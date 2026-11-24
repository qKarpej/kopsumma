"""Kopsumma testa serveris (mock). Tikai Python standarta bibliotēka.

Palaišana:  python mock/server.py            (http://localhost:8080)
Scenārijs:  python mock/server.py --scenario empty   (ready | empty | error | slow)
Pārslēgt darbības laikā: atver http://localhost:8080/__scenario/error

Atbilst tam pašam API līgumam, ko īstais FastAPI serveris (API-01…API-12).
Imports: fails, kura nosaukumā ir „bojats”, atgriež kļūdu ar rindas numuru.
"""

import argparse
import json
import re
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

DATA = json.loads((Path(__file__).parent / "data.json").read_text(encoding="utf-8"))
SCENARIOS = ("ready", "empty", "error", "slow")
state = {"scenario": "ready", "imports": {}}
TOKENS = {"access_token": "mock-access", "refresh_token": "mock-refresh", "token_type": "bearer",
          "expires_in": 900}


def empty_portfolio():
    return {"valuta": "EUR", "kopsumma_centos": 0, "ienakumi_ceturksni_centos": 0,
            "platformas": [], "nodoklis": None}


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, body):
        raw = b"" if status == 204 else json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type, Idempotency-Key")
        self.send_header("X-Request-ID", self.request_id)
        self.send_header("Content-Length", str(len(raw)))
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

    def _body(self) -> bytes:
        return self.rfile.read(int(self.headers.get("Content-Length", 0)))

    def do_POST(self):  # noqa: N802
        self.request_id = uuid.uuid4().hex
        path = urlparse(self.path).path
        raw = self._body()
        if path == "/api/v1/auth/login":
            body = json.loads(raw or b"{}")
            if body.get("parole") != "Kopsumma2026":
                return self._error(401, "INVALID_CREDENTIALS", "E-pasts vai parole nav pareiza.")
            return self._send(200, TOKENS)
        if path == "/api/v1/auth/register":
            body = json.loads(raw or b"{}")
            if body.get("epasts") == "anna@inbox.lv":
                return self._error(409, "EMAIL_TAKEN", "Šis e-pasts jau ir reģistrēts.")
            return self._send(201, {"lietotaja_id": uuid.uuid4().hex})
        if path == "/api/v1/auth/refresh":
            return self._send(200, TOKENS)
        if path == "/api/v1/auth/logout":
            return self._send(204, {})
        if not self._authorized():
            return None
        if state["scenario"] == "error":
            return self._error(503, "SERVICE_UNAVAILABLE", "Nav savienojuma ar serveri. Jūsu dati ir saglabāti.")
        if path == "/api/v1/imports":
            return self._upload(raw)
        m = re.fullmatch(r"/api/v1/imports/([\w-]+)/(confirm|cancel)", path)
        if m and m.group(1) in state["imports"]:
            imp = state["imports"][m.group(1)]
            if m.group(2) == "cancel":
                imp["statuss"] = "atcelts"
                return self._send(200, imp)
            imp["statuss"] = "apstiprinats"
            return self._send(200, {"importa_id": imp["importa_id"], "saglabati": imp["jauni"],
                                    "dublikati": imp["dublikati"]})
        return self._error(404, "NOT_FOUND", "Galapunkts nav atrasts.")

    def _upload(self, raw: bytes):
        filename = (re.search(rb'filename="([^"]*)"', raw) or [b"", b"izraksts.csv"])[1].decode()
        pid = re.search(rb'name="platformas_id"\r\n\r\n(\d+)', raw)
        platform = "Twino" if pid and pid.group(1) == b"2" else "Mintos"
        if "bojats" in filename:
            return self._send(422, {"error": {
                "code": "IMPORT_INVALID_ROW", "message": "47. rindā: Summa 'abc' nav skaitlis.",
                "detail": "Summa 'abc' nav skaitlis", "field": "fails.row[47]", "request_id": self.request_id}})
        rows = max(0, raw.count(b"\n") - 6)  # aptuveni: rindas mīnus multipart galvenes
        imp = {"importa_id": uuid.uuid4().hex, "statuss": "parbaude", "rindas": rows, "jauni": rows,
               "dublikati": 0, "izlaisti": 0, "platforma": platform, "faila_nosaukums": filename,
               "periods": {"no": "2026-10-01", "lidz": "2026-11-20"}, "ienakumi_centos": 9428,
               "kludas_rinda": None, "izveidots": "2026-11-24T10:00:00+00:00"}
        state["imports"][imp["importa_id"]] = imp
        return self._send(201, imp)

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
        if url.path == "/api/v1/platforms":
            return self._send(200, DATA["platforms"])
        if url.path == "/api/v1/auth/me":
            return self._send(200, {"lietotaja_id": "mock", "epasts": "anna@inbox.lv"})
        if url.path == "/api/v1/imports":
            return self._send(200, {"items": list(reversed(state["imports"].values()))})
        if url.path == "/api/v1/deadlines":
            return self._send(200, {"items": [], "nakamais": None} if empty else DATA["deadlines"])
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
