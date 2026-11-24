from pathlib import Path

import pytest

from app.importers import twino
from app.importers.common import ParseError, to_cents
from app.models import TxType

FIX = Path(__file__).parent / "fixtures"


def test_demo_statement_counts():
    res = twino.parse((FIX / "twino_2026-10-11.csv").read_bytes())
    assert res.rows == 84
    assert res.skipped == 1  # FUNDING nav ieguldījums
    assert len(res.transactions) == 83
    interest = sum(t.summa_centos for t in res.transactions if t.veids is TxType.procenti)
    assert interest == 9428


def test_ids_are_stable_between_imports():
    a = twino.parse((FIX / "twino_2026-10-11.csv").read_bytes())
    b = twino.parse((FIX / "twino_2026-10-11.csv").read_bytes())
    assert [t.arejais_id for t in a.transactions] == [t.arejais_id for t in b.transactions]
    assert len({t.arejais_id for t in a.transactions}) == len(a.transactions)


def test_identical_rows_are_not_merged():
    csv = (b"Processing Date,Type,Description,Loan Number,Amount\n"
           b"01.10.2026 09:00,REPAYMENT,INTEREST,LV-1,1.00\n"
           b"01.10.2026 09:00,REPAYMENT,INTEREST,LV-1,1.00\n")
    res = twino.parse(csv)
    assert len(res.transactions) == 2


def test_broken_amount_reports_row():
    with pytest.raises(ParseError) as e:
        twino.parse((FIX / "twino_bojats.csv").read_bytes())
    assert e.value.row == 2 and "abc" in e.value.reason


def test_mintos_file_is_rejected_with_hint():
    with pytest.raises(ParseError) as e:
        twino.parse((FIX / "mintos_2026_07-09.csv").read_bytes())
    assert e.value.row == 1 and "Twino" in e.value.reason


@pytest.mark.parametrize("raw,cents", [("1.234,56", 123456), ("1,234.56", 123456), ("-0,05", -5),
                                       ("2.005", 201), ("2.004", 200)])
def test_amount_formats_round_half_up(raw, cents):
    assert to_cents(raw, 2) == cents
