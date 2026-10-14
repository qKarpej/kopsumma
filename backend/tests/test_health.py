import os

os.environ.setdefault("JWT_SECRET", "test-secret-only-for-pytest-0123456789")

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402


def test_health():
    r = TestClient(app).get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}
