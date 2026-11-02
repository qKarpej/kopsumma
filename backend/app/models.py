"""Datu modelis pēc K3 2. sadaļas. Summas — BIGINT centos, nekad float."""

import enum
import uuid
from datetime import UTC, date, datetime

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    SmallInteger,
    String,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


def utcnow() -> datetime:
    return datetime.now(UTC)


class ImportStatus(enum.StrEnum):
    parbaude = "parbaude"
    apstiprinats = "apstiprinats"
    atcelts = "atcelts"
    kluda = "kluda"


class TxType(enum.StrEnum):
    procenti = "procenti"
    kapitala_pieaugums = "kapitala_pieaugums"
    ieguldijums = "ieguldijums"
    atmaksa = "atmaksa"
    maksa = "maksa"


class TxStatus(enum.StrEnum):
    apstiprinats = "apstiprinats"
    japarbauda = "japarbauda"
    aizstats = "aizstats"


class Lietotajs(Base):
    __tablename__ = "lietotajs"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    epasts: Mapped[str] = mapped_column(String(254), unique=True, nullable=False)
    paroles_jaucejvertiba: Mapped[str] = mapped_column(String(255), nullable=False)
    neveiksmigi_meginajumi: Mapped[int] = mapped_column(SmallInteger, default=0, nullable=False)
    pirmais_neveiksmigais: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    blokets_lidz: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    dzesanas_pieprasijums: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    izveidots: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Platforma(Base):
    __tablename__ = "platforma"

    id: Mapped[int] = mapped_column(SmallInteger, primary_key=True)
    nosaukums: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    formata_versija: Mapped[str] = mapped_column(String(20), nullable=False)
    aktiva: Mapped[bool] = mapped_column(default=True, nullable=False)


class ImportaSesija(Base):
    __tablename__ = "importa_sesija"
    __table_args__ = (
        CheckConstraint("jauni >= 0 AND dublikati >= 0", name="ck_importa_skaiti"),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    lietotaja_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("lietotajs.id", ondelete="CASCADE"), nullable=False, index=True
    )
    platformas_id: Mapped[int] = mapped_column(ForeignKey("platforma.id"), nullable=False)
    faila_nosaukums: Mapped[str] = mapped_column(String(255), nullable=False)
    statuss: Mapped[ImportStatus] = mapped_column(
        Enum(ImportStatus, name="importa_statuss"), nullable=False
    )
    jauni: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    dublikati: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    kludas_rinda: Mapped[int | None] = mapped_column(Integer)
    izveidots: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    apstiprinats: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    idempotences_atslega: Mapped[str | None] = mapped_column(String(64))


class Darijums(Base):
    __tablename__ = "darijums"
    __table_args__ = (
        UniqueConstraint("lietotaja_id", "platformas_id", "arejais_id", name="uq_darijums_arejais"),
        CheckConstraint("summa_centos <> 0", name="ck_summa_nav_nulle"),
        CheckConstraint("length(valuta) = 3", name="ck_valuta_iso"),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    lietotaja_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("lietotajs.id", ondelete="CASCADE"), nullable=False, index=True
    )
    platformas_id: Mapped[int] = mapped_column(ForeignKey("platforma.id"), nullable=False)
    importa_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("importa_sesija.id"))
    aizstaj_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("darijums.id"))
    arejais_id: Mapped[str] = mapped_column(String(64), nullable=False)
    darijuma_datums: Mapped[date] = mapped_column(Date, nullable=False)
    veids: Mapped[TxType] = mapped_column(Enum(TxType, name="darijuma_veids"), nullable=False)
    summa_centos: Mapped[int] = mapped_column(BigInteger, nullable=False)
    valuta: Mapped[str] = mapped_column(String(3), nullable=False)
    statuss: Mapped[TxStatus] = mapped_column(
        Enum(TxStatus, name="darijuma_statuss"), nullable=False
    )
    izveidots: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    platforma: Mapped[Platforma] = relationship()


class NodoklaLikme(Base):
    __tablename__ = "nodokla_likme"

    id: Mapped[int] = mapped_column(SmallInteger, primary_key=True)
    ienakuma_veids: Mapped[TxType] = mapped_column(Enum(TxType, name="likmes_veids"), nullable=False)
    likme_bazes_punktos: Mapped[int] = mapped_column(Integer, nullable=False)
    slieksnis_centos: Mapped[int] = mapped_column(BigInteger, nullable=False)
    speka_no: Mapped[date] = mapped_column(Date, nullable=False)
    speka_lidz: Mapped[date | None] = mapped_column(Date)


class AtjaunosanasMarkieris(Base):
    __tablename__ = "atjaunosanas_markieris"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    lietotaja_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("lietotajs.id", ondelete="CASCADE"), nullable=False, index=True
    )
    markiera_jaucejvertiba: Mapped[str] = mapped_column(String(64), nullable=False, unique=True)
    deriga_lidz: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    anulets: Mapped[bool] = mapped_column(default=False, nullable=False)
