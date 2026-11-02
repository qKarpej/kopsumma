from pathlib import Path

FIX = Path(__file__).parent / "fixtures"


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _import(client, token):
    r = client.post("/api/v1/imports", headers=_auth(token), data={"platformas_id": "1"},
                    files={"fails": ("m.csv", (FIX / "mintos_2026_07-09.csv").read_bytes(), "text/csv")})
    import_id = r.json()["importa_id"]
    client.post(f"/api/v1/imports/{import_id}/confirm",
                headers={**_auth(token), "Idempotency-Key": "key-portfolio-1"})


def test_empty_portfolio(client, token):
    body = client.get("/api/v1/portfolio", headers=_auth(token)).json()
    assert body["kopsumma_centos"] == 0
    assert body["platformas"] == [] and body["nodoklis"] is None


def test_portfolio_total_equals_platform_sum(client, token):
    _import(client, token)
    body = client.get("/api/v1/portfolio", headers=_auth(token)).json()
    assert body["kopsumma_centos"] == sum(p["summa_centos"] for p in body["platformas"])
    assert body["platformas"][0]["darijumu_skaits"] == 128
    assert body["nodoklis"]["periods"] == "2026-Q3"


def test_tax_matches_manual_calculation(client, token):
    _import(client, token)
    tax = client.get("/api/v1/tax?period=2026-Q3", headers=_auth(token)).json()
    assert tax["apliekams_centos"] == max(0, tax["procenti_centos"] + tax["kapitala_pieaugums_centos"])
    expected = (tax["apliekams_centos"] * 2550 * 2 + 10000) // 20000  # half-up veselos skaitļos
    assert tax["nodoklis_centos"] == expected


def test_transactions_list_and_detail(client, token):
    _import(client, token)
    items = client.get("/api/v1/transactions", headers=_auth(token)).json()["items"]
    assert len(items) == 128
    assert items[0]["datums"] >= items[-1]["datums"]
    one = client.get(f"/api/v1/transactions/{items[0]['id']}", headers=_auth(token))
    assert one.status_code == 200 and one.json()["id"] == items[0]["id"]


def test_cannot_read_other_users_transaction(client, token):
    _import(client, token)
    tx_id = client.get("/api/v1/transactions", headers=_auth(token)).json()["items"][0]["id"]
    client.post("/api/v1/auth/register", json={"epasts": "b@inbox.lv", "parole": "Kopsumma2026"})
    other = client.post("/api/v1/auth/login",
                        json={"epasts": "b@inbox.lv", "parole": "Kopsumma2026"}).json()["access_token"]
    assert client.get(f"/api/v1/transactions/{tx_id}", headers=_auth(other)).status_code == 404


def test_bad_period(client, token):
    r = client.get("/api/v1/tax?period=2026-Q9", headers=_auth(token))
    assert r.status_code == 400 and r.json()["error"]["field"] == "period"
