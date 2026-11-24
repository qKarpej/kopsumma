"""Twino konta izraksta CSV parsētājs (FR-06, FR-07).

Twino eksportē: Processing Date, Transaction Date, Type, Description, Loan Number, Amount
(atdalītājs — komats vai semikols; valūta — EUR, ja kolonnas Currency nav).
Twino nedod darījuma ID, tāpēc ārējais ID ir rindas satura SHA-1 + kārtas numurs
starp identiskām rindām — atkārtots tā paša faila imports neveido dublikātus.
"""

import csv
import hashlib
import io

from app.importers.common import ParsedTx, ParseError, ParseResult, decode, to_cents, to_date
from app.models import TxType

REQUIRED = ["Processing Date", "Type", "Description", "Amount"]

# Type → (Description → veids); "*" der jebkuram aprakstam
TYPE_MAP: dict[str, dict[str, TxType]] = {
    "repayment": {"principal": TxType.atmaksa, "interest": TxType.procenti, "penalty": TxType.procenti},
    "early_full_repayment": {"principal": TxType.atmaksa, "interest": TxType.procenti},
    "buyback": {"principal": TxType.atmaksa, "interest": TxType.procenti},
    "schedule": {"principal": TxType.atmaksa, "interest": TxType.procenti},
    "extension": {"interest": TxType.procenti, "principal": TxType.atmaksa},
    "buy_shares": {"*": TxType.ieguldijums},
    "investment": {"*": TxType.ieguldijums},
    "currency_fluctuation": {"*": TxType.kapitala_pieaugums},
    "fee": {"*": TxType.maksa},
}
SKIP = {"funding", "withdrawal", "deposit"}


def _reader(text: str) -> csv.DictReader:
    first = text.splitlines()[0] if text else ""
    delimiter = ";" if first.count(";") > first.count(",") else ","
    return csv.DictReader(io.StringIO(text), delimiter=delimiter)


def parse(content: bytes) -> ParseResult:
    reader = _reader(decode(content))
    fields = [f.strip() for f in (reader.fieldnames or [])]
    reader.fieldnames = fields
    missing = [c for c in REQUIRED if c not in fields]
    if missing:
        raise ParseError(1, f"Trūkst kolonnu: {', '.join(missing)}. Vai tas ir Twino izraksts?")

    occurrences: dict[str, int] = {}
    out: list[ParsedTx] = []
    rows = skipped = 0
    for i, rec in enumerate(reader, start=2):
        rows += 1
        ttype = (rec.get("Type") or "").strip().lower()
        desc = (rec.get("Description") or "").strip().lower()
        if ttype in SKIP:
            skipped += 1
            continue
        kinds = TYPE_MAP.get(ttype)
        if kinds is None:
            raise ParseError(i, f"Nezināms darījuma veids '{rec.get('Type')}'")
        kind = kinds.get(desc) or kinds.get("*")
        if kind is None:
            raise ParseError(i, f"Nezināms apraksts '{rec.get('Description')}' veidam '{rec.get('Type')}'")
        currency = (rec.get("Currency") or "EUR").strip().upper()
        if len(currency) != 3 or not currency.isalpha():
            raise ParseError(i, f"Valūta '{rec.get('Currency')}' nav ISO 4217 kods")
        when = to_date(rec.get("Transaction Date") or rec["Processing Date"], i)
        cents = to_cents(rec["Amount"], i)

        key = "|".join([rec["Processing Date"].strip(), ttype, desc,
                        (rec.get("Loan Number") or "").strip(), str(cents), currency])
        n = occurrences.get(key, 0)
        occurrences[key] = n + 1
        ext = "TW-" + hashlib.sha1(f"{key}|{n}".encode()).hexdigest()[:16]  # noqa: S324 — ne drošībai
        out.append(ParsedTx(ext, when, kind, cents, currency))
    if rows == 0:
        raise ParseError(2, "Failā nav neviena darījuma")
    return ParseResult(out, 0, rows, skipped)
