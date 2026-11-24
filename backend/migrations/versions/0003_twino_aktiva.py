"""Twino parsētājs ir gatavs — platforma kļūst aktīva.

Revision ID: 0003
Revises: 0002
"""
from alembic import op

revision = "0003"
down_revision = "0002"


def upgrade() -> None:
    op.execute("UPDATE platforma SET aktiva = true WHERE nosaukums = 'Twino'")


def downgrade() -> None:
    op.execute("UPDATE platforma SET aktiva = false WHERE nosaukums = 'Twino'")
