#!/bin/sh
# Palaišana konteinerā: JWT atslēga (ja nav dota vidē) tiek ģenerēta vienreiz un glabāta
# sējumā, migrācijas, demo dati (SEED_DEMO=1), tad API.
set -e
if [ -z "$JWT_SECRET" ]; then
  KEY_FILE=/data/jwt_secret
  [ -s "$KEY_FILE" ] || python -c "import secrets;print(secrets.token_urlsafe(48))" > "$KEY_FILE"
  JWT_SECRET=$(cat "$KEY_FILE")
  export JWT_SECRET
fi
alembic upgrade head
if [ "$SEED_DEMO" = "1" ]; then
  python -m app.seed
fi
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
