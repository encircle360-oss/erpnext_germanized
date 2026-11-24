# erpnext_germanized

ERPNext für deutsche Unternehmen als fertiges Container-Image: Frappe, ERPNext und HRMS mit den deutschen Apps von ALYF und Steuerbote in einem versionierten Image für die GitHub Container Registry.

> **Status: erstes Release, frühes Stadium.** Das Image `ghcr.io/encircle360-oss/erpnext_germanized:16.60.0-13` enthält alle Apps aus der Tabelle unten und besteht den Site-Test der CI. Es ist für Tests und erste Installationen gedacht; Rückmeldungen über Issues, Discussions oder Matrix sind willkommen, siehe [Roadmap](docs/roadmap.md).

Steuermeldungen an ELSTER übernimmt die enthaltene App [Steuerbote](https://github.com/encircle360-oss/steuerbote), zuerst die Umsatzsteuer-Voranmeldung. Steuerbote verweist in seinem README umgekehrt auf dieses Image.

## Was erpnext_germanized ist

- **Ein Image.** Frappe, ERPNext, HRMS, die Apps von ALYF und Steuerbote stecken zusammen in `ghcr.io/encircle360-oss/erpnext_germanized`. Backend, Frontend, Websocket, Worker und Scheduler starten aus demselben Image mit unterschiedlichen Befehlen, wie bei den Images von [frappe_docker](https://github.com/frappe/frappe_docker).
- **Deutsche Apps.** Registerangaben, Prüfung der USt-IdNr., Summen- und Saldenliste, DATEV-Export, E-Rechnungen nach XRechnung und ZUGFeRD, Bankanbindung und die Umsatzsteuer-Voranmeldung kommen als eigene Apps dazu, siehe [Enthaltene Apps](#enthaltene-apps).
- **Versionen aus `apps.json`.** Jede App ist auf ein Release-Tag gepinnt, nie auf einen Branch. `apps.json` ist die einzige Liste der Apps. Das Tag von Frappe steht als Vorgabe von `FRAPPE_BRANCH` im `Containerfile`.
- **Updates durch Tag-Wechsel.** Ein Update ist ein anderes Image-Tag und danach `bench migrate`. Sites, Dateien und Datenbank liegen in Volumes und bleiben erhalten.
- **Site-Test in der CI.** Vor jeder Veröffentlichung installiert die CI alle Apps auf einer frischen Site und prüft, dass das Backend antwortet. Ein Image, das den Test nicht besteht, wird nicht veröffentlicht.
- **SBOM und Provenance.** Zu jedem veröffentlichten Image erzeugt die CI eine Stückliste der enthaltenen Pakete (SBOM) und eine signierte Herkunftsangabe (Build Provenance), die `gh attestation verify` prüft.
- **Nur `linux/amd64`.** Ein Image für `linux/arm64` gibt es noch nicht, siehe [Roadmap](docs/roadmap.md).

## Enthaltene Apps

Frappe ist das Framework unter allen Apps. Die Apps stehen in der Reihenfolge von `apps.json`, in der sie auch installiert werden.

| App | Version | Zweck | Lizenz |
|---|---|---|---|
| [frappe](https://github.com/frappe/frappe) | v16.60.2 | Full-Stack-Webframework mit Python und MariaDB, auf dem ERPNext und alle anderen Apps laufen. | MIT |
| [erpnext](https://github.com/frappe/erpnext) | v16.60.0 | ERP-System mit Buchhaltung, Auftragsabwicklung und Lager, Fertigung, Anlagenverwaltung und Projekten. | GPL-3.0 |
| [hrms](https://github.com/frappe/hrms) | v16.60.0 | Personal und Lohn (Frappe HR) mit Mitarbeiterverwaltung, Urlaub und Anwesenheit, Spesen, Leistungsbeurteilung und Gehaltsabrechnung. | GPL-3.0 |
| [erpnext_germany](https://github.com/alyf-de/erpnext_germany) | v16.2.2 | Deutsche Anpassungen wie Summen- und Saldenliste, Zusammenfassende Meldung, Registerangaben, Prüfung der USt-IdNr., Geschäftsbriefe, Dienstreisen und GDPdU-Export. | GPL-3.0 |
| [erpnext_datev](https://github.com/alyf-de/erpnext_datev) | v16.0.2 | Schickt Belege beim Buchen per E-Mail an DATEV Unternehmen Online und exportiert Buchungen im DATEV-CSV-Format. | GPL-3.0 |
| [eu_einvoice](https://github.com/alyf-de/eu_einvoice) | v16.4.0 | Erstellt und liest E-Rechnungen im Format UN/CEFACT CII in den Profilen BASIC, EN 16931, EXTENDED und XRECHNUNG, außer bei XRECHNUNG auch eingebettet in ein PDF (ZUGFeRD, Factur-X). | GPL-3.0-or-later |
| [erpnext_pdf-on-submit](https://github.com/alyf-de/erpnext_pdf-on-submit) | v16.3.1 | Erzeugt beim Buchen eines Belegs ein PDF und hängt es an den Beleg. | GPL-3.0-or-later |
| [banking](https://github.com/alyf-de/banking) | v16.7.0 | Holt Bankumsätze per EBICS in ERPNext und gleicht sie mit Belegen ab, wobei EBICS ein Abonnement bei ALYF braucht und der Abgleich nicht. | GPL-3.0 |
| [steuerbote](https://github.com/encircle360-oss/steuerbote) | v0.11.0 | Steuermeldungen aus ERPNext an ELSTER, zuerst die Umsatzsteuer-Voranmeldung, noch in Entwicklung und nicht einsatzfähig. | AGPL-3.0-or-later |

Was jede App mitbringt und wo sie eingerichtet wird, steht in [Apps](docs/apps.md).

## Schnellstart

Du brauchst Docker mit dem Compose-Plugin auf einem Rechner mit `linux/amd64`. Das Beispiel nutzt das Tag `16`, also das neueste Release mit ERPNext 16; für den Dauerbetrieb trägst du unter `x-erpnext` das volle Tag ein, etwa `16.60.0-1`, siehe [Versionen und Updates](#versionen-und-updates).

1. Lege ein Verzeichnis an und hol das Beispiel [examples/compose.yaml](examples/compose.yaml):

   ```bash
   mkdir erpnext && cd erpnext
   curl -fsSLO https://raw.githubusercontent.com/encircle360-oss/erpnext_germanized/main/examples/compose.yaml
   ```

2. Ersetze in `compose.yaml` unter `x-site` beide `CHANGE_ME`: das Root-Passwort der Datenbank und das Passwort des Benutzers Administrator.

3. Starte alle Dienste und sieh dem Anlegen der Site zu:

   ```bash
   docker compose up -d
   docker compose logs -f create-site
   ```

   Der Dienst `create-site` legt beim ersten Start die Site `erp.localhost` an und installiert alle Apps in der Reihenfolge von `apps.json`. Das dauert einige Minuten, danach beendet sich der Dienst.

4. Öffne <http://localhost:8080> und melde dich als `Administrator` mit dem Passwort aus Schritt 2 an.

5. Der Einrichtungsassistent fragt zuerst nach Sprache, Land, Zeitzone und Währung. Wähle die Sprache Deutsch und das Land Deutschland. Der Assistent schlägt dann die Zeitzone Europe/Berlin und die Währung EUR vor und stellt Datum und Zahlen auf `dd.mm.yyyy` und `#.###,##`.

6. Danach legt der Assistent dein Benutzerkonto und die Firma an. Als Kontenplan bietet ERPNext für Deutschland die Vorlagen „SKR03 mit Kontonummern“ und „SKR04 mit Kontonummern“ an. Welcher Kontenrahmen passt, klärst du mit deiner Steuerberatung.

Sprache und Land lassen sich später in den Systemeinstellungen ändern, die Sprache zusätzlich für jeden Benutzer. Was für den Dauerbetrieb dazukommt, also Reverse Proxy, Sicherungen und Updates, steht in [Betrieb](docs/betrieb.md).

## Versionen und Updates

Die Image-Tags entstehen aus Git-Tags der Form `v<ERPNext-Version>-<Revision>`, etwa `v16.60.0-1`:

| Image-Tag | Zeigt auf |
|---|---|
| `16.60.0-1` | genau dieses Release |
| `16.60.0` | die neueste Revision zu ERPNext 16.60.0 |
| `16` | das neueste Release mit ERPNext 16 |
| `latest` | das neueste Release, auch über eine neue Hauptversion hinweg |
| `main`, `main-<sha7>` | Builds des Branches `main`, kein Release |

- **Pinne das volle Tag**, etwa `16.60.0-1`, oder den Digest. Bewegliche Tags wie `16` oder `latest` bringen beim nächsten Pull neue App-Versionen, ohne dass jemand `bench migrate` ausführt.
- **Ein Update ist ein Tag-Wechsel.** Sicherung anlegen, neues Tag eintragen, Container neu erzeugen und `bench --site <site> migrate` ausführen. Die Schritte stehen in [Betrieb](docs/betrieb.md#updates).
- **Die Revision** zählt die Releases zu einer ERPNext-Version. Eine neue Revision bringt etwa neue Versionen der anderen Apps, ein neues Frappe oder ein neues Basis-Image. Die Release-Notes nennen alle Versionen.
- **Zurück** geht es nur mit der Sicherung von vor dem Update, denn `bench migrate` ändert die Datenbank.

Schema, Release-Prozess und die Bedeutung der beweglichen Tags beschreibt [Versionierung](docs/versionierung.md).

## Eigenes Image

Wer andere Apps oder Versionen braucht, baut das Image selbst. Dafür braucht es Docker mit Buildx und Python 3.14.

1. Repository forken und klonen.
2. `apps.json` anpassen: Apps hinzufügen, entfernen oder andere Tags eintragen. `python3 -m germanized validate` prüft die Datei.
3. Bauen und testen:

   ```bash
   ./build.sh                                     # builds erpnext_germanized:local
   ./tests/site/run.sh erpnext_germanized:local   # installs every app on a test site
   ```

4. Nach `docker login` in die eigene Registry schieben:

   ```bash
   ./build.sh --tag registry.example.com/erp/erpnext_germanized:16.60.0-1 --push
   ```

Was beim Hinzufügen oder Entfernen einer App sonst zu tun ist, steht in [Entwicklung](docs/entwicklung.md#eine-app-hinzufügen-oder-entfernen).

## Dokumentation

- [Architektur](docs/architektur.md): Stufen des Containerfile, `apps.json` als Build-Secret, Inhalt des Images, Herkunft der deutschen Teile
- [Betrieb](docs/betrieb.md): docker compose, Kubernetes, Volumes, Sicherungen, Updates, Scheduler und Worker, Reverse Proxy
- [Versionierung](docs/versionierung.md): Tags, Revisionen, Release-Prozess, Pinnen
- [Apps](docs/apps.md): jede App mit Zweck, Lizenz, deutschen Besonderheiten und Einrichtung
- [Entwicklung](docs/entwicklung.md): Aufbau, Werkzeuge, Tests, CI, lokaler Build, Apps hinzufügen und entfernen
- [Roadmap](docs/roadmap.md): Stand und nächste Schritte
- [Idee: Verfahrensdokumentation](docs/ideen/verfahrensdokumentation.md): eine GoBD-Verfahrensdokumentation aus den Einstellungen und Protokollen der Site erzeugen; Recherche und Ausbauplan, noch nicht umgesetzt
- [Changelog](CHANGELOG.md), [Mitwirken](CONTRIBUTING.md), [Hinweise für Coding-Agenten](AGENTS.md), [Sicherheit](SECURITY.md)

## Mitwirken und Community

### Beiträge sind willkommen

erpnext_germanized lebt davon, dass Menschen das Image in ihren Firmen, Branchen und Umgebungen betreiben und zurückmelden, was fehlt. Du kannst

- **Maintainer werden**, für einen Bereich (etwa den Betrieb auf Kubernetes oder eine App) oder das ganze Projekt,
- **Apps vorschlagen**, die deutsche Unternehmen brauchen,
- **den Betrieb testen**, mit docker compose, Kubernetes oder deiner eigenen Umgebung,
- **Pull Requests** für Fehlerbehebungen, Werkzeuge und Dokumentation stellen,
- **Dokumentation und Beispiele** verbessern,
- **Fehler melden** oder Funktionen vorschlagen.

Jeder Beitrag zählt. Du musst kein ERPNext-Profi sein, wir helfen beim Einstieg.

### So geht es

1. Repository forken und einen Branch anlegen
2. Änderung samt Tests schreiben (Test zuerst, siehe [Mitwirken](CONTRIBUTING.md))
3. Lokal prüfen: `pre-commit run --all-files` und `pytest`, bei Änderungen am Image zusätzlich `./build.sh` und `./tests/site/run.sh erpnext_germanized:local`
4. Pull Request mit kurzer Beschreibung und Quelle stellen, etwa den Release-Notes einer App
5. Review gemeinsam durchgehen, bis es passt

### Maintainer werden

Wer dauerhaft Verantwortung übernehmen möchte, zeigt das am einfachsten durch Pull Requests und Hilfe in Issues und Discussions und schreibt dann an **oss@encircle360.com**. Ein Bereich reicht, es muss nicht das ganze Projekt sein.

## Support und professionelle Dienstleistungen

### Community-Support

- **Matrix:** [#oss:encircle360.com](https://matrix.to/#/#oss:encircle360.com) für den direkten Austausch mit Maintainern und Nutzern
- **Issues:** [Fehler und Wünsche zu erpnext_germanized](https://github.com/encircle360-oss/erpnext_germanized/issues)
- **Discussions:** [Fragen und Austausch](https://github.com/encircle360-oss/erpnext_germanized/discussions)
- **Fehler in Frappe, ERPNext oder einer der Apps** bitte beim jeweiligen Projekt melden: [frappe/frappe](https://github.com/frappe/frappe/issues), [frappe/erpnext](https://github.com/frappe/erpnext/issues), [frappe/hrms](https://github.com/frappe/hrms/issues), [alyf-de/erpnext_germany](https://github.com/alyf-de/erpnext_germany/issues), [alyf-de/erpnext_datev](https://github.com/alyf-de/erpnext_datev/issues), [alyf-de/eu_einvoice](https://github.com/alyf-de/eu_einvoice/issues), [alyf-de/erpnext_pdf-on-submit](https://github.com/alyf-de/erpnext_pdf-on-submit/issues), [alyf-de/banking](https://github.com/alyf-de/banking/issues), [encircle360-oss/steuerbote](https://github.com/encircle360-oss/steuerbote/issues). Fehler im Image, im Beispiel und in den Werkzeugen gehören in die Issues dieses Repositories.

### Professioneller Support

Für Einführung, Betrieb, Updates, Anpassungen oder Schulung rund um ERPNext und dieses Image: **hello@encircle360.com**

## Haftungsausschluss

erpnext_germanized wird „wie besehen“ („AS IS“) und ohne jede Gewährleistung bereitgestellt, weder ausdrücklich noch stillschweigend, einschließlich, aber nicht beschränkt auf die Gewährleistung der Marktgängigkeit, der Eignung für einen bestimmten Zweck und der Nichtverletzung von Rechten Dritter. Das gilt für das Image ebenso wie für Rezept, Werkzeuge und Beispiele.

erpnext_germanized ist Software, keine Steuer- oder Rechtsberatung. Mit der Nutzung erkennst du an:

- Du nutzt Image und Rezept auf eigenes Risiko. Für Betrieb, Sicherungen, Updates und die Sicherheit deiner Installation bist du selbst verantwortlich.
- Die Buchhaltungs- und Steuerfunktionen kommen aus den enthaltenen Apps. Für sie gelten die Hinweise und Haftungsausschlüsse der jeweiligen Projekte, für Steuerbote etwa dessen [Haftungsausschluss](https://github.com/encircle360-oss/steuerbote#haftungsausschluss).
- Ein grüner Site-Test zeigt, dass sich alle Apps installieren lassen und das Backend antwortet. Er zeigt nicht, dass jede Funktion richtig rechnet. Lass Kontenrahmen, Steuereinstellungen und Abläufe von deiner Steuerberatung prüfen.
- Die Maintainer, die encircle360 GmbH und alle Mitwirkenden haften nicht für Schäden oder Verluste jeder Art, die aus der Nutzung oder der Unmöglichkeit der Nutzung entstehen, insbesondere nicht für Datenverlust, Ausfallzeiten, Steuernachzahlungen, Zinsen, Verspätungs- oder Säumniszuschläge, Bußgelder oder die Kosten einer Nachbearbeitung. Das gilt, soweit ein Haftungsausschluss gesetzlich zulässig ist.
- erpnext_germanized ist weder ein Angebot der Frappe Technologies Pvt. Ltd. noch der ALYF GmbH. ERPNext ist eine Marke der Frappe Technologies Pvt. Ltd., DATEV eine Marke der DATEV eG. erpnext_germanized steht mit keinem davon in Verbindung.

Für den Einsatz mit zugesichertem Support und Reaktionszeiten sprich uns an: **hello@encircle360.com**

## Lizenz

Dieses Repository steht unter der [Apache License 2.0](LICENSE) (Apache-2.0). Das `Containerfile` basiert auf `images/custom/Containerfile` aus [frappe_docker](https://github.com/frappe/frappe_docker) v4.2.0 und steht wie das Original unter der MIT-Lizenz (Copyright Frappe Technologies Pvt. Ltd.). Ihr Text liegt in [LICENSES/frappe_docker.MIT.txt](LICENSES/frappe_docker.MIT.txt).

Das Image enthält Software unter eigenen Lizenzen. Frappe steht unter MIT, ERPNext und HRMS unter GPL-3.0, die Apps von ALYF unter GPL-3.0 oder GPL-3.0-or-later und Steuerbote unter AGPL-3.0-or-later, wie es die Tabelle unter [Enthaltene Apps](#enthaltene-apps) für jede App nennt. Dazu kommen die Python- und Node-Pakete der Apps und die Debian-Pakete des Basis-Images, jeweils unter ihrer eigenen Lizenz. Die SBOM eines Images listet diese Pakete auf. Den Quelltext von Frappe und jeder App gibt es öffentlich auf GitHub, jeweils zum gepinnten Tag.

Eine Ausnahme ist das Python-Paket [fintech](https://www.joonis.de/fintech/), das die App banking voraussetzt. Es steht unter keiner Open-Source-Lizenz, PyPI führt es als „Free To Use But Restricted“. Für EBICS erwirbt ALYF mit dem Abonnement eine Lizenz dafür, siehe die [EBICS-Dokumentation von banking](https://github.com/alyf-de/banking/blob/v16.6.4/banking/docs/en/banking/ebics-integration.md).

Das Label `org.opencontainers.image.licenses` des Images verbindet als SPDX-Ausdruck die Lizenz des Rezepts mit denen der Apps im Image: `Apache-2.0 AND MIT AND GPL-3.0-only AND GPL-3.0-or-later AND AGPL-3.0-or-later`. Das Rezept selbst bleibt unter Apache-2.0, das `Containerfile` unter MIT. Die Python-, Node- und Debian-Pakete darunter behalten ihre eigenen Lizenzen, siehe oben.

## Maintainer

erpnext_germanized wird von der **[encircle360 GmbH](https://encircle360.com)** entwickelt und gepflegt.

## Credits

Danke an alle, auf deren Arbeit dieses Image aufsetzt:

- [frappe_docker](https://github.com/frappe/frappe_docker) für das Rezept des Images,
- die Frappe Technologies Pvt. Ltd. für [Frappe](https://github.com/frappe/frappe), [ERPNext](https://github.com/frappe/erpnext) und [HRMS](https://github.com/frappe/hrms),
- die [ALYF GmbH](https://github.com/alyf-de) für ihre Apps für Deutschland,
- die ERPNext-Community. Die deutsche Übersetzung von Frappe, ERPNext und HRMS entsteht dort über [Crowdin](https://crowdin.com/project/frappe), nicht in diesem Repository.

Alle Mitwirkenden stehen in der [Contributors-Liste](https://github.com/encircle360-oss/erpnext_germanized/graphs/contributors).
