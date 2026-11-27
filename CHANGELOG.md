# Changelog

Alle nennenswerten Änderungen an erpnext_germanized stehen in dieser Datei. Das Format folgt [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), die Versionen dem Schema `v<ERPNext-Version>-<Revision>` aus [Versionierung](docs/versionierung.md). Ein Release bekommt einen Abschnitt `## [16.60.0-1] - JJJJ-MM-TT`; der Workflow Release übernimmt ihn in die Release-Notes.

## Unveröffentlicht

### Behoben

- Dokumentation: [Betrieb](docs/betrieb.md#updates) sagt, dass `bench install-app` eine neue App aus dem Image nur nimmt, wenn sie in `sites/apps.txt` im Volume `sites` steht, wer die Datei schreibt und was zu tun ist, wo der Job `jobs.configure` des Helm-Charts abgeschaltet ist. Das betrifft Sites, die Insights oder CRM nach dem Update auf 16.61.0-7 installieren.

## [16.61.0-7] - 2026-11-27

### Hinzugefügt

- [Insights v3.51.0](https://github.com/frappe/insights/releases/tag/v3.51.0), neu im Image: Auswertungen (Business Intelligence) mit Abfragen ohne SQL, Diagrammen und Dashboards, Lizenz AGPL-3.0 laut der Lizenzdatei des Projekts. ERPNext und HRMS bringen für ihre Module Arbeitsmappen für Insights mit, die Insights importiert, und das Feld „Dashboards“ der Systemeinstellungen (vorgegeben Insights) öffnet die Standard-Dashboards dann in ihrer Fassung für Insights; ohne Insights öffnen sie klassisch. Insights hat eine eigene Versionsreihe und steht in `INDEPENDENTLY_VERSIONED`, so dass `bump` es innerhalb der Hauptversion 3 anhebt. Neue Sites bekommen es mit `--install-app insights` aus dem Beispiel, bestehende Sites mit `bench --site <site> install-app insights` nach dem Update. Insights legt Python-Pakete fest, die auch andere Apps nutzen, darunter `sqlglot~=30.22.0`; das Image hat damit sqlglot aus der Reihe 30.22 statt der neuesten Version, die Frappe über sql_metadata zulässt. Einzelheiten in [Apps](docs/apps.md#insights).
- [Frappe CRM v16.5.0](https://github.com/frappe/crm/releases/tag/v16.5.0), neu im Image und optional: ein CRM für Vertriebsteams mit Leads, Deals, Kanban-Ansicht und Telefonie über Twilio und Exotel, Lizenz AGPL-3.0. Die Beispiele installieren CRM nicht; wer es will, ergänzt `--install-app crm` oder installiert es mit `bench --site <site> install-app crm`. CRM ersetzt auf der ganzen Site die Klassen von Kontakt und E-Mail-Vorlage und bringt den Client für Twilio mit. Entfernen mit `bench --site <site> uninstall-app crm` löscht seine Daten. Einzelheiten in [Apps](docs/apps.md#crm).
- Der Site-Test installiert alle Apps des Images, auch CRM, und prüft mit `pip check`, dass sich die Python-Pakete des Images vertragen; die Version von sqlglot steht im Log. Mit Insights prüft er, dass jede Arbeitsmappe, die eine App mitbringt, auf der Site steht und dass nginx die Inseln von Insights für Desk ausliefert.

### Geändert

- Das Label `org.opencontainers.image.licenses` nennt zusätzlich `AGPL-3.0-only` für Insights und CRM.
- [HRMS v16.60.1](https://github.com/frappe/hrms/releases/tag/v16.60.1): Korrekturen, unter anderem am nicht abgerechneten Betrag einer Spesenabrechnung gegen einen Vorschuss, an der Übernahme von Zeiterfassungen bei Schichten und an E-Mails stornierter Gehaltsabrechnungen in der Warteschlange.

## [16.61.0-6] - 2026-11-26

### Geändert

- [Briefbote v0.3.1](https://github.com/encircle360-oss/briefbote/releases/tag/v0.3.1): Die beiden Falzmarken und die Lochmarke stehen auf jeder Seite eines Ausdrucks statt nur auf der ersten, auch auf Folgeseiten einer Positionstabelle, den Seiten eines Leistungsnachweises und den Folgeseiten eines Geschäftsbriefs, mit beiden PDF-Generatoren. Seitenzahlen und die Lage der Wörter ändern sich nicht. Ist „Falz- und Lochmarken drucken“ aus, trägt keine Seite Marken. Nach dem Update genügt `bench migrate`.

### Behoben

- Dependabot schlägt für den Hook shellcheck nicht mehr `v0.11.0.1` vor: Der Tag ist älter als das gepinnte `v0.11.0.1-1`, dessen Zusatz Dependabot als Vorabversion liest. Die Konfiguration nimmt genau diese Version aus; spätere Versionen kommen weiter als Vorschlag.

## [16.61.0-5] - 2026-11-26

> **Warnung: Die Umsatzsteuer einer Anzahlung steht in ERPNext doppelt in den Büchern.** Das betrifft jede Site mit ERPNext 16.61, auch ohne Briefbote: Ein Zahlungseingang mit „Advance Taxes and Charges“ bucht die Umsatzsteuer der Anzahlung beim Eingang, die Ausgangsrechnung über die ganze Leistung bucht sie noch einmal, und das Zuordnen der Anzahlung bucht am Steuerkonto nichts um. Bis eine Korrektur gebucht ist, steht die Steuer der Anzahlung zweimal im Hauptbuch, und eine Umsatzsteuer-Voranmeldung aus dem Hauptbuch zählt sie doppelt. Wie zu korrigieren ist, klärt die Steuerberatung. Gefunden und beschrieben hat das Briefbote, siehe [Anzahlungsrechnung](https://github.com/encircle360-oss/briefbote/blob/v0.3.0/docs/anzahlungsrechnung.md).

### Geändert

- [Briefbote v0.3.0](https://github.com/encircle360-oss/briefbote/releases/tag/v0.3.0): sieben neue Druckformate, „Geschäftsbrief“ für den Business Letter von erpnext_germany, „Anzahlungsrechnung“ und „Proforma-Rechnung“ aus der Proforma-Rechnung von ERPNext 16, „Zahlungsavis“ für einen Zahlungsausgang an einen Lieferanten, „Anfrage“, „Lieferantenrücksendung“ und „Packliste“, dazu die Schlussrechnung, die „Rechnung“ druckt, wenn eine Ausgangsrechnung Anzahlungen zuordnet; damit siebzehn Formate. Das Format „Geschäftsbrief“ und seine Einträge im Menü legt Briefbote nur an, wo erpnext_germany installiert ist, im Image also immer. Briefbote sagt gleiche Seitenzahlen mit beiden Generatoren nicht mehr zu: Mit wkhtmltopdf kann eine lange Tabelle eine Seite mehr brauchen als mit Chromium, der Referenz für das Druckbild. Briefbote ist Alpha; die rechtlichen Texte und Regeln der Dokumente hat noch keine Steuerberatung und keine Rechtsanwältin geprüft. Nach dem Update gilt die Liste „Nach der Aktualisierung“ der Release-Notes: `bench migrate`, Standard-Druckformate nach Wunsch, vor Anzahlungsrechnungen die Warnung lesen und „Enable Proforma Invoice“ einschalten, einmal „Einstellungen prüfen“. Einrichtung und alle Formate in [Apps](docs/apps.md#briefbote).
- Der Site-Test druckt jedes Druckformat von Briefbote mit beiden Generatoren aus den Fällen seiner Nachweise, auch die neuen, eine Proforma-Rechnung als die Kopie ihres Kundenauftrags, die ERPNext druckt, dazu die Schlussrechnung RE-2026-0401 mit ihrer Anzahlung und den Geschäftsbrief GB-2026-0002 über drei Seiten, und prüft nach dem Anlegen der Site, dass sie das Druckformat „Geschäftsbrief“ und seine Einträge im Menü hat. Gleiche Seitenzahl beider Generatoren verlangt er weiter für jeden gedruckten Fall; Abweichungen stehen mit Namen und genauen Seitenzahlen in `KNOWN_PAGE_DIFFERENCES`.

## [16.61.0-4] - 2026-11-26

### Geändert

- [Briefbote v0.2.1](https://github.com/encircle360-oss/briefbote/releases/tag/v0.2.1): ein neuer Fuß mit bis zu vier Blöcken in gleich breiten Spalten auf fester Lage jeder Seite, die frühere Einstellung „Spalten des Fußes“ ist ausgeblendet und wirkt nicht mehr. Schlusstexte bleiben mit der letzten Position und den Summen zusammen, und beide Generatoren ergeben dieselbe Seitenzahl. Summen von Mahnung, Zahlungsbestätigung und Quittung stehen unter ihren Spalten; ohne gewähltes Bankkonto bitten Rechnung und Mahnung nicht um Überweisung, sondern zeigen einen Befund. Seitenleiste und Arbeitsbereich führen zu allen Belegen, die Einstellungen Geschäftspost haben die Schaltfläche „Einstellungen prüfen“ mit einer neuen Warnung zu Blöcken des Fußes mit mehr als vier Zeilen, und das README zeigt jedes Druckformat als Beispiel. Briefbote bleibt Alpha. Nach dem Update gilt der Abschnitt „Nach der Aktualisierung“ der Release-Notes: `bench migrate` und einmal „Einstellungen prüfen“.
- [Steuerbote v0.15.3](https://github.com/encircle360-oss/steuerbote/releases/tag/v0.15.3): Kunden und Lieferanten stehen überall mit Name und ID, etwa „Muster GmbH (10042)“; die Listen der USt-IdNr.-Bestätigungen haben eine Spalte für den Namen und einen Filter „Partner“, und der Patch `fill_the_party_names_of_confirmations` gibt bestehenden Bestätigungen den Namen ihres Partners. Der Dialog „Vorgaben aktualisieren“ passt wieder in seine Breite. Nach `bench migrate` sind die Schritte der Liste „Nach `bench migrate`“ in den Release-Notes zu erledigen.
- Der Site-Test druckt die acht Rechnungen aus dem Nachweis von Briefbote, deren Ende nahe am Seitenende liegt, direkt mit beiden Generatoren und verlangt gleich viele Seiten.

### Bekannte Grenzen

- Eine dieser Rechnungen, RE-2026-0121 aus dem Nachweis von Briefbote, braucht mit wkhtmltopdf eine Seite mehr als mit Chromium (4 statt 3 Seiten), auf `linux/amd64` wie auf `linux/arm64`; der Nachweis von Briefbote v0.2.1 zeigt dasselbe. Im Nachweis von Briefbote trägt die letzte Seite mit wkhtmltopdf die letzte Position, die Summen und die Zahlungsaufforderung, der Schlusstext steht also nicht allein. Chromium ist der vorgegebene Generator von Frappe 16 und dieses Images. Der Site-Test hält genau diese Seitenzahlen fest und schlägt fehl, sobald sie sich ändern; die Korrektur ist für Briefbote v0.2.2 vorgesehen.

## [16.61.0-3] - 2026-11-25

### Geändert

- [Briefbote v0.2.0](https://github.com/encircle360-oss/briefbote/releases/tag/v0.2.0): sieben neue Druckformate, „Angebot“, „Auftragsbestätigung“, „Lieferschein“, „Mahnung“ (Zahlungserinnerung und Mahnung), „Zahlungsbestätigung“, „Quittung“ und „Bestellung“, im selben Gestaltungssystem nach DIN 5008, als Entwurf mit „ENTWURF“ und storniert mit „STORNIERT“ auf jeder Seite. Die Mahnung prüft je Rechnung, seit wann Verzug besteht, und druckt Verzugszinsen und die Pauschale von 40 Euro nur, wo sie rechtmäßig sind. Neue Tabellen der Einstellungen Geschäftspost für Basiszinssätze und Mahnstufen; ein Patch trägt bei `bench migrate` die Basiszinssätze der Bundesbank ein. Briefbote setzt keine Standard-Druckformate und empfiehlt Mahnarten ohne Zinsen und Gebühr, siehe [Apps](docs/apps.md#briefbote). Briefbote ist Alpha: Die rechtlichen Texte und Regeln von Mahnung, Zahlungsbestätigung und Quittung hat noch keine Steuerberatung und keine Rechtsanwältin geprüft. Bekannte Grenze: Mit Chromium kann der Schlusssatz eines Dokuments allein auf einer letzten Seite stehen, wo wkhtmltopdf ihn noch unter den Summen unterbringt; dann unterscheidet sich die Seitenzahl um eine. Nach dem Update die Liste „Nach der Aktualisierung“ der Release-Notes abarbeiten.
- Steuerbote v0.15.2: Die Vorgaben kennen die Konten der DATEV-Ausgabe „Gültig für 2020“, die die Ausgabe 2026 nicht mehr beschriftet (Bilanzzuordnung Stand 2026.5, Kontenzuordnung Ertragsteuern Stand 2026.4); beide Stände erreichen eine bestehende Zuordnung nur über „Vorgaben aktualisieren“. Der neue Hinweis `KONTO-OHNE-STEUERSATZ` nennt für Skonti und Forderungsverluste ohne Steuersatz die Konten der Steuersätze, und der neue Schritt „Standardkonten des Unternehmens“ in „Steuerbote einrichten“ nennt Rabatt-, Abschreibungs- und Rundungskonten, die eine Meldung anhalten würden; dazu Folgearbeiten an Formularen und Vorschau, ohne Patch. Nach `bench migrate` sind die Schritte der Liste „Nach `bench migrate`“ in den [Release-Notes von Steuerbote v0.15.2](https://github.com/encircle360-oss/steuerbote/releases/tag/v0.15.2) zu erledigen.
- Der Site-Test druckt jedes Druckformat von Briefbote, auch die neuen, mit beiden Generatoren, mit den Belegen aus den Nachweisen von Briefbote für Verkauf, Mahnwesen, Zahlungseingang und Einkauf. Die Ausgangsrechnung im Standard-Druckformat von ERPNext nimmt er jetzt aus dem DocType selbst, weil der Nachweis von Briefbote „Rechnung“ als Standard setzt.

## [16.61.0-2] - 2026-11-25

### Geändert

- Steuerbote v0.15.1: Die Druckformate drucken auch auf älterem Frappe mit Chromium, weil das Stylesheet kein `header-spacing` mehr setzt, und mit beiden Generatoren dieselben Seiten mit Kopf, erster Zeile und Fuß an derselben Stelle; „Drucken“ in der Druckansicht druckt dasselbe PDF wie „PDF“. Die Prüfung der Steuernummer mit ERiC beim Speichern läuft jetzt tatsächlich, Korrekturen aus der Zeit vor 0.15.0 tragen „Grundlage unbekannt“ und halten ihren Beleg an, bis sie bestätigt sind, und Kz 500 zeigt den Wortlaut des Vordrucks. Für Holdings kennzeichnet Steuerbote die Konten der Anteile und hält die Körperschaftsteuererklärung bei Erträgen aus Beteiligungen ohne Kategorie an. Nach `bench migrate` sind die Schritte der Liste „Nach `bench migrate`“ in den [Release-Notes von Steuerbote v0.15.1](https://github.com/encircle360-oss/steuerbote/releases/tag/v0.15.1) zu erledigen.
- Briefbote v0.1.1: „Drucken“ in der Druckansicht druckt dasselbe PDF wie „PDF“. Logos drucken in der eingestellten Höhe als PNG, JPEG und SVG, auch ein SVG ohne Breite und Höhe; eine lange Rücksendeangabe verliert Postleitzahl und Ort nicht mehr. Jede Steuerzeile nennt Satz und Bemessungsgrundlage, auch mit den deutschen Steuervorlagen von ERPNext, und fehlt eine Pflichtangabe, sagt das Dokument oben, was fehlt. Entwürfe tragen „ENTWURF“, stornierte Belege „STORNIERT“, mit Chromium schräg über jeder Seite, mit wkhtmltopdf über der ersten, auch nach der Wandlung in PDF/A; dazu eine rechte Kante für alle Blöcke und eine breitere Spalte der Bezeichnung. Bekannt: Zahlen folgen dem Format der Site, nicht der Sprache des Dokuments, und die Wortlaute der Pflichthinweise warten auf die Prüfung durch eine Steuerberatung ([Release-Notes](https://github.com/encircle360-oss/briefbote/releases/tag/v0.1.1)).
- erpnext_pdf-on-submit v16.4.0: bettet die XML der E-Rechnung in die PDFs aller Belegarten ein, die das unterstützen, und kann das PDF in ein gewähltes Anhangfeld schreiben ([Release-Notes](https://github.com/alyf-de/erpnext_pdf-on-submit/releases/tag/v16.4.0)).
- banking v16.8.0: zeigt EBICS-Registrierungen ohne passenden EBICS-Benutzer und lässt sie entfernen, behebt Skonto-Beträge im Bankabgleich Beta und die Registrierung von EBICS-Benutzern nach Änderungen ([Release-Notes](https://github.com/alyf-de/banking/releases/tag/v16.8.0)).
- Der Site-Test verlangt für jeden Beleg von Briefbote und Steuerbote mit wkhtmltopdf und mit Chromium gleich viele Seiten. Er druckt eine Rechnung von Briefbote als Entwurf mit beiden Generatoren, wandelt sie mit dem Ghostscript des Images so in PDF/A-3, wie eu_einvoice es tut, und prüft, dass „ENTWURF“ danach noch auf den Seiten steht und quer über die Seite gemalt ist.
- [Betrieb](docs/betrieb.md#updates): Nach einem Update, sobald alle Dienste aus dem neuen Image laufen, `bench --site <site> clear-cache`. Während Dienste beider Images laufen, können die Namen der Asset-Bündel im gemeinsamen Cache auf die Dateien des anderen Images zeigen; der PDF-Generator auf Chromium-Basis meldet dann „Attempted Unauthorized File Access in PDF Generator“, und dem PDF fehlt das Druck-Stylesheet von Frappe. In dieser Zeit keine Belege anlegen.

## [16.61.0-1] - 2026-11-25

### Behoben

- PDFs mit Chromium setzen Text ohne Font-Hinting. Bisher rundete `chromium-headless-shell` die Breite jedes Zeichens einer eingebetteten Schrift auf ganze Pixel, und die Buchstaben standen ungleichmäßig weit auseinander: In den Formaten von Briefbote wich der Abstand zweier Ziffern um bis zu 5,11 % von der Breite ab, die die Schrift vorgibt, jetzt um 0,03 %, auf `linux/amd64` wie auf `linux/arm64`. Eine Einstellung in fontconfig wirkt darauf nicht, nur der Schalter `--font-render-hinting=none`, und Frappe nimmt keine eigenen Schalter an. Das Image legt deshalb an den Pfad von Chromium ein Skript, das das Programm mit diesem Schalter startet; `chromium_path` bleibt `/usr/lib/chromium/chromium-headless-shell`, siehe [Architektur](docs/architektur.md#chromium). Seitenzahlen der Formate von Briefbote ändern sich nicht, wkhtmltopdf ist nicht betroffen.
- Die Druckformate von Steuerbote v0.15.0 schlugen mit dem Generator Chromium auf Frappe v16.60.2 mit Fehler 500 fehl; ab dieser Revision drucken sie, weil Frappe v16.61.0 den Fehler behebt.

### Geändert

- Frappe v16.61.0 und ERPNext v16.61.0; HRMS bleibt auf v16.60.0, seinem neuesten Release. Mit der neuen ERPNext-Version beginnt die Revision wieder bei 1. Frappe v16.61.0 behebt unter anderem den Fehler 500 beim Drucken mit Chromium, wenn ein Druckformat `header-spacing` als Text setzt (Commit 26a97a00). Im Wartungsmodus lässt eine Site jetzt Lesen zu und lehnt nur Änderungen ab; `bench --site <site> set-config -p allow_reads_during_maintenance 0` stellt das bisherige Verhalten wieder her, siehe [Betrieb](docs/betrieb.md#updates). Alle Änderungen nennen die Release-Notes von [Frappe](https://github.com/frappe/frappe/releases/tag/v16.61.0) und [ERPNext](https://github.com/frappe/erpnext/releases/tag/v16.61.0).
- Der Site-Test druckt, was Benutzer drucken: Ein angemeldeter Benutzer lädt über nginx eine Ausgangsrechnung im Standard-Druckformat von ERPNext und je einen Beleg jedes Druckformats von Briefbote und Steuerbote als PDF herunter, mit wkhtmltopdf und mit Chromium. In den PDFs von Chromium misst er die Abstände zwischen Ziffern gegen die Breiten der Schrift, erlaubt sind 0,5 %. Bisher druckte er nur Briefbote und hätte weder die ungleichmäßigen Abstände noch den Fehler 500 von Steuerbote gefunden; beides zeigt er auf dem Stand von 16.60.0-16 an, siehe [Entwicklung](docs/entwicklung.md#lokaler-build-und-site-test).

## [16.60.0-16] - 2026-11-25

### Hinzugefügt

- [Briefbote v0.1.0](https://github.com/encircle360-oss/briefbote/releases/tag/v0.1.0), neu im Image: Druckformate für Geschäftsdokumente nach DIN 5008: Rechnung, Rechnungskorrektur, Stornorechnung und kaufmännische Gutschrift aus der Ausgangsrechnung, Gutschrift im Gutschriftsverfahren aus der Eingangsrechnung und Leistungsnachweis, siehe [Apps](docs/apps.md#briefbote). Briefbote kommt in `apps.json` vor Steuerbote; neue Sites bekommen es mit `--install-app briefbote` aus dem Beispiel, bestehende Sites mit `bench --site <site> install-app briefbote` nach dem Update.
- Der Site-Test prüft, dass nginx die Icons und Logos ausliefert, die die Hooks der Apps nennen, und druckt jedes Druckformat von Briefbote mit wkhtmltopdf und mit Chromium; jedes PDF muss den Beleg nennen und seine Schriften einbetten, in der eingebetteten Schrift Inter.
- Die Werkzeuge kennen Forks (`FORKS` in `germanized/apps.py`) mit Tags der Form `v16.2.2-encircle360.5`: `validate` und `release-check` nehmen sie an, `bump` lässt sie stehen, `check-versions` vergleicht sie mit den Releases des Originals, `readme --check` verlangt in ihrer Zeile einen Link auf das Original, und `summary` nennt sie in den Release-Notes. Eine App mit eigenen Versionsnummern darf vor ihrem ersten Release auf einen Branch zeigen; `release-check` lehnt das ab, und `bump` setzt den Branch auf das erste Release.

### Geändert

- Steuerbote v0.15.0: Bestätigung der USt-IdNrn. von Kunden und Lieferanten beim BZSt und über VIES, mit der Prüfung beim Buchen von Ausgangsrechnungen, die nach dem Update sofort aktiv ist (Lieferungen in Kz 41 und 42 ohne gültige Bestätigung vom Tag der Rechnung sperrt sie); die Steuer zu Umsätzen mit festem Steuersatz wahlweise wie gebucht; Verkäufe von Anlagegütern in Kz 81 und 86; ein gemeinsames Stylesheet aller Druckformate; die E-Bilanz mit ERiC 44.3.6.0 geprüft (nur „Prüfen“, nichts gesendet). Nach `bench migrate` sind die Schritte der Liste „Nach `bench migrate`“ in den [Release-Notes von Steuerbote v0.15.0](https://github.com/encircle360-oss/steuerbote/releases/tag/v0.15.0) zu erledigen, darunter „Vorgaben aktualisieren“ in Kontenzuordnung Umsatzsteuer und Bilanzzuordnung.
- Die Labels des Images nennen Hersteller (`vendor`), Autoren (`authors`), Projektseite (`url`) und Dokumentation (`documentation`).
- Das README fasst den Haftungsausschluss kürzer, mit Verweis auf die Abschnitte 7 und 8 der Apache License 2.0, Software Dritter, Betrieb und Datenschutz, nennt die Marken mit einem eigenen Hinweis und verweist unter „Maintainer“ auf encircle360.com.
- erpnext_germany kommt vorübergehend aus dem Fork [encircle360-oss/erpnext_germany](https://github.com/encircle360-oss/erpnext_germany), Tag `v16.2.2-encircle360.5`: v16.2.2 mit der Korrektur aus [alyf-de/erpnext_germany#148](https://github.com/alyf-de/erpnext_germany/pull/148), ohne die der geplante Job der Prüfung der USt-IdNr. nicht mehr vorankommt, sobald ein Kunde oder Lieferant eine USt-IdNr. hat, die sich nicht lesen lässt. Sobald ein Release von erpnext_germany die Korrektur enthält, zeigt `apps.json` wieder auf alyf-de/erpnext_germany. Der Name in bench bleibt `erpnext_germany`; bestehende Sites brauchen nach dem Update wie immer `bench migrate`.

## [16.60.0-15] - 2026-11-25

### Geändert

- Steuerbote v0.14.0: Die Umsatzsteuer-Voranmeldung ordnet Ausgangsrechnungen nach ihrem Leistungsdatum dem Zeitraum zu, ein Patch setzt das als Vorgabe in vorhandenen Einstellungen, und Belege für abgegebene Zeiträume erscheinen in „Nach der Abgabe geändert“; Erwerbe und Leistungen nach § 13b UStG auf Aufwandskonten bekommen ihre Bemessungsgrundlage, § 13b-Leistungen gehen nach dem Sitz des Leistenden in Kz 46 oder Kz 84; Start mit Steuerbote im laufenden Betrieb mit dem neuen Beleg „Voranmeldung vor Steuerbote“. Nach `bench migrate` bekommt die Kontenzuordnung Umsatzsteuer die neuen Spalten über „Vorgaben aktualisieren“.

## [16.60.0-14] - 2026-11-24

### Geändert

- Steuerbote v0.13.0: Tabellen aller Belege zeigen Beträge und ihre Spaltenköpfe vollständig; neue Bilder im README.
- Das Image enthält nur noch die Node.js-Pakete, die nach dem Build geladen werden: Socket.IO mit seinen Abhängigkeiten, die Bibliotheken, die der Browser aus `/assets/<app>/node_modules` lädt, und was das Speichern eines Website Themes braucht (`sass` und die Pakete, die das SCSS der Apps einbindet, etwa Bootstrap). Die `node_modules` der Oberflächen in den Apps und die Build-Werkzeuge in `node_modules` der Apps fallen weg, rund 2,5 GB, und mit ihnen die Schwachstellen, die Scanner darin melden. `bench build` und `bench get-app` im Container und Bundles von Frappe Studio gehen damit nicht mehr; die Seite `/attribution` und die SBOM von Frappe nennen für die entfernten Pakete keine Lizenz mehr, und Bibliotheken, die gebündelt in den Assets stecken, etwa Vue, sieht der Scan des Images nicht mehr, siehe [Architektur](docs/architektur.md#nodejs-pakete-nach-dem-build).
- Der Site-Test startet den Socket.IO-Server, lädt die Realtime-Handler der Apps, prüft, dass nginx die Bibliotheken aus `node_modules` ausliefert und die Verzeichnisse darunter im Image liegen, die die Assets nennen, und speichert ein eigenes Website Theme.
- [Entwicklung](docs/entwicklung.md#ci) nennt, wie lange eine Veröffentlichung je Plattform dauert.

## [16.60.0-13] - 2026-11-24

### Hinzugefügt

- Image für `linux/arm64`. Neue Tags nennen einen Index mit einem Image für `linux/amd64` und einem für `linux/arm64`, und Docker wählt das passende; die Tags bis 16.60.0-12 bleiben Images nur für `linux/amd64`. Die CI baut jede Plattform nativ, `linux/arm64` auf `ubuntu-26.04-arm`, und lässt den Site-Test und den Scan auf jeder laufen; veröffentlicht wird erst, wenn beide bestanden haben, und ein Schritt prüft, dass der Index genau die getesteten Images nennt. Die Herkunftsangabe gilt dem Index, jedes Release bekommt eine SBOM je Plattform. ERiC für Steuerbote gibt es nur für Linux x86_64: Prüfen, Testsenden und Senden über ERiC gehen weiter nur mit `linux/amd64`, die Abgabe als XML-Datei über Mein ELSTER braucht ERiC nicht.
- Der Site-Test erzeugt je ein PDF mit wkhtmltopdf und mit Chromium, dem vorgegebenen Generator von Frappe 16, und setzt dafür `chromium_path` wie das Beispiel für docker compose. Bisher erzeugte er kein PDF, und wkhtmltopdf und Chromium sind auf jeder Plattform eigene Programme.

### Geändert

- Steuerbote v0.12.0: Prüfliste für die Steuerberatung mit 105 Punkten, die vor der ersten echten Abgabe zu klären sind, und was davon heute eine Abgabe anhält; Befund der E-Bilanz, wenn die Bilanzzuordnung eine andere Version der HGB-Taxonomie nennt, mit dem Weg über „Auf neue Taxonomie heben“ oder die Version der Zuordnung; Bilder aller Belege aus den Browsertests im README. Darin auch Steuerbote v0.11.0, das in keinem Release war: Die Einrichtung füllt leere Zuordnungen mit den Vorgaben, „Vorgaben aktualisieren“ vermerkt die Vorgaben nur mit ausdrücklicher Entscheidung als übernommen, Beschreibungen und Dokumentation sind auf dem Stand aller Module.
- `examples/compose.yaml` legt keine Plattform mehr fest, Docker wählt das Image passend zum Rechner. Wer ERiC nutzt, betreibt alle Dienste aus dem Image auf `linux/amd64`, in einem Kubernetes-Cluster mit Knoten beider Plattformen per `kubernetes.io/arch: amd64` im `nodeSelector`, siehe [Apps](docs/apps.md#steuerbote).
- Die CI baut das Image je Plattform nur noch einmal und schiebt es im selben Build per Digest ohne Tag in die Registry; die Tags bekommt der Digest erst nach dem Site-Test und einer Prüfung, dass er das getestete Image ist. Bisher baute der Push ein zweites Mal und konnte dabei Schichten eines gleichzeitigen Release-Laufs aus dem gemeinsamen Cache nehmen; die Prüfung schlug dann erst fehl, als die Tags schon gesetzt waren.
- Die Herkunftsangabe nennt neben dem Index auch die Images beider Plattformen. `gh attestation verify` prüft damit auch den Digest einer Plattform, etwa `oci://ghcr.io/encircle360-oss/erpnext_germanized@sha256:<digest>`; bisher fand es dafür keine Herkunftsangabe.
- Der wöchentliche Scan von `latest` läuft je Plattform, `linux/arm64` in der neuen Kategorie `trivy-image-latest-arm64` von Code Scanning; `linux/amd64` behält `trivy-image-latest`. Solange `latest` kein Image für `linux/arm64` hat, endet dieser Scan mit einem Hinweis.
- Das `Containerfile` prüft das Paket von wkhtmltopdf vor der Installation gegen seine SHA-256-Summe, je Plattform in `WKHTMLTOPDF_SHA256_AMD64` und `WKHTMLTOPDF_SHA256_ARM64`.
- Veröffentlichungen bauen die Stufe `base` ohne Cache, die Debian-Pakete wie nginx und Chromium sind damit auf dem Stand jedes Builds. Bisher kamen sie aus dem Cache und blieben so alt wie dessen erster Build; Pull Requests nutzen den Cache weiter.
- README, [Apps](docs/apps.md) und [Roadmap](docs/roadmap.md) nennen den heutigen Umfang von Steuerbote von der Umsatzsteuer-Voranmeldung bis zu E-Bilanz und Jahresabschluss, statt „zuerst die Umsatzsteuer-Voranmeldung“; die Links auf die Dokumentation von Steuerbote und banking zeigen auf die gepinnten Tags.

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
