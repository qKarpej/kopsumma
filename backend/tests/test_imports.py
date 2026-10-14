from pathlib import Path

FIX = Path(__file__).parent / "fixtures"


def _upload(client, token, name, platform=1):
    return client.post(
        "/api/v1/imports",
        headers={"Authorization": f"Bearer {token}"},
        data={"platformas_id": str(platform)},
        files={"fails": (name, (FIX / name).read_bytes(), "text/csv")},
    )


def test_upload_requires_auth(client):
    r = client.post("/api/v1/imports", data={"platformas_id": "1"},
                    files={"fails": ("a.csv", b"x", "text/csv")})
    assert r.status_code == 401


def test_upload_summary(client, token):
    r = _upload(client, token, "mintos_2026_07-09.csv")
    assert r.status_code == 201
    body = r.json()
    assert body["statuss"] == "parbaude"
    assert body["jauni"] == 128 and body["dublikati"] == 2
    assert body["periods"]["no"].startswith("2026-07")


def test_upload_does_not_save_transactions(client, token):
    from app.db import get_db
    from app.main import app
    from app.models import Darijums

    _upload(client, token, "mintos_2026_07-09.csv")
    db = next(app.dependency_overrides[get_db]())
    assert db.query(Darijums).count() == 0


def test_broken_file_returns_row_number(client, token):
    r = _upload(client, token, "mintos_bojats.csv")
    assert r.status_code == 422
    err = r.json()["error"]
    assert err["code"] == "IMPORT_INVALID_ROW"
    assert err["field"] == "fails.row[47]"


def test_unsupported_platform(client, token):
    r = _upload(client, token, "mintos_2026_07-09.csv", platform=2)
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "PLATFORM_UNSUPPORTED"
