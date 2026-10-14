import os

os.environ.setdefault("JWT_SECRET", "test-secret-only-for-pytest-0123456789")

from datetime import date

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.config import get_settings
from app.db import Base, get_db
from app.main import app
from app.models import NodoklaLikme, Platforma, TxType


@pytest.fixture
def client(tmp_path, monkeypatch):
    monkeypatch.setattr(get_settings(), "upload_dir", str(tmp_path))
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False},
                           poolclass=StaticPool)
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine, expire_on_commit=False)
    with Session() as db:
        db.add_all([
            Platforma(id=1, nosaukums="Mintos", formata_versija="2025-csv", aktiva=True),
            Platforma(id=2, nosaukums="Twino", formata_versija="2025-csv", aktiva=False),
            NodoklaLikme(id=1, ienakuma_veids=TxType.procenti, likme_bazes_punktos=2550,
                         slieksnis_centos=100000, speka_no=date(2025, 1, 1)),
        ])
        db.commit()

    def override():
        db = Session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override
    yield TestClient(app)
    app.dependency_overrides.clear()


@pytest.fixture
def token(client):
    client.post("/api/v1/auth/register", json={"epasts": "anna@inbox.lv", "parole": "Kopsumma2026"})
    r = client.post("/api/v1/auth/login", json={"epasts": "anna@inbox.lv", "parole": "Kopsumma2026"})
    return r.json()["access_token"]
