def test_register_and_login(client):
    r = client.post("/api/v1/auth/register",
                    json={"epasts": "Anna@Inbox.lv", "parole": "Kopsumma2026"})
    assert r.status_code == 201
    r = client.post("/api/v1/auth/login",
                    json={"epasts": "anna@inbox.lv", "parole": "Kopsumma2026"})
    assert r.status_code == 200
    body = r.json()
    assert body["expires_in"] == 900
    assert body["access_token"] and body["refresh_token"]


def test_weak_password_rejected(client):
    r = client.post("/api/v1/auth/register", json={"epasts": "a@b.lv", "parole": "short1"})
    assert r.status_code == 422
    assert r.json()["error"]["field"] == "parole"


def test_duplicate_email(client):
    body = {"epasts": "a@b.lv", "parole": "Kopsumma2026"}
    client.post("/api/v1/auth/register", json=body)
    r = client.post("/api/v1/auth/register", json=body)
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "EMAIL_TAKEN"


def test_password_not_stored_in_plain_text(client):
    from app.db import get_db
    from app.main import app
    from app.models import Lietotajs

    client.post("/api/v1/auth/register", json={"epasts": "a@b.lv", "parole": "Kopsumma2026"})
    db = next(app.dependency_overrides[get_db]())
    user = db.query(Lietotajs).one()
    assert user.paroles_jaucejvertiba.startswith("$argon2id$")
    assert "Kopsumma2026" not in user.paroles_jaucejvertiba


def test_same_error_for_unknown_email_and_wrong_password(client):
    client.post("/api/v1/auth/register", json={"epasts": "a@b.lv", "parole": "Kopsumma2026"})
    r1 = client.post("/api/v1/auth/login", json={"epasts": "x@b.lv", "parole": "Kopsumma2026"})
    r2 = client.post("/api/v1/auth/login", json={"epasts": "a@b.lv", "parole": "Nepareiza123"})
    assert r1.status_code == r2.status_code == 401
    assert r1.json()["error"]["message"] == r2.json()["error"]["message"]


def test_lockout_after_five_failures(client):
    client.post("/api/v1/auth/register", json={"epasts": "a@b.lv", "parole": "Kopsumma2026"})
    for _ in range(5):
        r = client.post("/api/v1/auth/login", json={"epasts": "a@b.lv", "parole": "Nepareiza123"})
        assert r.status_code == 401
    r = client.post("/api/v1/auth/login", json={"epasts": "a@b.lv", "parole": "Kopsumma2026"})
    assert r.status_code == 423
    assert r.json()["error"]["code"] == "ACCOUNT_LOCKED"


def test_error_format_has_request_id(client):
    r = client.post("/api/v1/auth/login", json={"epasts": "x@b.lv", "parole": "x"})
    err = r.json()["error"]
    assert set(err) == {"code", "message", "detail", "field", "request_id"}
    assert err["request_id"] == r.headers["X-Request-ID"]
