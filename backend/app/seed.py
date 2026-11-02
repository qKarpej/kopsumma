"""Demo dati īstajam serverim: python -m app.seed

Izveido lietotāju anna@inbox.lv / Kopsumma2026 un importē kontrolizrakstu,
izmantojot to pašu parsētāju un saglabāšanu kā API-05/API-06."""

from pathlib import Path

from sqlalchemy import select

from app.db import SessionLocal
from app.importers import mintos
from app.models import Darijums, Lietotajs, TxStatus
from app.security import hash_password

FIXTURE = Path(__file__).resolve().parent.parent / "tests" / "fixtures" / "mintos_2026_07-09.csv"


def main() -> None:
    with SessionLocal() as db:
        user = db.scalar(select(Lietotajs).where(Lietotajs.epasts == "anna@inbox.lv"))
        if user is None:
            user = Lietotajs(epasts="anna@inbox.lv", paroles_jaucejvertiba=hash_password("Kopsumma2026"))
            db.add(user)
            db.flush()
        existing = set(db.scalars(select(Darijums.arejais_id).where(Darijums.lietotaja_id == user.id)))
        result = mintos.parse(FIXTURE.read_bytes())
        new = [t for t in result.transactions if t.arejais_id not in existing]
        for t in new:
            db.add(Darijums(lietotaja_id=user.id, platformas_id=1, arejais_id=t.arejais_id,
                            darijuma_datums=t.darijuma_datums, veids=t.veids, summa_centos=t.summa_centos,
                            valuta=t.valuta, statuss=TxStatus.apstiprinats))
        db.commit()
        print(f"Demo lietotājs anna@inbox.lv / Kopsumma2026 · pievienoti {len(new)} darījumi")


if __name__ == "__main__":
    main()
