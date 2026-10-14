# Darba vienošanās

## Atzari
- `main` — tikai caur pull request, CI jābūt zaļam.
- Nosaukumi: `feat/<īss-apraksts>`, `fix/<...>`, `chore/<...>`, `docs/<...>`.
  Piemēri: `feat/auth-api`, `feat/mintos-parser`, `chore/ci`.

## Commit ziņojumi
Formāts [Conventional Commits](https://www.conventionalcommits.org/):
`feat(auth): bloķēt kontu pēc 5 neveiksmīgiem mēģinājumiem`.
Aizliegti ziņojumi bez satura: „fix”, „update”, „wip”.

## Noslēpumi
- `.env` nekad netiek iesniegts; paraugs — `.env.example`.
- CI palaiž gitleaks katram pull request.

## Pabeigtības definīcija
1. Kods atzarā, pull request izveidots.
2. Testi un linteris izpildās.
3. Akcepta kritēriji pārbaudīti.
4. Apvienots `main` atzarā.
