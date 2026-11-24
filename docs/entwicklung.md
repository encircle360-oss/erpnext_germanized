# Entwicklung

Diese Seite beschreibt Aufbau, Einrichtung, Werkzeuge, Tests, Stil und CI. Wie ein Beitrag abläuft, steht in [CONTRIBUTING.md](../CONTRIBUTING.md), wie das Image aufgebaut ist, in [Architektur](architektur.md).

## Aufbau des Repositories

```text
erpnext_germanized/            Repository
├── apps.json                  Apps und ihre Release-Tags im Format von frappe_docker, Reihenfolge = Installation
├── Containerfile              Rezept des Images, aus frappe_docker v4.2.0 übernommen und angepasst
├── build.sh                   lokaler Build mit denselben Eingaben wie in der CI
├── germanized/                Werkzeuge in Python, nur Standardbibliothek, python -m germanized
│   ├── apps.py                apps.json lesen und gegen die Regeln des Images prüfen
│   ├── containerfile.py       Pins aus den Vorgaben der ARGs und das erste FROM des Containerfile mit Digest lesen
│   ├── node_modules.py        Node.js-Pakete einer Bench auf das kürzen, was nach dem Build noch geladen wird
│   ├── tags.py                Image-Tags aus Git-Ref, Commit und vorhandenen Releases, Prüfung der Release-Tags
│   ├── versions.py            neueste Releases auf GitHub nachsehen, Pins anheben und schreiben
│   ├── readme.py              Tabelle „Enthaltene Apps“ im README prüfen und ihre Versionen setzen
│   ├── summary.py             Zusammenfassung eines Builds für Workflow-Läufe und Release-Notes
│   └── __main__.py            Kommandozeile
├── tests/                     pytest-Tests der Werkzeuge
│   └── site/                  Site-Test des Images: compose.yaml und run.sh
├── examples/compose.yaml      Beispiel für docker compose
├── docs/                      Dokumentation
├── LICENSES/                  Lizenztext von frappe_docker (MIT) für das Containerfile
├── .github/workflows/         CI: Tests, Linters, Security, Image, Release, App versions
├── .github/actions/           Composite Action build-and-test, die beide Jobs des Workflows Image teilen
├── .github/dependabot.yml     wöchentliche Updates für GitHub Actions, Basis-Image, Compose-Dateien, pip und pre-commit
├── .github/ISSUE_TEMPLATE/    Vorlagen für Fehler und Wünsche, Verweise auf Discussions, Matrix und SECURITY.md
├── .github/PULL_REQUEST_TEMPLATE.md
│                              Vorlage für Pull Requests
├── .pre-commit-config.yaml    Hooks für pre-commit
├── pyproject.toml             Paketdaten der Werkzeuge, Einstellungen für ruff, pytest und coverage
└── requirements-dev.txt       Entwicklungswerkzeuge, exakt gepinnt
```

Die Werkzeuge unter `germanized/` kommen nicht ins Image. Sie prüfen das Rezept, leiten die Tags ab und heben Versionen an.

## Einrichtung

Du brauchst Python 3.14, für Build und Site-Test zusätzlich Docker mit Buildx und dem Compose-Plugin sowie `jq` und `timeout`.

```bash
git clone https://github.com/<dein-konto>/erpnext_germanized.git
cd erpnext_germanized
python3.14 -m venv .venv
. .venv/bin/activate
pip install -r requirements-dev.txt
pre-commit install
```

`requirements-dev.txt` bringt coverage, pre-commit, pytest, pytest-cov, ruff und zizmor in festen Versionen, dieselben wie bei Steuerbote. Zur Laufzeit brauchen die Werkzeuge nur die Standardbibliothek. `pre-commit install` richtet die Hooks aus `.pre-commit-config.yaml` ein.

## Werkzeuge

