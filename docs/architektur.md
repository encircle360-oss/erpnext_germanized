# Architektur

erpnext_germanized ist ein Rezept für ein Image, keine eigene App. Das Rezept besteht aus `apps.json` mit den Apps und ihren Tags, dem `Containerfile` aus frappe_docker und `build.sh` für den lokalen Build. Ins Image kommt kein eigener Code dieses Repositories, nur Frappe, die Apps aus `apps.json` und ihre Laufzeit. Diese Seite beschreibt, wie das Image entsteht und was darin steckt. Den Betrieb beschreibt [Betrieb](betrieb.md), Werkzeuge und CI [Entwicklung](entwicklung.md).

## Das Rezept und sein Ursprung

Das `Containerfile` ist `images/custom/Containerfile` aus [frappe_docker](https://github.com/frappe/frappe_docker) v4.2.0, das Rezept, das frappe_docker für Images mit eigenen Apps vorsieht. Es steht wie das Original unter der MIT-Lizenz, ihr Text liegt in `LICENSES/frappe_docker.MIT.txt`. Gegenüber dem Original ändert sich nur:

- **Ghostscript** wird in der Stufe `base` installiert, siehe [Ghostscript](#ghostscript).
- **Die Vorgaben der ARGs sind die Pins:** `FRAPPE_BRANCH` nennt statt des Branches `version-16` ein Release-Tag von Frappe; welches, zeigt die Tabelle im [README](../README.md#enthaltene-apps). Dazu kommen `FRAPPE_PATH=https://github.com/frappe/frappe`, `PYTHON_VERSION=3.14`, `DEBIAN_BASE=trixie`, `NODE_VERSION=24`, `WKHTMLTOPDF_VERSION=0.12.6.1-3` und `WKHTMLTOPDF_DISTRO=bookworm`. `INSTALL_CHROMIUM` bleibt wie im Original auf `true`.
- **Das erste `FROM` nennt das Basis-Image wörtlich und pinnt es per Digest**, `python:3.14-slim-trixie@sha256:…`, damit Dependabot es aktualisieren kann: Der Digest ändert sich mit jedem neuen Build des Tags, etwa mit einer neuen Patch-Version von Python oder Korrekturen aus Debian. Tests in `tests/` prüfen, dass der Digest dasteht und dass das Image zu `PYTHON_VERSION` und `DEBIAN_BASE` passt.
- **OCI-Labels** beschreiben das Image, siehe [Labels](#labels).
- **Ein eigener `RUN` in der Stufe `builder` entfernt die Node.js-Pakete, die nach dem Build niemand lädt**, siehe [Node.js-Pakete nach dem Build](#nodejs-pakete-nach-dem-build).

Die Startskripte und die nginx-Vorlage, die das Original aus seinem Verzeichnis `resources/core` kopiert, kommen unverändert aus derselben Version von frappe_docker. Das `Containerfile` lädt sie beim Build und prüft dabei ihre SHA-256-Summe. Der Kopf des `Containerfile` nennt jede Abweichung vom Original, damit sich die nächste Version von frappe_docker Zeile für Zeile vergleichen lässt.

## Stufen des Containerfile

| Stufe | Was sie tut |
|---|---|
| `base` | Debian trixie mit Python 3.14 aus `python:3.14-slim-trixie`. Legt den Benutzer `frappe` an (UID 1000, Gruppe 0) und installiert nginx, git, die Clients von MariaDB und PostgreSQL, restic und gpg für Sicherungen, wait-for-it und jq, die Bibliotheken für WeasyPrint, Ghostscript, wkhtmltopdf mit gepatchtem Qt und Chromium als `chromium-headless-shell`. Node.js 24 kommt über nvm mit yarn und pnpm, bench über pip. nginx läuft ohne root, die Verzeichnisse gehören der Gruppe 0, damit das Image auch mit beliebiger UID läuft, etwa unter OpenShift. |
| `builder` | Installiert Compiler und Entwicklungsbibliotheken, die Python-Pakete der Apps zum Bauen brauchen. Führt `bench init` mit Frappe aus `FRAPPE_PATH` zum Tag `FRAPPE_BRANCH` und den Apps aus `apps.json` aus und entfernt danach die `.git`-Verzeichnisse der Apps. Ein zweiter `RUN` entfernt die Node.js-Pakete, die nur zum Bauen da waren. |
| `backend` | Das Image, das veröffentlicht wird. Kopiert die fertige Bench aus `builder` nach `/home/frappe/frappe-bench`, ohne Compiler und Entwicklungsbibliotheken. Verschiebt die gebauten Assets aus `sites/assets` nach `/home/frappe/frappe-bench/assets`, damit sie zum Image gehören und nicht zum Volume `sites`, und setzt Volumes, Entrypoint, Befehl und Labels. |

## apps.json als Build-Secret

`apps.json` kommt als BuildKit-Secret `apps_json` in den Build, wie frappe_docker es vorsieht. Das Secret liegt nur während des einen `RUN` mit `bench init` unter `/opt/frappe/apps.json` und landet in keiner Schicht des Images.

- `bench init --apps_path=/opt/frappe/apps.json` holt jede App mit `git clone --branch <tag>`. `git clone` nimmt für `--branch` auch Tags, deshalb steht in `apps.json` unter `branch` das Release-Tag.
- bench installiert die Apps in der Reihenfolge von `apps.json`. `erpnext` steht deshalb vor allen Apps, die darauf aufbauen.
- bench legt jede App unter dem Namen aus ihrer `pyproject.toml` ab. Für `erpnext_pdf-on-submit` ist das `pdf_on_submit`. Unter diesem Namen erwarten sie auch `bench --site <site> install-app` und `bench new-site --install-app`.
- Fehlt das Secret oder ist es leer, baut das Original ohne Fehler ein Image nur mit Frappe. Dem Site-Test fällt das auf, denn er vergleicht die Apps im Image mit `apps.json`.

`build.sh` und die CI übergeben das Secret auf dieselbe Weise: `build.sh` mit `--secret id=apps_json,src=apps.json`, die CI über `secret-files` von `docker/build-push-action`.

## CACHE_BUST

BuildKit nimmt den Inhalt eines Secrets nicht in den Schlüssel seines Caches auf. Ohne weiteres Zutun würde ein geändertes `apps.json` deshalb die zwischengespeicherte Schicht mit `bench init` wiederverwenden, und das Image enthielte die alten Apps. Das Build-Argument `CACHE_BUST` verhindert das. `build.sh` und die CI setzen es auf die ersten 16 Zeichen der SHA-256-Summe von `apps.json`, und der `RUN` mit `bench init` liest es. Ändert sich `apps.json`, ändert sich `CACHE_BUST`, und die Schicht wird neu gebaut.

## Labels

| Label | Inhalt |
|---|---|
| `org.opencontainers.image.source` | `https://github.com/encircle360-oss/erpnext_germanized` |
| `org.opencontainers.image.title` | `erpnext_germanized` |
| `org.opencontainers.image.description` | eine Zeile auf Englisch |
| `org.opencontainers.image.licenses` | `Apache-2.0 AND MIT AND GPL-3.0-only AND GPL-3.0-or-later AND AGPL-3.0-or-later`: das Rezept (Apache-2.0, das `Containerfile` MIT) und die Apps im Image; Einzelheiten nennt das [README](../README.md#lizenz) |
| `org.opencontainers.image.version` | aus dem Build-Argument `VERSION`, Vorgabe `dev`; `build.sh` setzt es auf die Ausgabe von `git describe --tags --always --dirty`, die CI bei einem Release auf das Tag und sonst ebenfalls auf `git describe` |
| `org.opencontainers.image.base.name` | das Basis-Image, `docker.io/library/python:3.14-slim-trixie` |

Das Label `org.opencontainers.image.source` verbindet das Paket in der GitHub Container Registry mit diesem Repository. Die Labels eines Images zeigt `docker image inspect --format '{{json .Config.Labels}}' <image>`.

Neue Tags zeigen auf einen Index mit einem Image je Plattform. Für ein solches Image liest die GitHub Container Registry Beschreibung, Quelle und Lizenz aus den Annotationen des Index, nicht aus den Labels ([Working with the Container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#adding-a-description-to-multi-arch-images)). Der Job „Publish the image“ übernimmt `org.opencontainers.image.description`, `org.opencontainers.image.source` und `org.opencontainers.image.licenses` deshalb aus den Labels in den Index.

## Was im Image steckt

| Was | Wo oder wie |
|---|---|
| Bench | `/home/frappe/frappe-bench` mit `apps/`, der Python-Umgebung `env/`, `sites/`, `logs/` und den Assets unter `assets/`; Arbeitsverzeichnis des Images |
| Benutzer | `frappe`, UID 1000, Gruppe 0; das Image läuft nicht als root |
| Volumes | `/home/frappe/frappe-bench/sites` und `/home/frappe/frappe-bench/logs` |
| Entrypoint | `/usr/local/bin/entrypoint.sh` verlinkt beim Start die Assets des Images nach `sites/assets` und führt dann den Befehl aus. So passen die Assets im Volume immer zum laufenden Image. |
| Befehl (Vorgabe) | `start.sh` startet gunicorn auf Port 8000. `GUNICORN_WORKERS` (Vorgabe 2), `GUNICORN_THREADS` (4) und `GUNICORN_TIMEOUT` (120 Sekunden) steuern ihn. |
| Frontend | `nginx-entrypoint.sh` startet nginx auf Port 8080 (`NGINX_LISTEN_PORT`). nginx liefert Assets und Dateien aus und leitet alles andere an `BACKEND` und `SOCKETIO` weiter, siehe [Betrieb](betrieb.md#reverse-proxy). |
| Websocket | `node /home/frappe/frappe-bench/apps/frappe/socketio.js` auf Port 9000, sofern `socketio_port` in `common_site_config.json` keinen anderen nennt |
| Worker und Scheduler | `bench worker --queue <queues>` und `bench schedule` |
| Python, Node.js | Python 3.14 aus dem Basis-Image, Node.js 24 über nvm unter `/home/frappe/.nvm` |
| PDF | wkhtmltopdf 0.12.6.1-3, Chromium unter `/usr/lib/chromium/chromium-headless-shell` und die Bibliotheken für WeasyPrint. Welcher Generator ein PDF erzeugt, wählt Frappe 16 nach dem Feld „PDF-Generator“ des Druckformats, sonst nach der Vorgabe in den Druckeinstellungen: wkhtmltopdf, chrome oder PlutoPrint, auf einer neuen Site chrome. Typst und WeasyPrint gibt es nur für Druckformate aus dem Print Format Editor, dem visuellen Editor für Druckformate (`resolve_pdf_generator` in `frappe/utils/print_utils.py`). |
| Ghostscript | für die Umwandlung in PDF/A-3 durch eu_einvoice |
| Clients und Werkzeuge | `mariadb` und `psql` für `bench` und Sicherungen, restic und gpg, wait-for-it, jq, git, curl, vim |

Alle Dienste laufen aus demselben Image, nur mit anderem Befehl. Welcher Dienst welchen Befehl bekommt, zeigt [examples/compose.yaml](../examples/compose.yaml).

### Ghostscript

eu_einvoice wandelt ein PDF in PDF/A-3 um, bevor es die XML einer ZUGFeRD-Rechnung einbettet. Dafür ruft es Ghostscript (`gs`) auf und braucht das ICC-Profil `srgb.icc` in dessen Suchpfad. Ist `gs` nicht installiert, überspringt eu_einvoice die Umwandlung ohne Meldung und bettet die XML in das ursprüngliche PDF ein. Schlägt die Umwandlung fehl, schreibt es einen Eintrag ins Fehlerprotokoll und bettet ebenfalls in das ursprüngliche PDF ein (`eu_einvoice/european_e_invoice/einvoice.py`, Funktion `attach_xml_to_pdf`). frappe_docker installiert Ghostscript nicht, deshalb kommt es hier dazu. Der Site-Test prüft, dass `gs` und `srgb.icc` im Image sind.

### Chromium

`INSTALL_CHROMIUM=true` installiert `chromium-headless-shell` aus Debian. Frappe nutzt Chromium, wenn ein Druckformat oder die Druckeinstellungen den PDF-Generator „chrome“ wählen. Den Pfad liest Frappe aus `chromium_path` in `common_site_config.json`. Fehlt der Eintrag, lädt Frappe beim ersten Gebrauch selbst ein Chromium in das Verzeichnis `chromium` der Bench (`find_or_download_chromium_executable` in `frappe/utils/print_utils.py`). Im Container liegt dieses Verzeichnis nicht in einem Volume, und der Download braucht Internetzugang. Das Beispiel für docker compose setzt `chromium_path` deshalb auf `/usr/lib/chromium/chromium-headless-shell`. Der Site-Test setzt den Eintrag genauso und erzeugt mit beiden Generatoren je ein PDF: mit wkhtmltopdf über `frappe.utils.pdf.get_pdf`, Seitenzahlen im Footer eingeschlossen, und mit Chromium über `frappe.get_print`, den Weg des Druck-Knopfs.

## Node.js-Pakete nach dem Build

`bench init` installiert die Node.js-Abhängigkeiten jeder App und der Oberflächen in den Apps (etwa `hrms/frontend`, `frappe/flow`, `erpnext/islands`) und baut damit die Assets. Danach liegen in der Bench rund 2,7 GB `node_modules`, fast alles Compiler, Bundler und esbuild-Programme, die zur Laufzeit niemand startet. Scanner melden ihre Schwachstellen trotzdem, denn sie sehen nur, was im Image liegt.

Der zweite `RUN` der Stufe `builder` ruft deshalb `python -m germanized prune-node-modules` auf (`germanized/node_modules.py`). Die Werkzeuge kommen über einen Bind-Mount in den Build und landen nicht im Image. Behalten wird, was nach dem Build noch geladen wird, jeweils mit allen Paketen, von denen es abhängt:

- **Socket.IO:** die Pakete, die `apps/frappe/socketio.js` und alles, was es über relative Pfade lädt, mit `require` oder `import` einbinden, dazu die des Verzeichnisses `realtime` jeder App, aus dem der Server `<app>/realtime/handlers.js` lädt. Heute sind das `socket.io`, `@redis/client` und `cookie`.
- **Website Themes:** Speichert jemand ein Website Theme, übersetzt Frappe dessen SCSS mit `node generate_bootstrap_theme.js`. Behalten werden deshalb die Pakete, die dieses Skript über relative Pfade lädt (`sass`, dazu `fast-glob` und `chalk` aus `esbuild/utils.js`), und jedes Paket, das die SCSS-Dateien unter `<app>/<app>/public` mit `@import`, `@use` oder `@forward` einbinden, etwa `bootstrap`.
- **Bibliotheken für den Browser:** jedes Paket, das die gebauten Assets oder die Quellen einer App als `assets/<app>/node_modules/<paket>` nennen, etwa `qz-tray` und `js-sha256` für den Direktdruck, `html5-qrcode` für den Scanner, `frappe-gantt`, `photoswipe`, `ace-builds` und `occt-import-js` für 3D-Modelle in ERPNext.

Alles andere fällt weg: die `node_modules` der Oberflächen in den Apps ganz, aus jedem übrigen `node_modules` alle nicht behaltenen Pakete und jeder Eintrag mit Punkt am Anfang, also `.bin`, Caches wie `.cache` und Build-Ausgaben wie `.vite`. Ein verschachteltes `node_modules`, aus dem etwas behalten wird, etwa unter `<app>/realtime`, wird gekürzt statt gelöscht. Links namens `node_modules`, die danach ins Leere zeigen, entfernt der Schritt ebenfalls, etwa `apps/hrms/hrms/public/node_modules`, auf den `sites/assets/hrms` verweist.

Der Schritt bricht den Build ab, statt ein unvollständiges Image zu bauen, wenn einem behaltenen Paket eine reguläre Abhängigkeit fehlt oder ein behaltenes Paket danach nicht mehr da ist. Er folgt keinem Link aus der Bench hinaus: Ist eine App oder ihr `node_modules` ein Link, bricht er ab, und das `node_modules` eines behaltenen Pakets bleibt unberührt, wenn eines von beiden ein Link ist. Abhängigkeiten eines Pakets, das selbst ein Link ist (etwa `link:` bei yarn), sucht er vom Link aus, nicht vom Ziel aus wie Node.js; keine der Apps im Image nutzt das.

Was dadurch nicht mehr geht:

- **`bench build` im Container.** Neue Assets brauchen ohnehin ein neues Image, denn auch eine neue App kommt über `apps.json` und einen neuen Build.
- **Bundles von Frappe Studio.** Veröffentlicht man eine App aus Frappe Studio, baut Frappe ihr Bundle mit yarn und vite aus `frappe/studio/frontend`; diese Pakete fehlen, und der Build der Studio-App scheitert mit einem Eintrag im Fehlerprotokoll. Der Lauf nach `bench migrate` baut nur bereits veröffentlichte Studio-Apps neu und meldet Fehler nur.
- **Bibliotheken unter `/assets/<app>/node_modules`, die nirgends wörtlich stehen.** Behalten wird nur, was die Assets oder Quellen einer App als Pfad nennen. Setzt eigener Code den Pfad erst zur Laufzeit zusammen oder steht er nur in der Datenbank, etwa in einem Client Script, einer Web Page oder einem Print Format, antwortet nginx darauf mit 404.

Der Site-Test startet den Socket.IO-Server, lädt jede `realtime/handlers.js` der Apps, ruft über nginx jede Bibliothek ab, die die gebauten Assets unter `node_modules` nennen, und speichert ein eigenes Website Theme.

## Woher das Deutsche kommt

erpnext_germanized übersetzt nichts selbst und ändert keine App. Die deutschen Teile kommen aus Frappe, ERPNext und den Apps:

- **Oberfläche.** Frappe, ERPNext und HRMS bringen ihre deutsche Übersetzung als `locale/de.po` mit. Sie entsteht in der Community über [Crowdin](https://crowdin.com/project/frappe). Die Apps von ALYF haben eigene Dateien `locale/de.po`, Steuerbote `steuerbote/translations/de.csv`. Die Sprache gilt für die ganze Site in den Systemeinstellungen und kann je Benutzer abweichen.
- **Formate.** Wählt man im Einrichtungsassistenten das Land Deutschland, übernimmt Frappe dessen Vorgaben: Datum `dd.mm.yyyy`, Uhrzeit `HH:mm`, Zahlen `#.###,##`, Währung EUR und Zeitzone Europe/Berlin (`frappe/geo/country_info.json`).
- **Kontenrahmen und Steuervorlagen.** ERPNext bringt die Vorlagen „SKR03 mit Kontonummern“ und „SKR04 mit Kontonummern“ mit und legt beim Anlegen einer Firma mit dem Land Deutschland passende Steuervorlagen an, siehe [Apps](apps.md#erpnext).
- **Deutsche Funktionen.** Registerangaben, USt-IdNr.-Prüfung, Summen- und Saldenliste, DATEV, E-Rechnungen, EBICS und ELSTER kommen aus den Apps erpnext_germany, erpnext_datev, eu_einvoice, banking und Steuerbote, siehe [Apps](apps.md).
