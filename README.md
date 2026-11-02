# Kopsumma

- **Testa serveris:** `python3 mock/server.py` → http://localhost:8080 (scenārijs: `--scenario empty|error|slow` vai `/__scenario/error` darbības laikā)
- **Lietotne:** `cd mobile && flutter pub get && flutter run -d chrome --dart-define-from-file=config/mock.json` · pieteikšanās `anna@inbox.lv` / `Kopsumma2026`
- **Īstais API:** `docker compose up --build` un `docker compose exec api python -m app.seed`, lietotnei `--dart-define-from-file=config/local-api.json --web-port 5000`
- **Testi:** `cd backend && pytest` · `cd mock && pytest` · `cd mobile && flutter test`

Mobilā lietotne privātajam investoram: ieguldījumi no vairākām platformām (Mintos, Twino)
vienā portfelī un iedzīvotāju ienākuma nodokļa aprēķins pēc Latvijas normām.

Studiju projekts · Finanšu jomas mobilo lietotņu izstrāde · Aleksejs Pjavka

| Mape | Saturs |
|---|---|
| `backend/` | FastAPI + PostgreSQL API (K3 API līgums) |
| `mobile/` | Flutter klients |
| `docs/` | Sprintu pieraksti |

## Palaišana

```bash
cp .env.example .env        # aizpildiet vērtības
docker compose up --build   # API: http://localhost:8000/docs
```

### Backend lokāli
```bash
cd backend
pip install -r requirements-dev.txt
export JWT_SECRET=$(python -c "import secrets;print(secrets.token_urlsafe(32))")
pytest && ruff check .
```

### Mobilā lietotne
```bash
cd mobile
flutter pub get && flutter test
flutter run -d chrome --dart-define-from-file=config/mock.json            # testa serveris
flutter run --dart-define-from-file=config/android-emulator.json          # Android emulators
```
API bāzes adrese nāk no `API_BASE_URL` (`lib/config.dart`), konfigurācijas faili — `mobile/config/`.

## Statuss
Sprints 1 (12.10.–02.11.2026): vertikālā šķēle pieteikšanās → portfelis → darījumi → nodoklis caur testa serveri un īsto API — sk. `docs/sprints/sprint-1.md`.
