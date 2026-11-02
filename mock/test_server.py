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
