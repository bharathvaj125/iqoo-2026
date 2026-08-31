import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.base import Base
from app.db.session import get_db
from app.main import app

# In-memory SQLite, one fresh instance per test — real backend runs on Postgres
# (see app/core/config.py), but this is enough to exercise the actual FastAPI
# routes/ORM models end to end without needing a running Postgres for CI.
_engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
_TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=_engine)


def _override_get_db():
    db = _TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = _override_get_db


@pytest.fixture(autouse=True)
def _fresh_schema():
    """Recreates every table before each test so tests don't see each other's data."""
    Base.metadata.create_all(bind=_engine)
    yield
    Base.metadata.drop_all(bind=_engine)


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def db_session():
    """Direct DB access for test assertions (e.g. "exactly one user row exists"),
    bound to the same in-memory engine the app itself is overridden to use."""
    db = _TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
