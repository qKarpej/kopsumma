from pathlib import Path

import pytest

from app.importers import mintos
from app.models import TxType

FIX = Path(__file__).parent / "fixtures"


def test_control_file_128_new_2_duplicates():
    res = mintos.parse((FIX / "mintos_2026_07-09.csv").read_bytes())
    assert res.rows == 130
    assert len(res.transactions) == 128
    assert res.duplicates_in_file == 2


def test_amounts_are_integer_cents():
    res = mintos.parse((FIX / "mintos_2026_07-09.csv").read_bytes())
    assert all(isinstance(t.summa_centos, int) for t in res.transactions)


def test_broken_file_reports_row_47():
    with pytest.raises(mintos.ParseError) as exc:
        mintos.parse((FIX / "mintos_bojats.csv").read_bytes())
    assert exc.value.row == 47
    assert "2026/13/01" in exc.value.reason


@pytest.mark.parametrize("raw,cents", [("4.12", 412), ("-250.00", -25000), ("0.005", 1),
                                       ("1,10", 110)])
def test_cents_conversion_without_float(raw, cents):
    assert mintos._to_cents(raw, 2) == cents


def test_type_mapping():
    csv = ("Transaction ID,Date,Details,Turnover,Balance,Currency,Payment Type\n"
           "1,2026-09-30 10:00:00,x,4.12,,EUR,Interest received\n")
    res = mintos.parse(csv.encode())
    assert res.transactions[0].veids is TxType.procenti


def test_missing_columns():
    with pytest.raises(mintos.ParseError) as exc:
        mintos.parse(b"Date,Amount\n2026-01-01,1\n")
    assert exc.value.row == 1
