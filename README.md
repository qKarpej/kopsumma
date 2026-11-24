# Kopsumma

- **Viss ar vienu komandu:** `docker compose up --build` → lietotne http://localhost:3000, API http://localhost:8000/docs · demo konts `anna@inbox.lv` / `Kopsumma2026`
- **Telefonā (Android):** APK no [Actions → „Testa versija”](../../actions/workflows/release.yml) (artefakts `kopsumma-testa-versija`) → sākuma ekrānā „Servera adrese” → `http://<datora-IP>:8000`
- **Testa serveris:** `python3 mock/server.py` (:8080, scenāriji `--scenario empty|error|slow`) · lietotne: `cd mobile && flutter run -d chrome --dart-define-from-file=config/mock.json`
- **Testi:** `cd backend && pytest` · `cd mock && pytest` · `cd mobile && flutter test`

Lietotne privātajam investoram: ieguldījumi no vairākām platformām (Mintos, Twino) vienā portfelī,
iedzīvotāju ienākuma nodokļa aprēķins pēc Latvijas normām un atgādinājumi par deklarēšanas termiņiem.
Lietotne naudu nepārskaita — tikai nolasa lietotāja augšupielādētus izrakstus.

Studiju projekts · Finanšu jomas mobilo lietotņu izstrāde · Aleksejs Pjavka

## Ko var izdarīt (testa versija 0.2)

| Funkcija | Ekrāni | API |
|---|---|---|
| Reģistrācija, pieteikšanās, sesija paliek pēc restartēšanas | S-01, S-02, S-02a | API-01…04 |
| Mintos un Twino izraksta imports: pārbaude → apstiprināšana, dublikāti netiek saglabāti, kļūda ar rindas numuru | S-04…S-09 | API-05…07 |
| Portfelis pa platformām, darījumi ar filtru | S-03, S-10, S-11 | API-08…10 |
| Nodoklis pa ceturkšņiem (25,5 %, 1000 € slieksnis) | S-12 | API-11 |
| Termiņi: paziņojumi telefonā, Google kalendārs, .ics pārlūkā | S-14 | API-12 |

Imports strādā arī datora pārlūkā (http://localhost:3000) — izrakstu ērtāk lejupielādēt un augšupielādēt datorā,
bet portfeli un atgādinājumus skatīties telefonā. Demo izraksti: `demo/mintos_2026_07-09.csv`, `demo/twino_2026-10-11.csv`.

| Mape | Saturs |
|---|---|
| `backend/` | FastAPI + PostgreSQL API, parsētāji, nodokļa loģika |
| `mobile/` | Flutter lietotne (Android, iOS, web) |
| `mock/` | Testa serveris ar to pašu API līgumu |
| `demo/` | Demo izraksti importa demonstrācijai |
| `docs/` | Sprintu pieraksti |

## Palaišana sīkāk

### Docker (ieteicams)
```bash
docker compose up --build        # pirmā būvēšana ~5 min (Flutter web)
```
`.env` nav obligāts: JWT atslēga tiek ģenerēta konteinerā, demo dati ielādēti automātiski (`SEED_DEMO=1`).

### Telefons tajā pašā Wi-Fi tīklā
1. Datorā: `docker compose up --build`; uzziniet datora IP (`ipconfig` / `ip a`).
2. Telefonā instalējiet APK: Actions → „Testa versija” → pēdējais palaidums → artefakts `kopsumma-testa-versija` (zip ar APK).
3. Lietotnē: Sākums → „Servera adrese” → `http://192.168.x.x:8000` → pieteikties.

### Backend bez Docker
```bash
cd backend && pip install -r requirements-dev.txt
export JWT_SECRET=$(python -c "import secrets;print(secrets.token_urlsafe(32))")
alembic upgrade head && python -m app.seed && uvicorn app.main:app --reload
```

### Flutter
```bash
cd mobile && flutter pub get && flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000     # īstais API
flutter run --dart-define-from-file=config/android-emulator.json          # Android emulators + mock
```

## Statuss
- Sprints 1 (12.10.–02.11.): vertikālā šķēle — `docs/sprints/sprint-1.md`
- Sprints 2 (03.11.–07.12.): testa versija — `docs/sprints/sprint-2.md`
