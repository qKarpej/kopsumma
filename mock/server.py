"""Kopsumma testa serveris (mock). Tikai Python standarta bibliotēka.

Palaišana:  python mock/server.py            (http://localhost:8080)
Scenārijs:  python mock/server.py --scenario empty   (ready | empty | error | slow)
Pārslēgt darbības laikā: atver http://localhost:8080/__scenario/error

Atbilst tam pašam API līgumam, ko īstais FastAPI serveris (K3, API-02, API-08…API-11).
"""

import argparse
import json
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

DATA = json.loads((Path(__file__).parent / "data.json").read_text(encoding="utf-8"))
SCENARIOS = ("ready", "empty", "error", "slow")
state = {"scenario": "ready"}


def empty_portfolio():
    return {"valuta": "EUR", "kopsumma_centos": 0, "ienakumi_ceturksni_centos": 0,
            "platformas": [], "nodoklis": None}


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, body):
        raw = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
        self.send_header("X-Request-ID", self.request_id)
        self.end_headers()
        self.wfile.write(raw)

    def _error(self, status, code, message):
        self._send(status, {"error": {"code": code, "message": message, "detail": "mock",
                                      "field": None, "request_id": self.request_id}})

    def do_OPTIONS(self):  # noqa: N802 (CORS preflight Flutter web klientam)
        self.request_id = uuid.uuid4().hex
        self._send(204, {})

    def _authorized(self):
        if not self.headers.get("Authorization", "").startswith("Bearer "):
            self._error(401, "AUTH_REQUIRED", "Lūdzu, piesakieties.")
            return False
        return True

    def do_POST(self):  # noqa: N802
        self.request_id = uuid.uuid4().hex
        if urlparse(self.path).path != "/api/v1/auth/login":
            return self._error(404, "NOT_FOUND", "Galapunkts nav atrasts.")
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length) or b"{}")
        if body.get("parole") != "Kopsumma2026":
            return self._error(401, "INVALID_CREDENTIALS", "E-pasts vai parole nav pareiza.")
        self._send(200, {"access_token": "mock-access", "refresh_token": "mock-refresh",
                         "token_type": "bearer", "expires_in": 900})

    def do_GET(self):  # noqa: N802
        self.request_id = uuid.uuid4().hex
        url = urlparse(self.path)
        if url.path.startswith("/__scenario/"):
            name = url.path.rsplit("/", 1)[-1]
            if name not in SCENARIOS:
                return self._error(400, "BAD_SCENARIO", f"Scenārijs: {', '.join(SCENARIOS)}")
            state["scenario"] = name
            return self._send(200, {"scenario": name})
        if url.path == "/health":
            return self._send(200, {"status": "ok", "scenario": state["scenario"]})
        if not self._authorized():
            return None

        scenario = state["scenario"]
        if scenario == "slow":
            time.sleep(3)
        if scenario == "error":
            return self._error(503, "SERVICE_UNAVAILABLE",
                               "Nav savienojuma ar serveri. Jūsu dati ir saglabāti.")
        empty = scenario == "empty"

        if url.path == "/api/v1/portfolio":
            return self._send(200, empty_portfolio() if empty else DATA["portfolio"])
        if url.path == "/api/v1/transactions":
            q = parse_qs(url.query)
            items = [] if empty else DATA["transactions"]
            if q.get("platforma"):
                items = [t for t in items if t["platforma"] == q["platforma"][0]]
            return self._send(200, {"items": items, "skaits": len(items)})
        if url.path.startswith("/api/v1/transactions/"):
            tx_id = url.path.rsplit("/", 1)[-1]
            tx = next((t for t in DATA["transactions"] if t["id"] == tx_id), None)
            if tx is None or empty:
                return self._error(404, "NOT_FOUND", "Darījums nav atrasts.")
            return self._send(200, tx)
        if url.path == "/api/v1/tax":
            if empty:
                return self._send(200, {**DATA["tax"], "procenti_centos": 0,
                                        "kapitala_pieaugums_centos": 0, "apliekams_centos": 0,
                                        "nodoklis_centos": 0, "neieklauti": 0})
            return self._send(200, DATA["tax"])
        return self._error(404, "NOT_FOUND", "Galapunkts nav atrasts.")

    def log_message(self, fmt, *args):
        print(f"[mock:{state['scenario']}] {self.command} {self.path} {args[1] if len(args) > 1 else ''}")


def main():
    parser = argparse.ArgumentParser(description="Kopsumma testa serveris")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--scenario", choices=SCENARIOS, default="ready")
    args = parser.parse_args()
    state["scenario"] = args.scenario
    print(f"Kopsumma mock: http://localhost:{args.port}  scenārijs={args.scenario}")
    ThreadingHTTPServer(("0.0.0.0", args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
