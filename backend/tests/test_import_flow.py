from pathlib import Path

from app.routers import portfolio

FIX = Path(__file__).parent / "fixtures"


def _h(token):
    return {"Authorization": f"Bearer {token}"}


def _upload(client, token, name, platform):
    return client.post("/api/v1/imports", headers=_h(token), data={"platformas_id": str(platform)},
                       files={"fails": (name, (FIX / name).read_bytes(), "text/csv")})


def test_platforms_list(client):
    items = client.get("/api/v1/platforms").json()["items"]
    assert [(p["nosaukums"], p["aktiva"]) for p in items] == [("Mintos", True), ("Twino", True)]


def test_twino_upload_confirm_and_portfolio(client, token):
    r = _upload(client, token, "twino_2026-10-11.csv", 2)
    assert r.status_code == 201
    body = r.json()
    assert body["platforma"] == "Twino" and body["jauni"] == 83 and body["izlaisti"] == 1
    c = client.post(f"/api/v1/imports/{body['importa_id']}/confirm",
                    headers={**_h(token), "Idempotency-Key": "demo-key-0001"})
    assert c.json()["saglabati"] == 83
    p = client.get("/api/v1/portfolio", headers=_h(token)).json()
    assert [x["nosaukums"] for x in p["platformas"]] == ["Twino"]
    again = _upload(client, token, "twino_2026-10-11.csv", 2).json()
    assert again["jauni"] == 0 and again["dublikati"] == 83


def test_history_and_cancel(client, token):
    imp = _upload(client, token, "twino_2026-10-11.csv", 2).json()["importa_id"]
    _upload(client, token, "mintos_bojats.csv", 1)
    hist = client.get("/api/v1/imports", headers=_h(token)).json()["items"]
    assert {h["statuss"] for h in hist} == {"parbaude", "kluda"}
    r = client.post(f"/api/v1/imports/{imp}/cancel", headers=_h(token))
    assert r.json()["statuss"] == "atcelts"
    confirm = client.post(f"/api/v1/imports/{imp}/confirm",
                          headers={**_h(token), "Idempotency-Key": "demo-key-0002"})
    assert confirm.status_code == 409
    assert client.post(f"/api/v1/imports/{imp}/cancel", headers=_h(token)).status_code == 409


def test_deadlines_next_is_january(client, token, monkeypatch):
    monkeypatch.setattr(portfolio, "today", lambda: __import__("datetime").date(2026, 11, 24))
    for name, pid in (("mintos_2026_07-09.csv", 1), ("twino_2026-10-11.csv", 2)):
        imp = _upload(client, token, name, pid).json()["importa_id"]
        client.post(f"/api/v1/imports/{imp}/confirm", headers={**_h(token), "Idempotency-Key": f"k-{name}"})
    body = client.get("/api/v1/deadlines", headers=_h(token)).json()
    assert body["items"] == [body["nakamais"]]
    nxt = body["nakamais"]
    # abu ceturkšņu peļņa < 1000 € → viens termiņš: 15.01.2027, deklarēt un samaksāt
    assert nxt["datums"] == "2027-01-15" and nxt["veids"] == "deklaresana_un_samaksa"
    assert nxt["periods"] == "2026-Q3, 2026-Q4" and nxt["provizorisks"]
    assert nxt["nodoklis_centos"] == 3635 + 2404  # 142,55 € un 94,28 € × 25,5 %


def test_deadlines_quarterly_when_over_threshold(client, token, monkeypatch):
    from datetime import date

    from app.db import get_db
    from app.main import app
    from app.models import Darijums, Lietotajs, TxStatus, TxType

    monkeypatch.setattr(portfolio, "today", lambda: date(2026, 11, 24))
    db = next(app.dependency_overrides[get_db]())
    user = db.query(Lietotajs).one()
    db.add(Darijums(lietotaja_id=user.id, platformas_id=1, arejais_id="X-1",
                    darijuma_datums=date(2026, 10, 5),
                    veids=TxType.procenti, summa_centos=150000, valuta="EUR", statuss=TxStatus.apstiprinats))
    db.commit()
    items = client.get("/api/v1/deadlines", headers=_h(token)).json()["items"]
    assert [(x["veids"], x["datums"]) for x in items] == [
        ("deklaresana", "2027-01-15"), ("samaksa", "2027-01-23")]
    assert items[0]["nodoklis_centos"] == 38250


def test_deadlines_empty(client, token):
    assert client.get("/api/v1/deadlines", headers=_h(token)).json() == {"items": [], "nakamais": None}