Alle Befehle laufen im Wurzelverzeichnis des Repositories und lesen `apps.json`, `Containerfile` und `README.md` von dort. Bei jedem Problem enden sie mit dem Exit-Code 1 und einer Meldung.

| Befehl | Was er tut |
|---|---|
| `python -m germanized validate` | prüft `apps.json` gegen die Regeln unten |
| `python -m germanized tags --ref REF --sha SHA [--existing TAGS]` | gibt die Image-Tags eines Git-Refs aus, durch Kommas getrennt; `--existing` nimmt die Release-Tags des Repositories, wie `git tag -l 'v*'` sie ausgibt, damit bewegliche Tags nur vorwärts gehen, siehe [Versionierung](versionierung.md#image-tags) |
| `python -m germanized release-check --ref REF` | prüft ein Release-Tag wie `refs/tags/v16.60.0-1` gegen das Tag von ERPNext in `apps.json` |
| `python -m germanized summary [--tags a,b]` | gibt Pins, Apps und Tags eines Builds als Markdown aus, für die Zusammenfassung eines Workflow-Laufs und die Release-Notes |
| `python -m germanized check-versions` | stellt jedem Pin das neueste Release auf seiner Hauptversion gegenüber |
| `python -m germanized bump [--write]` | zeigt, welche Pins sich anheben lassen; mit `--write` schreibt es `apps.json` und `FRAPPE_BRANCH` im `Containerfile` |
| `python -m germanized readme --check` | prüft die Tabelle „Enthaltene Apps“ im README gegen die Pins |
| `python -m germanized readme --write` | setzt die Spalte Version dieser Tabelle auf die Pins |
| `python -m germanized prune-node-modules BENCH` | entfernt die Node.js-Pakete einer Bench, die nach dem Build niemand lädt; läuft im Build in der Stufe `builder`, siehe [Architektur](architektur.md#nodejs-pakete-nach-dem-build) |

`check-versions` und `bump` fragen die API von GitHub ab. Ohne Token lässt GitHub nur 60 Anfragen in der Stunde zu; ist die Umgebungsvariable `GITHUB_TOKEN` gesetzt, schicken die Werkzeuge das Token mit.

Regeln für `apps.json`, die `validate` prüft:

- ein JSON-Array aus Einträgen mit genau den Schlüsseln `url` und `branch`, nicht leer,
- `url` hat die Form `https://github.com/<owner>/<repo>`, ohne `/` am Ende und ohne `.git`,
- keine App doppelt,
- `branch` ist ein Release-Tag der Form `vX.Y.Z`,
- der erste Eintrag ist `https://github.com/frappe/erpnext`,
- jede App hat dieselbe Hauptversion wie Frappe, außer den Apps in `INDEPENDENTLY_VERSIONED` in `germanized/apps.py`, bisher nur Steuerbote.

Die Tabelle im README hat die Spalten `| App | Version | Zweck | Lizenz |`, zuerst eine Zeile für `[frappe](https://github.com/frappe/frappe)`, dann eine Zeile je App in der Reihenfolge von `apps.json`. In der Spalte App steht ein Link mit dem Namen des Repositories, in der Spalte Version das Tag. `readme --write` ändert nur die Spalte Version; Zweck und Lizenz werden von Hand gepflegt.

## Tests

```bash
pytest
```

`pytest` führt die Tests unter `tests/` aus und misst dabei die Abdeckung von `germanized`, Zeilen und Zweige. Unter 100 % schlägt der Lauf fehl (`--cov-fail-under=100` in `pyproject.toml`). Die Tests brauchen kein Netz: Wo ein Werkzeug GitHub fragt, bekommt es im Test eine Funktion, die feste Antworten liefert. Weitere Tests prüfen das Repository selbst, etwa dass `apps.json` gültig ist, dass das erste `FROM` des `Containerfile` das Basis-Image per Digest pinnt und zu `PYTHON_VERSION` und `DEBIAN_BASE` passt und dass die Hooks in `.pre-commit-config.yaml` dieselben Versionen von ruff und zizmor nennen wie `requirements-dev.txt`.

## Testgetrieben arbeiten

1. **Rot:** Schreib zuerst einen Test, der ohne die Änderung fehlschlägt, und sieh ihn fehlschlagen.
2. **Grün:** Schreib die kleinste Änderung, die ihn bestehen lässt.
3. **Aufräumen:** Verbessere Namen und Struktur, während alle Tests grün bleiben.

Kein bestehender Test wird abgeschwächt, übersprungen oder gelöscht, um grün zu werden. Die Werkzeuge behalten 100 % Abdeckung. Testnamen beschreiben die Regel, die sie prüfen.

## Stil

- **ruff** mit der Konfiguration in `pyproject.toml`, wie bei Steuerbote: Einrückung mit Tabs, Zeilen bis 110 Zeichen, doppelte Anführungszeichen, Python 3.14 als Ziel. Regelgruppen F, E, W, I, UP, B, RUF, S, SIM, C4 und T20; ausgenommen sind E101 und W191 wegen der Tabs und E501, weil die Zeilenlänge der Formatierer setzt. In Tests ist `assert` erlaubt.
- **Nur die Standardbibliothek** zur Laufzeit, mit `pathlib`, `dataclasses` und Typangaben. Docstrings an öffentlichen Funktionen.
- **Shell:** `set -euo pipefail`, frei von Befunden von shellcheck.
- **Containerfile:** frei von Befunden von hadolint. Wo das Original von frappe_docker eine Regel verletzt, steht die Ausnahme mit Begründung direkt an der Anweisung, damit sich das Rezept weiter Zeile für Zeile mit dem Original vergleichen lässt.
- **Englisch im Code**, auch in Kommentaren, Meldungen der Werkzeuge und Namen der Workflow-Schritte. Dokumentation, Issues und Pull Requests auf Deutsch.
- **Kommentare erklären das Warum**, nie das Was und nie die Geschichte einer Änderung.
- **pre-commit** führt ruff (`ruff check --fix` und `ruff format`), shellcheck und zizmor aus und prüft JSON und YAML, Leerzeichen am Zeilenende (außer in Markdown), den Zeilenumbruch am Dateiende und große Dateien. Die Lizenztexte bleiben unverändert.

## Lokaler Build und Site-Test

```bash
./build.sh                                   # builds erpnext_germanized:local for linux/amd64
./build.sh --platform linux/arm64            # the same for linux/arm64, natively on an ARM machine
./tests/site/run.sh erpnext_germanized:local
```

`build.sh` prüft zuerst `apps.json` mit `python3 -m germanized validate` und baut dann mit `docker buildx build`: `apps.json` als Secret `apps_json`, `CACHE_BUST` aus der SHA-256-Summe von `apps.json` und `VERSION` aus `git describe --tags --always --dirty`. Optionen: `--tag TAG` für einen anderen Namen, `--push` schiebt das Image in die Registry von `TAG`, statt es lokal zu laden, `--no-cache` baut jede Schicht neu, `--platform` wählt eine andere Plattform als `linux/amd64`. Auf einem Rechner der anderen Plattform baut Docker unter Emulation, und das dauert ein Vielfaches; für den Site-Test einer Plattform baut man am besten auf ihr.

`tests/site/run.sh IMAGE` prüft ein Image so, wie die CI es vor jeder Veröffentlichung tut:

1. Die Apps im Image entsprechen `apps.json`, jede aus dem gepinnten Tag gebaut.
2. Ghostscript ist da, mit dem Profil `srgb.icc` für eu_einvoice.
3. MariaDB 11.8 und Redis starten aus `tests/site/compose.yaml`.
4. In einem Container des Images legt `bench new-site` die Site `test.localhost` mit allen Apps an, und `bench --site test.localhost list-apps` nennt jede davon.
5. gunicorn, der Standardbefehl des Images, beantwortet `/api/method/ping` mit `pong` und liefert die Anmeldeseite als HTML.
6. Der Socket.IO-Server, `node apps/frappe/socketio.js`, startet mit den Node.js-Paketen, die nach dem Build übrig sind, und beantwortet den Handshake von Engine.IO.
7. Jede `<app>/realtime/handlers.js` im Image lädt mit `node`. Socket.IO lädt sie erst bei einer angemeldeten Verbindung und warnt bei einem Fehler nur.
8. nginx vor dem Backend beantwortet den Ping ebenfalls, liefert die Assets aus und leitet `/socket.io/` an den Socket.IO-Server weiter.
9. nginx liefert jede Bibliothek, die die gebauten Assets unter `assets/<app>/node_modules` nennen.
10. Ein eigenes Website Theme lässt sich speichern: Frappe übersetzt sein SCSS mit `node generate_bootstrap_theme.js`, und nginx liefert das Ergebnis als `text/css` aus.

Zum Schluss entfernt das Skript alle Container und Volumes. Nach 20 Minuten bricht es ab. Die Passwörter der Testsite stehen nur in `tests/site/compose.yaml` und gelten nur für diese Wegwerf-Site.

## CI

Ein Pull Request wird erst gemergt, wenn alle Jobs grün sind. Jeder Workflow liest den Inhalt des Repositories nur (`contents: read`); Rechte zum Schreiben bekommen einzelne Jobs, die sie brauchen. Alle Actions sind über den vollen Commit-SHA gepinnt, mit der Version als Kommentar, auch in der Composite Action unter `.github/actions/`.

| Workflow | Wann | Was er tut |
|---|---|---|
| Tests (`tests.yml`) | Pull Requests, Pushes auf `main`, von Hand | `ruff check`, `ruff format --check`, `pytest` mit 100 % Abdeckung, `python -m germanized validate` und `python -m germanized readme --check` |
| Linters (`linters.yml`) | Pull Requests, Pushes auf `main`, von Hand | pre-commit auf allen Dateien, darin shellcheck für `build.sh` und `tests/site/run.sh`; hadolint auf dem `Containerfile`; zizmor auf den Workflows und den Konfigurationen von Dependabot und pre-commit |
| Security (`security.yml`) | Pull Requests, Pushes auf `main`, montags 04:17 UTC, von Hand | gitleaks über die ganze Git-Historie; `trivy config` über das Repository, wobei trivy nur das `Containerfile` erkennt und mit seinen Regeln für Dockerfiles prüft, Compose-Dateien und Workflows nicht (die Workflows prüft zizmor im Workflow Linters); wöchentlich und von Hand zusätzlich trivy über das veröffentlichte Image `latest` |
| Image (`build.yml`) | Pull Requests und Pushes auf `main`, die `Containerfile`, `apps.json`, `build.sh`, `germanized/`, `tests/site/`, `LICENSES/`, `.github/actions/` oder den Workflow selbst ändern; von Hand; als Teil von Release | je Plattform ein Lauf der Composite Action `.github/actions/build-and-test`, die das Image baut, den Site-Test ausführt und das Image mit trivy scannt, `linux/amd64` auf `ubuntu-latest` und `linux/arm64` auf `ubuntu-26.04-arm`: „Build and test“ für Pull Requests, Läufe von Hand und Forks, mit Rechten nur zum Hochladen des Scans; für Pushes auf `main` und von Release-Tags „Build, test and push“, der danach Image per Digest, Cache und SBOM je Plattform schreibt, und „Publish the image“, der beide Images als ein Index unter den Tags veröffentlicht und die Herkunftsangabe schreibt, auf `main` mit den Tags `main` und `main-<sha7>` |
| Release (`release.yml`) | Push eines Tags `v*` | `release-check`, dann Image wie oben mit den Tags des Releases, danach das GitHub-Release mit Release-Notes und je einer SBOM für `linux/amd64` und `linux/arm64` |
| App versions (`versions.yml`) | montags 06:00 UTC, von Hand | hebt die Pins mit `bump --write` an und öffnet bei Änderungen einen Pull Request, siehe [Versionierung](versionierung.md#release-prozess-für-maintainer) |

**Was einen Pull Request anhält und was nur berichtet.** Tests, Linters, gitleaks, der Scan der Konfiguration und im Workflow Image Build und Site-Test halten einen Pull Request an, wenn sie fehlschlagen. Die Scans der Images auf Schwachstellen, im Workflow Image bei jedem Build und wöchentlich für `latest`, sind Berichte: Ihre Befunde kommen aus Debian und den Apps und verschwinden mit einem neuen Build oder einem Update, deshalb halten sie kein Image an. Ihre Befunde landen in Code Scanning; bei Pull Requests aus Forks, die nichts hochladen dürfen, stehen sie im Log des Laufs.

**Veröffentlichen.** Nur Pushes veröffentlichen ein Image: Pushes auf `main` und Pushes von Release-Tags in `encircle360-oss/erpnext_germanized`, mit dem `GITHUB_TOKEN` des Laufs. Pull Requests, Läufe von Hand und Forks bauen und testen nur, im Job „Build and test“, dessen Token außer dem Scan nichts schreiben darf. Der Job „Build, test and push“ baut das Image je Plattform nativ auf einem Runner dieser Plattform und nur einmal: Derselbe Build lädt es in die lokale Docker-Engine für Site-Test und Scan und schiebt es per Digest, noch ohne Tag, in die Registry. Ein zweiter Build für den Push könnte Schichten aus dem Cache nehmen, den ein gleichzeitiger Lauf inzwischen geschrieben hat, etwa das Release zum selben Stand. Nach dem Site-Test bestätigt ein Schritt, dass der Digest das getestete Image ist. Erst wenn beide Plattformen bestanden haben, legt „Publish the image“ einen Index mit genau diesen beiden Digests unter den Tags an und prüft ihn. Scheitert eine Plattform, bekommt kein Tag ein neues Image. Die Caches des Builds, `ghcr.io/encircle360-oss/erpnext_germanized:buildcache` für `linux/amd64` und `:buildcache-arm64` für `linux/arm64` in der Registry, lesen beide Jobs, schreiben darf sie nur „Build, test and push“. Die Herkunftsangabe gilt dem Index, die Scans landen je Plattform in eigenen Kategorien von Code Scanning (`trivy-image` und `trivy-image-arm64`). Herkunftsangabe und Code Scanning nutzt die CI nur in einem öffentlichen Repository; das prüft die Composite Action bei jedem Lauf.

**Dependabot** schlägt jede Woche Updates vor (`.github/dependabot.yml`), jeweils frühestens sieben Tage nach ihrem Erscheinen: für die GitHub Actions der Workflows und der Composite Action unter `.github/actions/`, für das Basis-Image im ersten `FROM` des `Containerfile`, für die Images in `tests/site/compose.yaml` und `examples/compose.yaml` und für die Entwicklungswerkzeuge in `requirements-dev.txt` und `.pre-commit-config.yaml`. Weil das `FROM` das Basis-Image per Digest pinnt, kommen auch neue Builds desselben Tags als Update. Eine neue Minor- oder Hauptversion von Python schlägt Dependabot nicht vor, neue Hauptversionen von MariaDB und Redis ebenso wenig, und das Image dieses Repositories bleibt im Beispiel auf dem Tag `16`. Wechselt das Basis-Image auf eine andere Python-Version oder ein anderes Debian, gehören `PYTHON_VERSION` und `DEBIAN_BASE` von Hand dazu; bis beide passen, schlagen die Tests fehl. pip und pre-commit kommen in einem gemeinsamen Pull Request, damit ruff und zizmor an beiden Stellen gleichzeitig steigen.

## Pins und wo sie stehen

| Was | Wo |
|---|---|
| Apps | `apps.json`, Release-Tags |
| Frappe | `FRAPPE_BRANCH` im `Containerfile` |
| Basis-Image, Python, Debian | erstes `FROM` des `Containerfile` per Tag und Digest, dazu `PYTHON_VERSION` und `DEBIAN_BASE` |
| Node.js, wkhtmltopdf | `NODE_VERSION`, `WKHTMLTOPDF_VERSION` und `WKHTMLTOPDF_DISTRO` im `Containerfile` |
| Dateien aus frappe_docker | Adressen mit `v4.2.0` und SHA-256-Summen im `Containerfile` |
| MariaDB, Redis | `tests/site/compose.yaml` und `examples/compose.yaml`, per Tag |
| GitHub Actions | in den Workflows und in `.github/actions/`, per Commit-SHA mit Version als Kommentar |
| Entwicklungswerkzeuge | `requirements-dev.txt` (`==`), Hooks in `.pre-commit-config.yaml` über `rev`, gitleaks mit Version und SHA-256 in `security.yml` |

Eine Version, die an mehreren Stellen steht, etwa ruff in `requirements-dev.txt` und `.pre-commit-config.yaml`, wird an allen Stellen gleichzeitig angehoben. Für ruff und zizmor prüft das ein Test, der fehlschlägt, solange die beiden Dateien verschiedene Versionen nennen.

## Eine App hinzufügen oder entfernen

Hinzufügen:

1. **Prüfen**, ob die App passt: Releases als Tags `vX.Y.Z`, dieselbe Hauptversion wie Frappe, eine Lizenz, die eine Weitergabe im Image erlaubt, gepflegt und für ERPNext 16 freigegeben (`[tool.bench.frappe-dependencies]` in ihrer `pyproject.toml`).
2. **Test zuerst**, falls sich eine Regel ändert, etwa für eine App mit eigener Versionierung, die in `INDEPENDENTLY_VERSIONED` kommt.
3. **`apps.json`:** einen Eintrag mit `url` und `branch` an der Stelle, an der die App installiert werden soll, also nach den Apps, die sie voraussetzt, und vor Steuerbote.
4. **README:** eine Zeile in der Tabelle „Enthaltene Apps“ an derselben Stelle, mit Zweck aus dem README der App und ihrer Lizenz. `python -m germanized readme --check` muss grün sein.
5. **Beispiel und Dokumentation:** `--install-app` in `create-site` von [examples/compose.yaml](../examples/compose.yaml) und die Liste im Helm-Beispiel in [Betrieb](betrieb.md#auf-kubernetes) ergänzen, jeweils mit dem Namen, unter dem bench die App kennt (der Name aus ihrer `pyproject.toml`). Dazu ein Abschnitt in [Apps](apps.md) und ein Eintrag im [Changelog](../CHANGELOG.md).
6. **Lokal prüfen:** `python -m germanized validate`, `./build.sh` und `./tests/site/run.sh erpnext_germanized:local`.

Entfernen geht in umgekehrter Reihenfolge und ist für bestehende Sites ein Bruch: Eine Site, auf der die App installiert ist, lässt sich mit einem Image ohne die App nicht mehr migrieren. Der Changelog sagt deshalb, was Betreiber vorher tun, nämlich die App mit `bench --site <site> uninstall-app <app>` entfernen, solange das alte Image läuft. Das löscht die Daten der App, also vorher sichern.

## Commits

- Commit-Nachrichten sind englisch, ein Satz, klein geschrieben, im Imperativ, und vervollständigen den Satz „If applied, this commit will …“, etwa `add the site test` oder `pin the actions by digest`.
- Keine Ticket-Präfixe, keine Fußzeilen (Trailer).
- Branches heißen nach dem Thema. Auf `main` wird nicht direkt committet.
- Ein Thema pro Pull Request, die Dokumentation im selben Pull Request.
