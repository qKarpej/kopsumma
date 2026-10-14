from fastapi import FastAPI

from app import errors

app = FastAPI(title="Kopsumma API", version="0.1.0")
errors.install(app)


@app.get("/health")
def health():
    return {"status": "ok"}
