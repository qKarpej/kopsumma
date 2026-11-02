"""Naudas loģika: visas summas veselos centos (K3, L-2). Float netiek izmantots."""

from dataclasses import dataclass
from datetime import date
from decimal import ROUND_HALF_UP, Decimal

TAXABLE = {"procenti", "kapitala_pieaugums"}


def tax_cents(taxable_cents: int, rate_bp: int) -> int:
    """Nodoklis no apliekamā ienākuma; noapaļo vienu reizi līdz centam (ROUND_HALF_UP)."""
    if taxable_cents <= 0:
        return 0
    value = Decimal(taxable_cents) * Decimal(rate_bp) / Decimal(10_000)
    return int(value.quantize(Decimal("1"), rounding=ROUND_HALF_UP))


def quarter_bounds(period: str) -> tuple[date, date]:
    """'2026-Q3' → (2026-07-01, 2026-09-30)."""
    year_s, q_s = period.upper().split("-Q")
    year, q = int(year_s), int(q_s)
    if q not in (1, 2, 3, 4):
        raise ValueError("ceturksnim jābūt 1–4")
    start = date(year, 3 * q - 2, 1)
    end = date(year + 1, 1, 1) if q == 4 else date(year, 3 * q + 1, 1)
    return start, date.fromordinal(end.toordinal() - 1)


@dataclass(frozen=True)
class Deadlines:
    deklaresanas: date
    samaksas: date


def deadlines(period_end: date, taxable_cents: int, threshold_cents: int) -> Deadlines:
    """Ja peļņa ceturksnī sasniedz slieksni — līdz nākamā mēneša 15./23. datumam,
    citādi — līdz nākamā gada 15. janvārim (deklarācija un samaksa)."""
    if taxable_cents >= threshold_cents:
        y, m = (period_end.year + 1, 1) if period_end.month == 12 else (period_end.year, period_end.month + 1)
        return Deadlines(date(y, m, 15), date(y, m, 23))
    nxt = date(period_end.year + 1, 1, 15)
    return Deadlines(nxt, nxt)


def portfolio_value_cents(amounts_by_type: dict[str, int]) -> int:
    """Ieguldītais atlikums: ieguldījumi (negatīvi) mīnus atgūtā pamatsumma."""
    invested = -amounts_by_type.get("ieguldijums", 0)
    returned = amounts_by_type.get("atmaksa", 0)
    return max(0, invested - returned)
