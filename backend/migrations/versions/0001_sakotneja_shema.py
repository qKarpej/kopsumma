"""Sākotnējā shēma: lietotajs, platforma, importa_sesija, darijums, nodokla_likme, marķieri.

Revision ID: 0001
"""
from datetime import date

import sqlalchemy as sa
from alembic import op

from app import models  # noqa: F401
from app.db import Base

revision = "0001"
down_revision = None


def upgrade() -> None:
    bind = op.get_bind()
    Base.metadata.create_all(bind)
    op.bulk_insert(models.Platforma.__table__, [
        {"id": 1, "nosaukums": "Mintos", "formata_versija": "2025-csv", "aktiva": True},
        {"id": 2, "nosaukums": "Twino", "formata_versija": "2025-csv", "aktiva": False},
    ])
    op.bulk_insert(models.NodoklaLikme.__table__, [
        {"id": 1, "ienakuma_veids": "procenti", "likme_bazes_punktos": 2550,
         "slieksnis_centos": 100000, "speka_no": date(2025, 1, 1), "speka_lidz": None},
        {"id": 2, "ienakuma_veids": "kapitala_pieaugums", "likme_bazes_punktos": 2550,
         "slieksnis_centos": 100000, "speka_no": date(2025, 1, 1), "speka_lidz": None},
    ])


def downgrade() -> None:
    Base.metadata.drop_all(op.get_bind())
    for name in ("importa_statuss", "darijuma_veids", "darijuma_statuss", "likmes_veids"):
        op.execute(sa.text(f"DROP TYPE IF EXISTS {name}"))
