# Changelog

Alle nennenswerten Änderungen an erpnext_germanized stehen in dieser Datei. Das Format folgt [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), die Versionen dem Schema `v<ERPNext-Version>-<Revision>` aus [Versionierung](docs/versionierung.md). Ein Release bekommt einen Abschnitt `## [16.60.0-1] - JJJJ-MM-TT`; der Workflow Release übernimmt ihn in die Release-Notes.

## Unveröffentlicht

### Hinzugefügt

- Image für `linux/arm64`. Neue Tags nennen einen Index mit einem Image für `linux/amd64` und einem für `linux/arm64`, und Docker wählt das passende; die Tags bis 16.60.0-12 bleiben Images nur für `linux/amd64`. Die CI baut jede Plattform nativ, `linux/arm64` auf `ubuntu-26.04-arm`, und lässt den Site-Test und den Scan auf jeder laufen; veröffentlicht wird erst, wenn beide bestanden haben, und ein Schritt prüft, dass der Index genau die getesteten Images nennt. Die Herkunftsangabe gilt dem Index, jedes Release bekommt eine SBOM je Plattform. ERiC für Steuerbote gibt es nur für Linux x86_64: Prüfen, Testsenden und Senden über ERiC gehen weiter nur mit `linux/amd64`, die Abgabe als XML-Datei über Mein ELSTER braucht ERiC nicht.
- Der Site-Test erzeugt je ein PDF mit wkhtmltopdf und mit Chromium, dem vorgegebenen Generator von Frappe 16, und setzt dafür `chromium_path` wie das Beispiel für docker compose. Bisher erzeugte er kein PDF, und wkhtmltopdf und Chromium sind auf jeder Plattform eigene Programme.

### Geändert

