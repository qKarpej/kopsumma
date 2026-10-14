# Sprints 1 · 05.10.–12.10.2026

**Mērķis:** lietotājs var pieteikties lietotnē un importēt Mintos CSV izrakstu, redzot importa
kopsavilkumu (jauni darījumi, dublikāti, kļūdas rinda) pirms saglabāšanas.

**Pieejamais laiks:** 12 h · **Plānots:** 12 h (5 vienības) · **Milestone:** Sprints 1

| # | Vienība | Issue | PR | h | Statuss |
|---|---|---|---|---|---|
| 1 | Repozitorijs, CI un projektu skeleti | #1 | #7 | 2 | ✅ |
| 2 | DB shēma un migrācija | #2 | #8 | 2 | ✅ |
| 3 | Reģistrācija un pieteikšanās API (API-01, API-02) | #3 | #9 | 3 | ✅ |
| 4 | Pieteikšanās ekrāns S-02 ar kļūdas stāvokli | #4 | #10 | 2 | ✅ |
| 5 | Mintos CSV parsētājs un API-05 | #5 | #11 | 3 | ✅ |
| 6 | Importa apstiprināšana API-06 | #6 | — | 3 | ⏭ izmests plānošanā, sprints 2 |

## Pabeigtības definīcija
1. Kods atzarā, pull request izveidots.
2. Testi un linteris izpildās (CI: ruff, pytest, migrācija, flutter analyze, flutter test, gitleaks).
3. Akcepta kritēriji pārbaudīti (atzīmēti issue).
4. Apvienots `main` ar merge commit.

## Atšķirība no plāna
Kods un pull request repozitorijā iesniegti 14.10.2026., pēc sprinta beigām — commit datumi to
rāda. Pirmajā CI palaišanā (#7) migrācijas solis krita, jo alembic vēl nebija pievienots;
salabots ar nosacījumu workflow failā.

## Izmaiņa nākamajam sprintam
Commit un push katru darba dienu, nevis sprinta beigās, lai vēsture atspoguļo reālo darba gaitu.
