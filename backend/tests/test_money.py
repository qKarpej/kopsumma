"""Naudas loģikas testi: noapaļošana, sliekšņi, summas (K5 prasība ≥ 3)."""

from datetime import date

import pytest

from app import money


@pytest.mark.parametrize("taxable,expected", [
    (122510, 31240),   # 1225,10 € × 25,5 % = 312,40050 → 312,40 €
    (100, 26),         # 1,00 € × 25,5 % = 0,255 → 0,26 € (ROUND_HALF_UP)
    (98, 25),          # 0,98 € × 25,5 % = 0,2499 → 0,25 €
    (1, 0),            # 0,01 € × 25,5 % = 0,00255 → 0,00 €
])
def test_tax_rounds_half_up_once(taxable, expected):
    assert money.tax_cents(taxable, 2550) == expected


def test_no_tax_on_loss_or_zero():
    assert money.tax_cents(0, 2550) == 0
    assert money.tax_cents(-5000, 2550) == 0


def test_tax_is_integer_cents():
    assert isinstance(money.tax_cents(123456789, 2550), int)


def test_threshold_reached_means_next_month():
    d = money.deadlines(date(2026, 9, 30), 100000, 100000)
    assert d.deklaresanas == date(2026, 10, 15)
    assert d.samaksas == date(2026, 10, 23)


def test_below_threshold_means_january():
    d = money.deadlines(date(2026, 9, 30), 99999, 100000)
    assert d.deklaresanas == date(2027, 1, 15)


def test_q4_threshold_rolls_over_year():
    assert money.deadlines(date(2026, 12, 31), 200000, 100000).deklaresanas == date(2027, 1, 15)


def test_quarter_bounds():
    assert money.quarter_bounds("2026-Q3") == (date(2026, 7, 1), date(2026, 9, 30))
    assert money.quarter_bounds("2026-q4") == (date(2026, 10, 1), date(2026, 12, 31))
    with pytest.raises(ValueError):
        money.quarter_bounds("2026-Q5")


def test_portfolio_value_is_invested_minus_returned():
    assert money.portfolio_value_cents({"ieguldijums": -50000, "atmaksa": 12000, "procenti": 900}) == 38000
    assert money.portfolio_value_cents({"atmaksa": 500}) == 0
