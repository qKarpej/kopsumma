"""API-08 portfelis, API-09/10 darījumi, API-11 nodoklis (FR-10, FR-11, FR-14)."""

import uuid
from collections import defaultdict
from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app import money
from app.db import get_db
from app.errors import ApiError
from app.models import Darijums, Lietotajs, NodoklaLikme, Platforma, TxStatus, TxType
from app.security import current_user

router = APIRouter(prefix="/api/v1", tags=["portfolio"])


def _tx_json(t: Darijums) -> dict:
    return {
        "id": str(t.id), "datums": t.darijuma_datums.isoformat(), "platforma": t.platforma.nosaukums,
        "veids": t.veids.value, "summa_centos": t.summa_centos, "valuta": t.valuta,
        "statuss": t.statuss.value, "arejais_id": t.arejais_id,
    }


def _active(db: Session, user: Lietotajs):
    return db.scalars(
        select(Darijums).where(Darijums.lietotaja_id == user.id, Darijums.statuss != TxStatus.aizstats)
        .order_by(Darijums.darijuma_datums.desc())
    ).all()


def _rate(db: Session, kind: TxType, on: date) -> NodoklaLikme:
    rate = db.scalars(
        select(NodoklaLikme).where(NodoklaLikme.ienakuma_veids == kind, NodoklaLikme.speka_no <= on)
        .order_by(NodoklaLikme.speka_no.desc())
    ).first()
    if rate is None:
        raise ApiError(500, "RATE_MISSING", "Nodokļa likme nav konfigurēta.")
    return rate


def _tax(db: Session, user: Lietotajs, period: str) -> dict:
    try:
        start, end = money.quarter_bounds(period)
    except ValueError as exc:
        raise ApiError(400, "BAD_PERIOD", "Periods jānorāda formātā 2026-Q3.", field="period") from exc
    sums: dict[str, int] = defaultdict(int)
    excluded = 0
    for t in _active(db, user):
        if not (start <= t.darijuma_datums <= end) or t.veids.value not in money.TAXABLE:
            continue
        if t.valuta != "EUR" or t.statuss is TxStatus.japarbauda:
            excluded += 1
            continue
        sums[t.veids.value] += t.summa_centos
    taxable = max(0, sums["procenti"] + sums["kapitala_pieaugums"])
    rate = _rate(db, TxType.procenti, end)
    d = money.deadlines(end, taxable, rate.slieksnis_centos)
    return {
        "periods": period.upper(),
        "procenti_centos": sums["procenti"],
        "kapitala_pieaugums_centos": sums["kapitala_pieaugums"],
        "apliekams_centos": taxable,
        "likme_bazes_punktos": rate.likme_bazes_punktos,
        "nodoklis_centos": money.tax_cents(taxable, rate.likme_bazes_punktos),
        "deklaresanas_termins": d.deklaresanas.isoformat(),
        "samaksas_termins": d.samaksas.isoformat(),
        "neieklauti": excluded,
    }


def _last_quarter(txs) -> str:
    latest = max((t.darijuma_datums for t in txs), default=date.today())
    return f"{latest.year}-Q{(latest.month - 1) // 3 + 1}"


@router.get("/portfolio")
def portfolio(user: Lietotajs = Depends(current_user), db: Session = Depends(get_db)):
    txs = [t for t in _active(db, user) if t.valuta == "EUR"]
    by_platform: dict[int, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    counts: dict[int, int] = defaultdict(int)
    for t in txs:
        by_platform[t.platformas_id][t.veids.value] += t.summa_centos
        counts[t.platformas_id] += 1
    names = {p.id: p.nosaukums for p in db.scalars(select(Platforma)).all()}
    platforms = [
        {"id": pid, "nosaukums": names[pid], "summa_centos": money.portfolio_value_cents(sums),
         "darijumu_skaits": counts[pid]}
        for pid, sums in sorted(by_platform.items())
    ]
    period = _last_quarter(txs)
    start, end = money.quarter_bounds(period)
    income = sum(t.summa_centos for t in txs
                 if t.veids.value in money.TAXABLE and start <= t.darijuma_datums <= end)
    tax = _tax(db, user, period) if txs else None
    return {
        "valuta": "EUR",
        "kopsumma_centos": sum(p["summa_centos"] for p in platforms),
        "ienakumi_ceturksni_centos": income,
        "platformas": platforms,
        "nodoklis": None if tax is None else {
            "periods": tax["periods"], "summa_centos": tax["nodoklis_centos"],
            "deklaresanas_termins": tax["deklaresanas_termins"],
        },
    }


@router.get("/transactions")
def transactions(
    platforma: str | None = Query(default=None),
    user: Lietotajs = Depends(current_user),
    db: Session = Depends(get_db),
):
    items = [_tx_json(t) for t in _active(db, user)
             if platforma is None or t.platforma.nosaukums == platforma]
    return {"items": items, "skaits": len(items)}


@router.get("/transactions/{tx_id}")
def transaction(tx_id: uuid.UUID, user: Lietotajs = Depends(current_user), db: Session = Depends(get_db)):
    t = db.get(Darijums, tx_id)
    if t is None or t.lietotaja_id != user.id:
        raise ApiError(404, "NOT_FOUND", "Darījums nav atrasts.")
    return _tx_json(t)


@router.get("/tax")
def tax(period: str = Query(...), user: Lietotajs = Depends(current_user), db: Session = Depends(get_db)):
    return _tax(db, user, period)
