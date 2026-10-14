"""importa_sesija.idempotences_atslega (API-06).

Revision ID: 0002
Revises: 0001
"""
import sqlalchemy as sa
from alembic import op

revision = "0002"
down_revision = "0001"


def upgrade() -> None:
    # 0001 veido tabulas no aktuālā modeļa, tāpēc jaunā DB kolonna jau var būt.
    cols = {c["name"] for c in sa.inspect(op.get_bind()).get_columns("importa_sesija")}
    if "idempotences_atslega" in cols:
        return
    with op.batch_alter_table("importa_sesija") as t:
        t.add_column(sa.Column("idempotences_atslega", sa.String(64), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("importa_sesija") as t:
        t.drop_column("idempotences_atslega")
