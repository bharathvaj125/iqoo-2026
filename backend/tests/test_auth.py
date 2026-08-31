from app.core.security import decode_access_token
from app.models.user import User


def test_new_email_creates_a_user(client, db_session):
    response = client.post("/api/auth/login", json={"email": "asha1@example.com"})

    assert response.status_code == 200
    body = response.json()
    assert body["access_token"]
    assert body["role"] is None  # fresh account hasn't picked a role yet

    users = db_session.query(User).filter(User.email == "asha1@example.com").all()
    assert len(users) == 1


def test_existing_email_logs_in_without_creating_a_duplicate(client, db_session):
    first = client.post("/api/auth/login", json={"email": "caregiver1@example.com"})
    second = client.post("/api/auth/login", json={"email": "caregiver1@example.com"})

    assert first.status_code == 200
    assert second.status_code == 200

    first_sub = decode_access_token(first.json()["access_token"])["sub"]
    second_sub = decode_access_token(second.json()["access_token"])["sub"]
    assert first_sub == second_sub  # same account both times, not a fresh one

    users = db_session.query(User).filter(User.email == "caregiver1@example.com").all()
    assert len(users) == 1


def test_issued_jwt_is_valid_against_an_existing_protected_endpoint(client):
    login = client.post("/api/auth/login", json={"email": "asha2@example.com"})
    token = login.json()["access_token"]

    unauthenticated = client.get("/api/patients")
    assert unauthenticated.status_code == 401

    authenticated = client.get("/api/patients", headers={"Authorization": f"Bearer {token}"})
    assert authenticated.status_code == 200


def test_role_can_be_set_once_and_only_once(client):
    login = client.post("/api/auth/login", json={"email": "asha3@example.com"})
    token = login.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    set_role = client.post("/api/auth/role", json={"role": "asha"}, headers=headers)
    assert set_role.status_code == 200
    assert set_role.json()["role"] == "asha"

    # The token from /login is now stale (it was issued before a role existed) —
    # the caller is expected to switch to the fresh token /role just returned.
    fresh_headers = {"Authorization": f"Bearer {set_role.json()['access_token']}"}
    second_attempt = client.post("/api/auth/role", json={"role": "caregiver"}, headers=fresh_headers)
    assert second_attempt.status_code == 400
