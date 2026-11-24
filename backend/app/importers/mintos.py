"""Mintos konta izraksta CSV parsētājs (FR-06, FR-07).

Kolonnas: Transaction ID, Date, Details, Turnover, Balance, Currency, Payment Type.
Summas tiek pārvērstas centos ar Decimal — float netiek izmantots nekur.
"""

import csv
import io

from app.importers.common import ParsedTx, ParseError, ParseResult, decode, to_cents, to_date
from app.models import TxType

__all__ = ["ParseError", "ParseResult", "ParsedTx", "parse"]

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
SKIP = {"deposits", "deposit", "withdrawal", "withdrawals", "incoming client payment",
        "outgoing client payment"}


def parse(content: bytes) -> ParseResult:
    text = decode(content)

    reader = csv.DictReader(io.StringIO(text))
    missing = [c for c in REQUIRED if c not in (reader.fieldnames or [])]
    if missing:
        raise ParseError(1, f"Trūkst kolonnu: {', '.join(missing)}")

    seen: set[str] = set()
    out: list[ParsedTx] = []
    dup = rows = skipped = 0
    for i, rec in enumerate(reader, start=2):  # 1. rinda ir galvene
        rows += 1
        tx_id = (rec["Transaction ID"] or "").strip()
        if not tx_id:
            raise ParseError(i, "Trūkst darījuma ID")
        if tx_id in seen:
            dup += 1
            continue
        seen.add(tx_id)
        ptype = (rec["Payment Type"] or "").strip().lower()
        if ptype in SKIP:
            skipped += 1
            continue
        kind = TYPE_MAP.get(ptype)
        if kind is None:
            raise ParseError(i, f"Nezināms darījuma veids '{rec['Payment Type']}'")
        currency = (rec["Currency"] or "").strip().upper()
        if len(currency) != 3 or not currency.isalpha():
            raise ParseError(i, f"Valūta '{rec['Currency']}' nav ISO 4217 kods")
        out.append(ParsedTx(tx_id, to_date(rec["Date"], i), kind,
                            to_cents(rec["Turnover"], i), currency))
    if rows == 0:
        raise ParseError(2, "Failā nav neviena darījuma")
    return ParseResult(out, dup, rows, skipped)
