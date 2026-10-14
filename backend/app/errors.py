"""Vienots kļūdu formāts visiem galapunktiem (K3, 3.1)."""

import uuid

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


class ApiError(Exception):
    def __init__(
        self,
        status: int,
        code: str,
        message: str,
        detail: str | None = None,
        field: str | None = None,
    ):
        self.status, self.code, self.message = status, code, message
        self.detail, self.field = detail, field


def _body(request: Request, code, message, detail=None, field=None) -> dict:
    return {
        "error": {
            "code": code,
            "message": message,
            "detail": detail,
            "field": field,
            "request_id": getattr(request.state, "request_id", None),
        }
    }


def install(app: FastAPI) -> None:
    @app.middleware("http")
    async def request_id(request: Request, call_next):
        request.state.request_id = request.headers.get("X-Request-ID") or uuid.uuid4().hex
        response = await call_next(request)
        response.headers["X-Request-ID"] = request.state.request_id
        return response

    @app.exception_handler(ApiError)
    async def api_error(request: Request, exc: ApiError):
        return JSONResponse(
            status_code=exc.status,
            content=_body(request, exc.code, exc.message, exc.detail, exc.field),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_error(request: Request, exc: RequestValidationError):
        first = exc.errors()[0] if exc.errors() else {}
        field = ".".join(str(p) for p in first.get("loc", [])[1:]) or None
        return JSONResponse(
            status_code=422,
            content=_body(
                request,
                "VALIDATION_ERROR",
                "Pārbaudiet ievadītos datus.",
                first.get("msg"),
                field,
            ),
        )
