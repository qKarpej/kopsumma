# Sprints 2 · testa versija

**Mērķis:** prototips testēšanas versijas līmenī — lietotājs reģistrējas, importē savus Mintos un Twino izrakstus,
redz portfeli un nodokli un saņem atgādinājumus par termiņiem; lietotne instalējama telefonā un atverama pārlūkā.

**Periods:** 03.11.–decembra prezentācija · **Darba veids:** individuāls.

| # | Vienība | Issue / PR | Statuss |
|---|---|---|---|
| 1 | Importa ekrāni S-04–S-07 (platforma, fails, pārbaude, apstiprināšana) | #14, PR #26 | ✅ |
| 2 | Importa kļūdas ekrāns S-09 ar rindas numuru | #15, PR #26 | ✅ |
| 3 | Imports pabeigts S-08, importu vēsture, atcelšana (API-07) | #17, PR #25, #26 | ✅ |
| 4 | Twino parsētājs (otrā platforma) | PR #25 | ✅ |
| 5 | Reģistrācija S-02a, sesijas atjaunošana ar rotāciju (API-03/04) | PR #25, #26 | ✅ |
| 6 | Nodokļa termiņi (API-12), paziņojumi telefonā, Google kalendārs, .ics | PR #25, #26 | ✅ |
| 7 | `docker compose up` — API + DB + demo dati + web lietotne | PR #25 | ✅ |
| 8 | Testa būvējumi: Android APK un web CI; laidiena darbplūsma | PR #26 | ✅ |

**Testi:** backend 66 (t. sk. Twino parsētājs, importa plūsma, termiņi, sesijas rotācija), testa serveris 7,
Flutter — API klients, kalendāra loģika, importa / reģistrācijas / termiņu ekrānu scenāriji.

**Kas nav izdarīts:** iOS būvējums (nav macOS CI), īsts hostings internetā (demo — lokālais Docker),
konta dzēšana, valūtu konvertācija ne-EUR darījumiem (tie paliek „jāpārbauda”).

**Godīgi par vēsturi:** sprinta izstrādes komiti veikti 24.11.; nedēļas ritms netika ievērots.

**Procesa pašpārbaude:** atzari `feat/…` ✓ · commit ziņojumi ✓ · nav .env/atslēgu (gitleaks, .gitleaksignore tikai testu
viltus trauksmēm) ✓ · CI zaļš, ieskaitot APK un web būvējumu ✓ · apvienots tikai pēc zaļa CI ✓.
