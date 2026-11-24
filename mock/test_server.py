import json
import threading
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer

import pytest

import server


@pytest.fixture(scope="module")
def base():
    httpd = ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    yield f"http://127.0.0.1:{httpd.server_address[1]}"
    httpd.shutdown()


def get(url, auth=True):
    req = urllib.request.Request(url, headers={"Authorization": "Bearer x"} if auth else {})
    try:
        with urllib.request.urlopen(req) as r:  # noqa: S310
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def test_portfolio_ready(base):
    server.state["scenario"] = "ready"
    status, body = get(f"{base}/api/v1/portfolio")
    assert status == 200
    assert body["kopsumma_centos"] == sum(p["summa_centos"] for p in body["platformas"])


def test_requires_auth(base):
    assert get(f"{base}/api/v1/portfolio", auth=False)[0] == 401


def test_scenarios(base):
    get(f"{base}/__scenario/empty", auth=False)
    assert get(f"{base}/api/v1/portfolio")[1]["platformas"] == []
    get(f"{base}/__scenario/error", auth=False)
    status, body = get(f"{base}/api/v1/portfolio")
    assert status == 503 and body["error"]["code"] == "SERVICE_UNAVAILABLE"
    get(f"{base}/__scenario/ready", auth=False)


def post(url, data: bytes, ctype="application/json", headers=None):
    req = urllib.request.Request(url, data=data, method="POST",
                                 headers={"Authorization": "Bearer x", "Content-Type": ctype, **(headers or {})})
    try:
        with urllib.request.urlopen(req) as r:  # noqa: S310
            raw = r.read()
            return r.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def _multipart(filename: str, platform: int, content: bytes) -> bytes:
    return (b"--B\r\nContent-Disposition: form-data; name=\"platformas_id\"\r\n\r\n" + str(platform).encode()
            + b"\r\n--B\r\nContent-Disposition: form-data; name=\"fails\"; filename=\"" + filename.encode()
            + b"\"\r\nContent-Type: text/csv\r\n\r\n" + content + b"\r\n--B--\r\n")


def test_import_flow(base):
    server.state["scenario"] = "ready"
    body = _multipart("twino.csv", 2, b"h\n" + b"r\n" * 20)
    status, imp = post(f"{base}/api/v1/imports", body, "multipart/form-data; boundary=B")
    assert status == 201 and imp["platforma"] == "Twino" and imp["statuss"] == "parbaude"
    status, done = post(f"{base}/api/v1/imports/{imp['importa_id']}/confirm", b"",
                        headers={"Idempotency-Key": "k-000001"})
    assert status == 200 and done["saglabati"] == imp["jauni"]
    assert get(f"{base}/api/v1/imports")[1]["items"][0]["statuss"] == "apstiprinats"


def test_import_broken_file(base):
    server.state["scenario"] = "ready"
    status, err = post(f"{base}/api/v1/imports", _multipart("mintos_bojats.csv", 1, b"x"),
                       "multipart/form-data; boundary=B")
    assert status == 422 and err["error"]["field"] == "fails.row[47]"


def test_deadlines_and_platforms(base):
    server.state["scenario"] = "ready"
    assert get(f"{base}/api/v1/deadlines")[1]["nakamais"]["datums"] == "2027-01-15"
    assert [p["nosaukums"] for p in get(f"{base}/api/v1/platforms")[1]["items"]] == ["Mintos", "Twino"]
    server.state["scenario"] = "empty"
    assert get(f"{base}/api/v1/deadlines")[1]["nakamais"] is None


def test_register_and_refresh(base):
    assert post(f"{base}/api/v1/auth/register", b'{"epasts":"anna@inbox.lv","parole":"x"}')[0] == 409
    assert post(f"{base}/api/v1/auth/register", b'{"epasts":"juris@inbox.lv","parole":"x"}')[0] == 201
    assert post(f"{base}/api/v1/auth/refresh", b'{"refresh_token":"r"}')[1]["access_token"]
    assert post(f"{base}/api/v1/auth/logout", b'{"refresh_token":"r"}') == (204, None)