- `examples/compose.yaml` legt keine Plattform mehr fest, Docker wählt das Image passend zum Rechner. Wer ERiC nutzt, betreibt alle Dienste aus dem Image auf `linux/amd64`, in einem Kubernetes-Cluster mit Knoten beider Plattformen per `kubernetes.io/arch: amd64` im `nodeSelector`, siehe [Apps](docs/apps.md#steuerbote).
- Die CI baut das Image je Plattform nur noch einmal und schiebt es im selben Build per Digest ohne Tag in die Registry; die Tags bekommt der Digest erst nach dem Site-Test und einer Prüfung, dass er das getestete Image ist. Bisher baute der Push ein zweites Mal und konnte dabei Schichten eines gleichzeitigen Release-Laufs aus dem gemeinsamen Cache nehmen; die Prüfung schlug dann erst fehl, als die Tags schon gesetzt waren.
- Das Image enthält nur noch die Node.js-Pakete, die nach dem Build geladen werden: Socket.IO mit seinen Abhängigkeiten, die Bibliotheken, die der Browser aus `/assets/<app>/node_modules` lädt, und was das Speichern eines Website Themes braucht (`sass` und die Pakete, die das SCSS der Apps einbindet, etwa Bootstrap). Die `node_modules` der Oberflächen in den Apps und die Build-Werkzeuge in `node_modules` der Apps fallen weg, rund 2,7 GB, und mit ihnen die Schwachstellen, die Scanner darin melden. `bench build` im Container und Bundles von Frappe Studio gehen damit nicht mehr, siehe [Architektur](docs/architektur.md#nodejs-pakete-nach-dem-build).
- Der Site-Test startet den Socket.IO-Server, lädt die Realtime-Handler der Apps, prüft, dass nginx die Bibliotheken aus `node_modules` ausliefert, und speichert ein eigenes Website Theme.

## [16.60.0-12] - 2026-11-24

### Geändert

- Steuerbote v0.10.0: HGB-Taxonomie 6.10 neben 6.9 (Einrichtung beider Pakete, E-Bilanz je Wirtschaftsjahr, Regeln und Arelle-Prüfung, Vorgaben der Bilanzzuordnung für 6.10, „Auf neue Taxonomie heben“, Kontennachweis nach 6.10).

## [16.60.0-11] - 2026-11-24

### Geändert

- Steuerbote v0.9.0: Zusammenspiel der Jahresmeldungen (E-Bilanz speist Anlage GK Zeile 11 und KSt 1 F Zeilen 17/18 der Körperschaftsteuererklärung, Vergleich von E-Bilanz und festgestelltem Jahresabschluss, Umsatzhinweis der Umsatzsteuererklärung, durchgehend getesteter Jahreslauf), Wirtschaftsjahre des eigenen Unternehmens bevorzugt, Dokumentation und Sicherheitshinweise auf dem Stand aller Belege.

## [16.60.0-10] - 2026-11-24

### Geändert

- Steuerbote v0.8.0: Belege „E-Bilanz“ (Positionen der Taxonomie 6.9, Kontennachweis, Anlagenspiegel, Überleitung, XBRL, Übermittlung als Simulation) und „Jahresabschluss“ (Größenklasse, Feststellung, Vorschau der Offenlegung, XBRL für das Unternehmensregister); Vorgaben der Bilanzzuordnung für SKR03 und SKR04; Seitenleiste in Gruppen mit Icons und Arbeitsbereich mit allen Jahresmeldungen; Jahrgang 2027 für Voranmeldung und USt 1 H (vorläufig); Plattformprüfung der ERiC-Einrichtung; Dokumentation.

## [16.60.0-9] - 2026-11-23

### Geändert

- Steuerbote v0.7.0: Belege „Körperschaftsteuererklärung“ und „Gewerbesteuererklärung“ (vorläufig aus den Jahresdokumentationen 2025) mit Rückstellungsvorschlag und Kontennachweis; „Bilanzzuordnung“ je Unternehmen für E-Bilanz und Offenlegung mit Salden aus dem Hauptbuch; Kern der E-Bilanz mit Instanz, Nutzdaten und Simulation; XBRL-Datei der Offenlegung für das Unternehmensregister mit geführtem Upload; Leser der Jahresdokumentationen und Jahresprüfung aller Datenarten.

## [16.60.0-8] - 2026-11-23

### Geändert

- Steuerbote v0.6.0: Seite „Steuerbote einrichten“ mit Vorgaben, „Vorgaben aktualisieren“ und Export/Import der Kontenzuordnung; Jahresmeldungen mit „Einstellungen Jahresmeldungen“, dem Beleg „Umsatzsteuererklärung“ (USt 2 A 2026) samt Druckformat und Übermittlung als Simulation, der Kontenzuordnung Ertragsteuern mit Vorgaben für SKR03 und SKR04 und den Fristen der Jahresmeldungen in „Offene Fristen“; Rechenkerne für Körperschaftsteuer, Gewerbesteuer, Jahresabschluss nach HGB und XBRL mit Taxonomie 6.9; ERiC-Datenarten für Erklärungen und Bilanz, Versionsprüfung mit den Bibliotheksversionen aus den öffentlichen Versionsinformationen.

## [16.60.0-7] - 2026-11-23

### Geändert

- Steuerbote v0.5.0: „Steuervorlagen prüfen“ in der Kontenzuordnung, Abgleich der Voranmeldung mit Sales Register und Purchase Register (Abweichungen brauchen eine Erklärung vor der Abgabe), „USt-IdNrn. prüfen“ und Hinweise zu ungeprüften, veralteten und ungültigen Nummern an der Voranmeldung, wöchentliche Prüfung der ERiC-Laufzeiten gegen die öffentliche Mindestversionsliste von ELSTER mit Benachrichtigung der System Manager, gesperrte Entwürfe ohne Berechnen und Verwerfen; Steuerbote unterstützt die Jahre ab 2026.

## [16.60.0-6] - 2026-11-21

### Geändert

- Steuerbote v0.4.0: Zusammenfassende Meldung über ERiC (Datenart ZMDO, Teilnehmernummer in den Einstellungen, Laufzeitprüfung mit Plugin-Check), beobachtete Konten mit Stufe „Hinweis“, zwei Runden der Sicherheitsprüfung (Speichern über die API ändert keine berechneten Werte mehr, Dateischutz für Übermittlungen und USt-IdNr.-Nachweise, Zertifikat und PIN an Benutzer und Beleg gebunden, ERiC-Worker in privatem Verzeichnis) und ihre Reste, 28 Browsertests in der CI. Für Betreiber: Pfad und SHA-256 des ERiC-Archivs stehen jetzt in der `common_site_config.json` der Bench (`bench set-config -g steuerbote_eric_archive …`, `steuerbote_eric_archive_sha256 …`), nicht mehr in den ERiC-Einstellungen; Steuerbote verlangt Frappe ab 16.54.0, das Image hat v16.60.2.

### Hinzugefügt

- Ideen-Dokument [Verfahrensdokumentation](docs/ideen/verfahrensdokumentation.md): Recherche, Zielbild und Ausbauplan für eine App, die die GoBD-Verfahrensdokumentation aus einer Site erzeugt; noch nicht umgesetzt.

## [16.60.0-5] - 2026-11-21

### Geändert

- Steuerbote v0.3.0: Dauerfristverlängerung über ERiC, ZM-XML für ERiC, Fristenkalender mit Erinnerungen, Jahrgänge als Daten, Kz 70, Datenlieferant aus dem Unternehmen, Proxy für ERiC, Standard-Druckformate.

## [16.60.0-4] - 2026-11-21

### Geändert

- Steuerbote v0.2.0: Zusammenfassende Meldung mit CSV für Mein ELSTER und USt-IdNr.-Prüfung beim BZSt, Dauerfristverlängerung als Beleg.

## [16.60.0-3] - 2026-11-20

### Geändert

- Steuerbote v0.1.3: „Steuern“ steht in der Leiste von ERPNext hinter Rechnungswesen, mit eigenem Logo und Eintrag für den App-Umschalter.

## [16.60.0-2] - 2026-11-18

### Geändert

- Steuerbote v0.1.2: stornierte Belege erscheinen im Bericht „UStVA Kennzahlen“ mit „Storniert“ statt eines Drucklinks, Hinweise enden nach Namen mit Punkt mit genau einem Punkt.
- `python -m germanized` startet auch mit Python 3.12 und 3.13, weil `tags.py` seine Annotationen verzögert auswertet; unterstützt bleibt Python 3.14.
- Das erste `FROM` pinnt das Basis-Image `python:3.14-slim-trixie` zusätzlich per Digest, damit Dependabot auch neue Builds desselben Tags vorschlägt.
- Das Label `org.opencontainers.image.licenses` verbindet als SPDX-Ausdruck die Lizenz des Rezepts mit denen der Apps im Image, `Apache-2.0 AND MIT AND GPL-3.0-only AND GPL-3.0-or-later AND AGPL-3.0-or-later`; das Rezept selbst bleibt unter Apache-2.0.
- Ein Image veröffentlichen nur noch Pushes auf `main` und von Release-Tags, im Job „Build, test and publish“ des Workflows Image. Pull Requests, Läufe von Hand und Forks bauen und testen im Job „Build and test“, dessen Token nur den Scan hochladen darf; beide Jobs teilen die Composite Action `.github/actions/build-and-test`.
- Bewegliche Tags gehen nur vorwärts: Eine spätere Revision einer älteren ERPNext-Version bekommt ihr volles Tag und das Tag ihrer ERPNext-Version, nimmt aber `16` und `latest` keinem neueren Release weg.
- Dependabot aktualisiert auch die Actions der Composite Action und die Hooks von pre-commit, diese im selben Pull Request wie `requirements-dev.txt`; ein Test hält ruff und zizmor an beiden Stellen auf derselben Version.
- Dokumentation nach einem Review berichtigt: Das Beispiel für das Helm-Chart von Frappe setzt Storage Class und Datenbank und ist gegen das Chart 8.0.93 geprüft, dazu Hinweise auf `chromium_path` und darauf, dass `jobs.migrate` den Wartungsmodus auch nach einem Fehler ausschaltet. Die Apps nennen die Oberfläche wie die deutsche Übersetzung der gepinnten Versionen, etwa „Spesenabrechnung“ und „Anhänge anfügen“, und banking v16.6.4 erstellt SEPA-Zahlungsaufträge nur als XML-Datei. Steuerbote veröffentlicht Releases, die der Workflow App versions vorschlägt, und die Version von Frappe steht nur noch in `FRAPPE_BRANCH` und im README. Berichtigt sind außerdem Rundungsmethoden, Dienstreise-Regionen, PDF-Generatoren, der Scan der Konfiguration mit trivy und die Queue der Prüfung der USt-IdNr.

## [16.60.0-1] - 2026-11-18

### Hinzugefügt

- Erste Distribution: ein Image mit Frappe v16.60.2, ERPNext v16.60.0, HRMS v16.60.0, erpnext_germany v16.2.2, erpnext_datev v16.0.2, eu_einvoice v16.4.0, erpnext_pdf-on-submit v16.3.1, banking v16.6.4 und Steuerbote v0.1.1, in dieser Reihenfolge installiert.
- Rezept aus `images/custom/Containerfile` von frappe_docker v4.2.0 auf Python 3.14 und Debian trixie, mit Node.js 24, wkhtmltopdf 0.12.6.1-3, Chromium und zusätzlich Ghostscript für die PDF/A-3-Rechnungen von eu_einvoice.
- `apps.json` als einzige Liste der Apps, jede auf ein Release-Tag gepinnt.
- `build.sh` für den lokalen Build mit denselben Eingaben wie in der CI.
- Werkzeuge `python -m germanized`: `validate`, `tags`, `release-check`, `summary`, `check-versions`, `bump` und `readme`, mit 100 % Testabdeckung.
- Site-Test `tests/site/run.sh`, der alle Apps auf einer frischen Site installiert und Backend und nginx prüft.
- CI mit den Workflows Tests, Linters, Security, Image, Release und App versions. Pushes auf `main` veröffentlichen die Image-Tags `main` und `main-<sha7>`, ein Release-Tag wie `v16.60.0-1` die Tags `16.60.0-1`, `16.60.0`, `16` und `latest`.
- Beispiel für docker compose in `examples/compose.yaml`.
- Dokumentation zu Architektur, Betrieb, Versionierung, Apps, Entwicklung und Roadmap, dazu Regeln für Beiträge, Coding-Agenten und Sicherheit sowie Vorlagen für Issues und Pull Requests.
