# Sprints 1 · plāns un rezultāts

**Mērķis:** lietotājs var importēt Mintos izrakstu no telefona, apstiprināt to un redzēt portfeļa kopsummu.

**Produkta stāvoklis sprinta sākumā:** pieteikšanās (S-02), API-05 izraksta pārbaude, CI — sk. `sprint-0.md`.

**Pieejamais laiks:** 12 h · **Plānots:** 11 h

| # | Vienība | Issue | h | Atbildīgais |
|---|---|---|---|---|
| 1 | Importa apstiprināšana API-06 | #6 (PR #13) | 1 | Aleksejs Pjavka |
| 2 | Importa ekrāni S-04–S-07 | #14 | 4 | Aleksejs Pjavka |
| 3 | Importa kļūdas ekrāns S-09 | #15 | 2 | Aleksejs Pjavka |
| 4 | Portfeļa API-08 un S-03 ar datiem | #16 | 3 | Aleksejs Pjavka |
| 5 | Imports pabeigts S-08 | #17 | 1 | Aleksejs Pjavka |

## Komandas biedru uzdevumi
- **Iļja Molčanovs** — koda apskate: PR #13, trīs komentāri pie konkrētām rindām.
- **Sebastjans Peive** — procesa pārbaude: atzari, commit ziņojumi, .gitignore un noslēpumi, CI, DoD.

## Pabeigtības definīcija
Kods atzarā, PR izveidots · testi un linteris izpildās · akcepta kritēriji pārbaudīti · apvienots `main`.

## Sprints pagarināts līdz 02.11. (K5) — vertikālā šķēle
K5 mērķis aizstāja daļu no sākotnējā plāna: viens scenārijs no ekrāna līdz datiem un atpakaļ.

**Mērķis:** lietotājs piesakās un redz portfeļa kopsummu, darījumus un nodokļa aprēķinu — ekrāns → API klients → testa serveris / API → ekrāns.

| # | Vienība | PR / issue | Plāns h | Fakts h | Statuss |
|---|---|---|---|---|---|
| 1 | Importa apstiprināšana API-06 | #6, PR #13 | 1 | 1 | ✅ |
| 2 | Testa serveris (`mock/`), 4 scenāriji | PR #19 | 1 | 1 | ✅ |
| 3 | Naudas loģika + testi (`money.py`) un portfeļa/nodokļa API | #16, PR #20 | 3 | 3 | ✅ |
| 4 | Flutter karkass, navigācija, API klients | PR #21, #22 | 3 | 4 | ✅ |
| 5 | Četri stāvokļi + logrīku testi | PR #21 | 1 | 2 | ✅ |
| 6 | Importa ekrāni S-04–S-09 | #14, #15, #17 | 7 | 0 | ❌ → sprints 2 |

**Kas nav izdarīts un kāpēc:** importa ekrāni — prioritāte tika dota pilnai šķēlei ar datiem, nevis vairākiem ekrāniem bez datiem.
Turklāt izraksta importēšana telefonā ir neērta (fails jālejupielādē no platformas), tāpēc importa kanāls tiks pārskatīts.

**Godīgi par vēsturi:** sprinta izstrādes komiti ir veikti 02.11.; nedēļas starppunktos komitu nav. Vēsture nav pārrakstīta.

**Viena izmaiņa nākamajam sprintam:** vismaz viens neliels PR katru nedēļu (izstrāde pa daļām, nevis pēdējā dienā).

**Komandas biedru uzdevumi (PR #13 koda apskate, procesa pārbaude):** līdz 02.11. nav saņemti.
