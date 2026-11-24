"""Kopīgais visiem izrakstu parsētājiem: rezultāta tips, kļūda ar rindas numuru, summas centos."""

from dataclasses import dataclass, field
from datetime import date, datetime
from decimal import ROUND_HALF_UP, Decimal, InvalidOperation

from app.models import TxType


class ParseError(Exception):
    def __init__(self, row: int, reason: str):
        super().__init__(f"row {row}: {reason}")
        self.row, self.reason = row, reason


@dataclass(frozen=True)
class ParsedTx:
    arejais_id: str
    darijuma_datums: date
    veids: TxType
    summa_centos: int
    valuta: str


@dataclass
class ParseResult:
    transactions: list[ParsedTx]
    duplicates_in_file: int
    rows: int
    skipped: int = 0  # naudas iemaksas/izmaksas, kas nav ieguldījumu darījumi
    notes: list[str] = field(default_factory=list)


def decode(content: bytes) -> str:
    try:
        return content.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise ParseError(1, "Fails nav UTF-8 CSV") from exc


def to_cents(raw: str, row: int, allow_zero: bool = False) -> int:
    text = (raw or "").strip().replace(" ", "").replace(" ", "")
    if "," in text and "." in text:  # 1.234,56 vai 1,234.56
        text = text.replace(",", "") if text.rfind(".") > text.rfind(",") else \
            text.replace(".", "").replace(",", ".")
    else:
        text = text.replace(",", ".")
    try:
        value = Decimal(text)
    except InvalidOperation as exc:
        raise ParseError(row, f"Summa '{raw}' nav skaitlis") from exc
    cents = int((value * 100).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
    if cents == 0 and not allow_zero:
        raise ParseError(row, "Summa ir 0")
    return cents


DATE_FORMATS = ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d", "%d.%m.%Y %H:%M:%S",
                "%d.%m.%Y %H:%M", "%d.%m.%Y", "%d/%m/%Y %H:%M", "%d/%m/%Y")


def to_date(raw: str, row: int) -> date:
    for fmt in DATE_FORMATS:
        try:
            return datetime.strptime((raw or "").strip(), fmt).date()
        except ValueError:
            continue
    raise ParseError(row, f"Datums '{raw}' nav derīgs")
