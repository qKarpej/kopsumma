# Kopsumma

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
flutter create --platforms=android,ios .   # vienreiz: izveido platformu mapes
flutter pub get && flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Statuss
Sprints 1 (05.–12.10.2026): reģistrācija, pieteikšanās, Mintos izraksta pārbaude — sk. `docs/sprints/`.
