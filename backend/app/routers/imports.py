"""API-05 izraksta pārbaude (nekas netiek saglabāts) un API-06 apstiprināšana (L-3)."""

import json
import uuid
from datetime import UTC, date, datetime
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, Header, UploadFile
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.config import get_settings
from app.db import get_db
from app.errors import ApiError
from app.importers import mintos
from app.models import Darijums, ImportaSesija, ImportStatus, Lietotajs, Platforma, TxStatus, TxType
from app.security import current_user

router = APIRouter(prefix="/api/v1/imports", tags=["imports"])

PARSERS = {"Mintos": mintos.parse}


@router.post("", status_code=201)
async def upload(
    fails: UploadFile = File(...),
    platformas_id: int = Form(...),
    user: Lietotajs = Depends(current_user),
    db: Session = Depends(get_db),
):
    s = get_settings()
    platform = db.get(Platforma, platformas_id)
    if platform is None or not platform.aktiva or platform.nosaukums not in PARSERS:
        raise ApiError(400, "PLATFORM_UNSUPPORTED", "Šī platforma vēl netiek atbalstīta.",
                       field="platformas_id")

    content = await fails.read(s.max_upload_bytes + 1)
    if len(content) > s.max_upload_bytes:
        raise ApiError(413, "FILE_TOO_LARGE", "Fails ir lielāks par 10 MB.", field="fails")

    session = ImportaSesija(
        lietotaja_id=user.id,
        platformas_id=platform.id,
        faila_nosaukums=(fails.filename or "izraksts.csv")[:255],
        statuss=ImportStatus.parbaude,
    )
    try:
        result = PARSERS[platform.nosaukums](content)
    except mintos.ParseError as err:
        session.statuss, session.kludas_rinda = ImportStatus.kluda, err.row
        db.add(session)
        db.commit()
        raise ApiError(422, "IMPORT_INVALID_ROW", f"{err.row}. rindā: {err.reason}.",
                       detail=err.reason, field=f"fails.row[{err.row}]") from err

    existing = set(db.scalars(
        select(Darijums.arejais_id).where(
            Darijums.lietotaja_id == user.id,
            Darijums.platformas_id == platform.id,
            Darijums.arejais_id.in_([t.arejais_id for t in result.transactions]),
        )
    ))
    new = [t for t in result.transactions if t.arejais_id not in existing]
    session.jauni = len(new)
    session.dublikati = result.duplicates_in_file + (len(result.transactions) - len(new))
    db.add(session)
    db.commit()

    # Parsētie dati tiek glabāti līdz apstiprināšanai (API-06, nākamais sprints).
    Path(s.upload_dir).mkdir(parents=True, exist_ok=True)
    Path(s.upload_dir, f"{session.id}.json").write_text(json.dumps([
        {**t.__dict__, "darijuma_datums": t.darijuma_datums.isoformat(), "veids": t.veids.value}
        for t in new
    ]))

    dates = [t.darijuma_datums for t in new]
    return {
        "importa_id": str(session.id),
        "statuss": session.statuss.value,
        "rindas": result.rows,
        "jauni": session.jauni,
        "dublikati": session.dublikati,
        "periods": {"no": min(dates).isoformat(), "lidz": max(dates).isoformat()} if dates else None,
        "ienakumi_centos": sum(t.summa_centos for t in new if t.summa_centos > 0
                               and t.veids.value in ("procenti", "kapitala_pieaugums")),
    }


@router.post("/{import_id}/confirm")
def confirm(
    import_id: uuid.UUID,
    idempotency_key: str = Header(..., alias="Idempotency-Key", min_length=8, max_length=64),
    user: Lietotajs = Depends(current_user),
    db: Session = Depends(get_db),
):
    """API-06: saglabā pārbaudītos darījumus vienā transakcijā (L-3, NFR-11)."""
    session = db.get(ImportaSesija, import_id)
    if session is None or session.lietotaja_id != user.id:
        raise ApiError(404, "IMPORT_NOT_FOUND", "Imports nav atrasts.")
    if session.statuss is ImportStatus.apstiprinats:
        if session.idempotences_atslega == idempotency_key:
            return {"importa_id": str(session.id), "saglabati": session.jauni,
                    "dublikati": session.dublikati}
        raise ApiError(409, "IMPORT_ALREADY_CONFIRMED", "Šis imports jau ir saglabāts.")
    if session.statuss is not ImportStatus.parbaude:
        raise ApiError(409, "IMPORT_NOT_CONFIRMABLE", "Šo importu vairs nevar saglabāt.")

    path = Path(get_settings().upload_dir, f"{session.id}.json")
    if not path.exists():
        raise ApiError(409, "IMPORT_EXPIRED",
                       "Pārbaudes dati vairs nav pieejami. Augšupielādējiet failu vēlreiz.")
    rows = json.loads(path.read_text())

    for r in rows:
        db.add(Darijums(
            lietotaja_id=user.id,
            platformas_id=session.platformas_id,
            importa_id=session.id,
            arejais_id=r["arejais_id"],
            darijuma_datums=date.fromisoformat(r["darijuma_datums"]),
            veids=TxType(r["veids"]),
            summa_centos=r["summa_centos"],
            valuta=r["valuta"],
            statuss=TxStatus.apstiprinats if r["valuta"] == "EUR" else TxStatus.japarbauda,
        ))
    session.statuss = ImportStatus.apstiprinats
    session.apstiprinats = datetime.now(UTC)
    session.idempotences_atslega = idempotency_key
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise ApiError(409, "IMPORT_CONFLICT", "Daļa darījumu jau ir saglabāta citā importā.") from exc
    path.unlink(missing_ok=True)
    return {"importa_id": str(session.id), "saglabati": len(rows), "dublikati": session.dublikati}
