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


def _confirm(client, token, import_id, key="key-0001-abcdef"):
    return client.post(f"/api/v1/imports/{import_id}/confirm",
                       headers={"Authorization": f"Bearer {token}", "Idempotency-Key": key})


def _count(model):
    from app.db import get_db
    from app.main import app

    return next(app.dependency_overrides[get_db]()).query(model).count()


def test_confirm_saves_all_in_one_go(client, token):
    from app.models import Darijums

    import_id = _upload(client, token, "mintos_2026_07-09.csv").json()["importa_id"]
    r = _confirm(client, token, import_id)
    assert r.status_code == 200
    assert r.json()["saglabati"] == 128
    assert _count(Darijums) == 128


def test_confirm_is_idempotent(client, token):
    from app.models import Darijums

    import_id = _upload(client, token, "mintos_2026_07-09.csv").json()["importa_id"]
    first = _confirm(client, token, import_id).json()
    second = _confirm(client, token, import_id)
    assert second.status_code == 200 and second.json() == first
    assert _count(Darijums) == 128


def test_confirm_with_other_key_is_conflict(client, token):
    import_id = _upload(client, token, "mintos_2026_07-09.csv").json()["importa_id"]
    _confirm(client, token, import_id, key="key-0001-abcdef")
    r = _confirm(client, token, import_id, key="key-0002-abcdef")
    assert r.status_code == 409


def test_reimport_after_confirm_counts_all_as_duplicates(client, token):
    import_id = _upload(client, token, "mintos_2026_07-09.csv").json()["importa_id"]
    _confirm(client, token, import_id)
    body = _upload(client, token, "mintos_2026_07-09.csv").json()
    assert body["jauni"] == 0 and body["dublikati"] == 130


def test_cannot_confirm_someone_elses_import(client, token):
    import_id = _upload(client, token, "mintos_2026_07-09.csv").json()["importa_id"]
    client.post("/api/v1/auth/register", json={"epasts": "b@inbox.lv", "parole": "Kopsumma2026"})
    other = client.post("/api/v1/auth/login",
                        json={"epasts": "b@inbox.lv", "parole": "Kopsumma2026"}).json()["access_token"]
    r = _confirm(client, other, import_id)
    assert r.status_code == 404
