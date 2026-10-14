"""Mintos konta izraksta CSV parsētājs (FR-06, FR-07).

Kolonnas: Transaction ID, Date, Details, Turnover, Balance, Currency, Payment Type.
Summas tiek pārvērstas centos ar Decimal — float netiek izmantots nekur.
"""

import csv
import io
from dataclasses import dataclass
from datetime import date, datetime
from decimal import ROUND_HALF_UP, Decimal, InvalidOperation

from app.models import TxType

REQUIRED = ["Transaction ID", "Date", "Turnover", "Currency", "Payment Type"]

TYPE_MAP = {
    "interest received": TxType.procenti,
    "interest received from pending payments": TxType.procenti,
    "late fees received": TxType.procenti,
    "investment principal increase": TxType.ieguldijums,
    "investment principal repayment": TxType.atmaksa,
    "investment principal rebuy": TxType.atmaksa,
    "discount/premium for secondary market transaction": TxType.kapitala_pieaugums,
    "secondary market fee": TxType.maksa,
    "fx commission": TxType.maksa,
}


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


def _to_cents(raw: str, row: int) -> int:
    try:
        value = Decimal(raw.strip().replace(",", "."))
    except InvalidOperation as exc:
        raise ParseError(row, f"Summa '{raw}' nav skaitlis") from exc
    cents = int((value * 100).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
    if cents == 0:
        raise ParseError(row, "Summa ir 0")
    return cents


def _to_date(raw: str, row: int) -> date:
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d", "%d.%m.%Y %H:%M", "%d.%m.%Y"):
        try:
            return datetime.strptime(raw.strip(), fmt).date()
        except ValueError:
            continue
    raise ParseError(row, f"Datums '{raw}' nav derīgs")


def parse(content: bytes) -> ParseResult:
    try:
        text = content.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise ParseError(1, "Fails nav UTF-8 CSV") from exc

    reader = csv.DictReader(io.StringIO(text))
    missing = [c for c in REQUIRED if c not in (reader.fieldnames or [])]
    if missing:
        raise ParseError(1, f"Trūkst kolonnu: {', '.join(missing)}")

    seen: set[str] = set()
    out: list[ParsedTx] = []
    dup = rows = 0
    for i, rec in enumerate(reader, start=2):  # 1. rinda ir galvene
        rows += 1
        tx_id = (rec["Transaction ID"] or "").strip()
        if not tx_id:
            raise ParseError(i, "Trūkst darījuma ID")
        if tx_id in seen:
            dup += 1
            continue
        seen.add(tx_id)
        kind = TYPE_MAP.get((rec["Payment Type"] or "").strip().lower())
        if kind is None:
            raise ParseError(i, f"Nezināms darījuma veids '{rec['Payment Type']}'")
        currency = (rec["Currency"] or "").strip().upper()
        if len(currency) != 3 or not currency.isalpha():
            raise ParseError(i, f"Valūta '{rec['Currency']}' nav ISO 4217 kods")
        out.append(ParsedTx(tx_id, _to_date(rec["Date"], i), kind,
                            _to_cents(rec["Turnover"], i), currency))
    if rows == 0:
        raise ParseError(2, "Failā nav neviena darījuma")
    return ParseResult(out, dup, rows)
