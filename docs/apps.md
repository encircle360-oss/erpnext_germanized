# Apps

Diese Seite beschreibt jede App im Image: wozu sie da ist, woher sie kommt, unter welcher Lizenz sie steht, was sie für Deutschland mitbringt und wo sie eingerichtet wird. Grundlage sind README und Dokumentation der Projekte zum gepinnten Tag. Welche Version im Image steckt, steht in `apps.json` und in der Tabelle im [README](../README.md#enthaltene-apps). Weicht diese Seite von der Dokumentation eines Projekts ab, gilt die des Projekts.

Die Namen der Oberfläche stehen hier so, wie die deutsche Übersetzung sie zeigt, dahinter in Klammern der englische Name des DocTypes, wo das hilft.

## Frappe

- **Repository:** [frappe/frappe](https://github.com/frappe/frappe), Lizenz MIT
- **Dokumentation:** [docs.frappe.io/framework](https://docs.frappe.io/framework)

Frappe ist das Framework unter allen Apps: Python und MariaDB auf dem Server, eine eng verbundene Oberfläche im Browser. Es bringt die Oberfläche Desk, Rollen und Berechtigungen, eine REST-API für alle DocTypes, Berichte, Druckformate, E-Mail, Hintergrundjobs und den Scheduler mit. ERPNext ist die erste Anwendung, für die Frappe gebaut wurde.

Für Deutschland:

- **Übersetzung.** `frappe/locale/de.po`, gepflegt von der Community über Crowdin. Die Sprache gilt für die Site und lässt sich je Benutzer ändern.
- **Formate.** Mit dem Land Deutschland im Einrichtungsassistenten stellt Frappe Datum `dd.mm.yyyy`, Uhrzeit `HH:mm`, Zahlen `#.###,##`, Währung EUR und Zeitzone Europe/Berlin ein.

Einrichtung:

- **Systemeinstellungen** (System Settings): Sprache, Land, Zeitzone, Datums- und Zahlenformat und Währung. „Erster Wochentag“ steht auch nach dem Assistenten auf Sonntag. Als „Rundungsmethode“ steht vor dem Assistenten „Symmetrisches Runden (alt)“, der Assistent setzt „Symmetrisches Runden“, zur Wahl steht außerdem „Kaufmännisches Runden“. Welche Rundung zur Buchhaltung passt, klärt die Firma mit ihrer Steuerberatung.
- **Druckeinstellungen** (Print Settings): Vorgabe für den PDF-Generator, siehe [Architektur](architektur.md#was-im-image-steckt).

## ERPNext

- **Repository:** [frappe/erpnext](https://github.com/frappe/erpnext), Lizenz GPL-3.0
- **Dokumentation:** [docs.frappe.io/erpnext](https://docs.frappe.io/erpnext/)

ERPNext ist das ERP-System: Buchhaltung von der Buchung bis zu den Berichten, Auftragsabwicklung mit Verkauf, Einkauf und Lager, Fertigung, Anlagenverwaltung und Projekte mit Aufgaben und Zeiterfassung. ERPNext ist eine Marke der Frappe Technologies Pvt. Ltd., siehe deren [Logo and Trademark Policy](https://github.com/frappe/erpnext/blob/v16.61.0/TRADEMARK_POLICY.md).

Für Deutschland:

- **Kontenrahmen.** Für das Land Deutschland bietet der Einrichtungsassistent die Vorlagen „SKR03 mit Kontonummern“ und „SKR04 mit Kontonummern“ an (`erpnext/accounts/doctype/account/chart_of_accounts/verified/`), dazu die allgemeinen Vorlagen „Standard“ und „Standard with Numbers“.
- **Steuervorlagen.** Legt man eine Firma mit dem Land Deutschland an, erzeugt ERPNext aus `erpnext/setup/setup_wizard/data/country_wise_tax.json` passende Vorlagen: für den Verkauf etwa Inland, Lieferungen und sonstige Leistungen in die EU und in Drittländer, Bauleistungen nach § 13b UStG und den Nullsteuersatz nach § 12 Abs. 3 UStG, für den Einkauf Inland, EU, Drittland und § 13b UStG, dazu Artikelsteuervorlagen für 19 %, 7 % und 0 %.
- **Übersetzung.** `erpnext/locale/de.po`, ebenfalls über Crowdin.

Vorlagen sind ein Anfang, keine geprüfte Einrichtung. Kontenrahmen und Steuervorlagen gehören vor der ersten Buchung zur Steuerberatung.

Einrichtung: Firma, Kontenplan und Geschäftsjahr legt der Einrichtungsassistent an, alles Weitere regeln die Buchhaltungseinstellungen (Accounts Settings) und das Unternehmen (Company).

## HRMS

- **Repository:** [frappe/hrms](https://github.com/frappe/hrms) (Frappe HR), Lizenz GPL-3.0
- **Dokumentation:** [docs.frappe.io/hr](https://docs.frappe.io/hr/introduction)

HRMS ist die Personalverwaltung: Mitarbeiter von der Einstellung über Beförderungen und Versetzungen bis zum Austrittsgespräch, Urlaub und Anwesenheit, Spesen und Vorschüsse, Leistungsbeurteilung, Gehaltsstrukturen und Gehaltsabrechnung, dazu eine mobile App. Bis Version 13 gehörten diese Module zu ERPNext.

Für Deutschland bringt HRMS keinen eigenen Teil mit; `hrms/regional` enthält nur Indien und die Vereinigten Arabischen Emirate. Deutsche Felder am Mitarbeiter, die Liste der Krankenkassen und die Dienstreisen kommen aus [erpnext_germany](#erpnext_germany). Weil einige Funktionen von erpnext_germany HRMS voraussetzen, steht HRMS in `apps.json` davor.

## erpnext_germany

- **Repository:** [alyf-de/erpnext_germany](https://github.com/alyf-de/erpnext_germany) von der ALYF GmbH, Lizenz GPL-3.0; im Image vorübergehend aus dem Fork [encircle360-oss/erpnext_germany](https://github.com/encircle360-oss/erpnext_germany), siehe unten
- **Name in bench:** `erpnext_germany`

Die App sammelt regionale Anpassungen für Deutschland:

- **Berichte** „Summen- und Saldenliste“ und „Zusammenfassende Meldung“. Die Zusammenfassende Meldung führt derzeit jede Rechnung als sonstige Leistung (S). Dreiecksgeschäfte (D) und innergemeinschaftliche Lieferungen (L) sind in der CSV-Datei von Hand zu ändern.
- **Registerinformation** mit Registerart, Registergericht und Registernummer an Unternehmen, Kunde und Lieferant.
- **Prüfung der USt-IdNr.** über den Dienst VIES der Europäischen Kommission, von Hand oder automatisch: Der Scheduler prüft nach und nach jeden aktiven Kunden und Lieferanten mit USt-IdNr., dessen letzte Prüfung (USt-IdNr Prüfung, VAT ID Check) mehr als drei Monate zurückliegt. Jede Prüfung läuft als Hintergrundjob in der Queue `long`; der Worker dafür braucht Zugang zu `ec.europa.eu`.
- **Lückenlose Nummern.** Von Angeboten, Aufträgen und Ausgangsrechnungen lässt sich je Nummernkreis und Firma nur der jeweils letzte Beleg löschen. Den Schalter dazu enthalten die ERPNext-Deutschland-Einstellungen (ERPNext Germany Settings), vorgegeben ist er an.
- **Geschützte Anhänge.** An Angeboten, Aufträgen, Lieferscheinen, Rechnungen, Zahlungen, Buchungssätzen, Anlagen und weiteren Belegen lassen sich Anhänge nur löschen, solange der Beleg ein Entwurf oder storniert ist.
- **Mitarbeiter:** zusätzliche Felder, etwa für Steuerangaben, eine Liste der Konfessionen und, mit HRMS, eine Liste der deutschen Krankenkassen.
- **Geschäftsbriefe** (Business Letter) aus einer Geschäftsbriefvorlage, zum Drucken oder als E-Mail an Kunden und Lieferanten.
- **Dienstreisen** (Business Trip) mit HRMS: Verpflegungsmehraufwand nach Dienstreise-Region und Kilometerpauschale für den privaten Pkw. Eine gebuchte Dienstreise legt eine Spesenabrechnung (Expense Claim) als Entwurf an. Die Regionen mit ihren Pauschalen kommen bei der Installation als Grundliste nach dem deutschen Steuerrecht dazu. Ein Update der App kann neue Pauschalen bringen: Der Patch `import_business_trip_regions` in `patches.txt` importiert die Liste bei `bench migrate` erneut, legt fehlende Regionen an und ergänzt neue Zeiträume, ohne vorhandene Beträge zu ändern. In den Dienstreise-Einstellungen stehen die Kilometerpauschale und je eine „Art der Auslagenabrechnung“ für Verpflegungsmehraufwand und Kilometerpauschale.
- **GDPdU-Export** für die Übergabe von Daten an das Finanzamt nach § 147 Abs. 6 AO und den GoBD: je DocType eine CSV-Datei, auf Wunsch mit den Anhängen, dazu `index.xml` und die DTD, als ZIP-Datei am Export. Welche DocTypes dazugehören, entscheidet die App nicht, das klärt die Firma mit ihrer Steuerberatung.

Die DTD `gdpdu-01-03-2019.dtd` gehört nicht zur App, sie ist von der CaseWare Germany GmbH und liegt unverändert bei. Mehr steht im [README von erpnext_germany](https://github.com/alyf-de/erpnext_germany/blob/v16.2.2/README.md).

**Fork.** In v16.2.2 kommt der geplante Job der Prüfung der USt-IdNr. nicht mehr voran, sobald ein Kunde oder Lieferant eine USt-IdNr. hat, die sich nicht lesen lässt: Er bricht ab und fragt alle paar Minuten dieselben Partner erneut ab. Die Korrektur steht als [alyf-de/erpnext_germany#148](https://github.com/alyf-de/erpnext_germany/pull/148) beim Projekt. Bis ein Release sie enthält, baut das Image die App aus dem Tag `v16.2.2-encircle360.5` des Forks: v16.2.2 mit dieser Korrektur und sonst unverändert. Sobald ein Release die Korrektur enthält, zeigt `apps.json` wieder auf alyf-de/erpnext_germany mit dessen Release-Tag.

## erpnext_datev

- **Repository:** [alyf-de/erpnext_datev](https://github.com/alyf-de/erpnext_datev) von der ALYF GmbH, Lizenz GPL-3.0
- **Name in bench:** `erpnext_datev`

Die App verbindet ERPNext mit DATEV auf zwei Wegen:

- **DATEV Unternehmen Online.** Beim Buchen einer Ausgangsrechnung, Eingangsrechnung oder Spesenabrechnung schickt die App den Beleg per E-Mail an DATEV Unternehmen Online, als PDF des Ausdrucks oder als die Anhänge des Belegs. Einrichtung in den DATEV Unternehmen Online-Einstellungen: Integration aktivieren, unter „Absender“ das E-Mail-Konto wählen, je Belegart die Zieladresse aus DATEV Unternehmen Online eintragen und „Anhänge anfügen“ oder „Druck anfügen“ wählen. Die Absenderadresse muss die des gewählten E-Mail-Kontos sein.
- **DATEV-CSV-Export.** Der Bericht „DATEV“ zeigt die Buchungen (GL Entry) im Format von DATEV und exportiert sie mit den Stammdaten als ZIP-Datei für die Steuerberatung. Einrichtung in den DATEV-Einstellungen: Mandantennummer, Beraternummer und „Temporäre Gegenkontonummer“, empfohlen ist 9090.

ERPNext kennt keine Automatikkonten von DATEV. Mit dem Gegenkonto 9090 ist die Automatik abgeschaltet. Wer ein anderes Gegenkonto nimmt, bucht in ERPNext nur auf Konten ohne Automatik, sonst stimmt der Abzug der Umsatzsteuer nicht. DATEV und DATEV Unternehmen Online sind Marken der DATEV eG, die App ist von ihr weder geprüft noch empfohlen. Mehr steht im [README von erpnext_datev](https://github.com/alyf-de/erpnext_datev/blob/v16.0.2/README.md).

## eu_einvoice

- **Repository:** [alyf-de/eu_einvoice](https://github.com/alyf-de/eu_einvoice) von der ALYF GmbH, Lizenz GPL-3.0-or-later
- **Name in bench:** `eu_einvoice`
- **Dokumentation:** [eu_einvoice/docs](https://github.com/alyf-de/eu_einvoice/tree/v16.4.0/eu_einvoice/docs/en/eu_einvoice) im Repository

Die App erstellt und liest E-Rechnungen im Format UN/CEFACT Cross Industry Invoice (CII) in den Profilen BASIC, EN 16931, EXTENDED und XRECHNUNG. Außer bei XRECHNUNG lässt sich die XML in ein PDF einbetten (ZUGFeRD, Factur-X). UBL-Rechnungen und ein Versand über Peppol gehören nicht dazu.

- **Ausgangsrechnung.** Das Feld „E-Rechnungs-Profil“ wählt das Profil. Je nach den E-Rechnungs-Einstellungen entsteht die E-Rechnung beim Speichern oder Buchen zur Probe und wird gegen die Schematron-Regeln des Profils geprüft. „E-Rechnung herunterladen“ unter „…“ liefert die XML. Das PDF aus der Druckvorschau enthält sie eingebettet, außer beim Profil XRECHNUNG.
- **Eingangsrechnung.** Ein E-Rechnungs-Import (E Invoice Import) liest eine XML-Datei oder ein ZUGFeRD-PDF, prüft es und übernimmt Lieferant, Positionen, Steuern und Zahlungsbedingungen. Rechnungen mit formalen Fehlern lassen sich trotzdem importieren.
- **PDF/A-3.** Vor dem Einbetten wandelt die App das PDF mit Ghostscript in PDF/A-3 um. Ghostscript ist im Image, siehe [Architektur](architektur.md#ghostscript).

Einrichtung:

- **Codelisten** im Format Genericode, etwa für Zahlungsarten (UNTDID 4461), Einheiten, Steuerkategorien (UNTDID 5305), Befreiungsgründe (VATEX) und elektronische Adressen (EAS). Die XML-Datei wird zuerst heruntergeladen und dann hochgeladen; danach ordnet man die Codes Zahlungsbedingungen, Einheiten, Steuervorlagen und Konten zu.
- **Käufer-Referenz** (Buyer Reference), in Deutschland die Leitweg-ID für öffentliche Auftraggeber, an Ausgangsrechnung, Auftrag oder Kunde.
- **Elektronische Adresse** mit ihrem Schema an Unternehmen, Kunde und Lieferant; ohne Eintrag nimmt die App E-Mail-Adressen.
- **Bankverbindung** über eine Zahlungsweise vom Typ Bank mit Konto und Bankkonto, in der Vorlage der Zahlungsbedingungen gewählt.
- **E-Rechnungs-Einstellungen:** ob beim Speichern und Buchen validiert wird und was bei einem Fehler geschieht.

Die App [Compendium](https://github.com/alyf-de/compendium), die die Dokumentation in Desk unter `/app/docs` anzeigt, ist nicht im Image. Die Dokumentation steht deshalb nur im Repository.

## erpnext_pdf-on-submit

- **Repository:** [alyf-de/erpnext_pdf-on-submit](https://github.com/alyf-de/erpnext_pdf-on-submit) von der ALYF GmbH, Lizenz GPL-3.0-or-later
- **Name in bench:** `pdf_on_submit`, nicht der Name des Repositories. Unter diesem Namen steht die App in `bench --site <site> list-apps` und in `--install-app`.

Die App erzeugt beim Buchen eines Belegs ein PDF und hängt es an den Beleg. Das geht für jeden DocType, der sich drucken und buchen lässt.

Einrichtung in den PDF-on-Submit-Einstellungen: In der Tabelle „Aktiviert für“ steht eine Zeile je DocType, auf Wunsch mit eigenem Druckformat, Briefkopf, Muster für den Dateinamen und Filtern, etwa für eigene PDFs von Gutschriften. „PDF im Hintergrund erstellen“ ist vorgegeben an: Das PDF entsteht dann in einem Hintergrundjob, also nur mit laufenden Workern. Das PDF entsteht in der Sprache aus dem Feld Sprache des Belegs; an Kunden und Lieferanten lässt sich dafür eine eigene Drucksprache (Print Language) wählen. Seit v16.4.0 kann eine Zeile mit „Attach To Field“ das PDF zusätzlich in ein gewähltes Anhangfeld des Belegs schreiben, und die App bettet die XML der E-Rechnung in die PDFs aller Belegarten ein, die das unterstützen, nicht mehr nur der Ausgangsrechnung ([Release-Notes](https://github.com/alyf-de/erpnext_pdf-on-submit/releases/tag/v16.4.0)).

## banking

- **Repository:** [alyf-de/banking](https://github.com/alyf-de/banking) (ALYF Banking) von der ALYF GmbH, Lizenz GPL-3.0
- **Name in bench:** `banking`
- **Dokumentation:** [Banking Wiki](https://github.com/alyf-de/banking/wiki) und [banking/docs](https://github.com/alyf-de/banking/tree/v16.8.0/banking/docs/en/banking) im Repository

Die App holt Kontoauszüge als Banktransaktionen (Bank Transaction) in ERPNext und hilft, sie mit Belegen abzugleichen.

- **Abgleich** im Bankabgleich Beta (Bank Reconciliation Tool Beta): Banktransaktionen gegen Zahlungen und Buchungssätze oder gegen offene Ausgangs- und Eingangsrechnungen, für die der Abgleich die Zahlung selbst anlegt, mit HRMS auch gegen Spesenabrechnungen. Der Abgleich ist kostenlos und arbeitet auch mit Umsätzen aus anderen Quellen.
- **Import von Hand:** CAMT-Dateien (camt.052, camt.053) und MT940-Dateien, hochgeladen im Bankabgleich Beta.
- **EBICS:** Abruf der Umsätze direkt bei der Bank, für Banken in Deutschland, Österreich, Frankreich und der Schweiz. EBICS braucht ein kostenpflichtiges Abonnement bei ALYF ([banking.alyf.de](https://banking.alyf.de/banking-pricing)) und einen EBICS-Zugang der Bank. Für diesen Zugang empfiehlt die Dokumentation die Signaturklasse T: Damit ruft ERPNext Umsätze ab, kann aber keine Zahlungen auslösen.
- **SEPA-Zahlungsaufträge** (SEPA Payment Order) im Format pain.001 für Zahlungen an Lieferanten und Mitarbeiter, aus Eingangsrechnungen und mit HRMS aus Spesenabrechnungen. Einen gebuchten Auftrag lädt man unter „Aktionen“ mit „Als XML herunterladen“ herunter und dann selbst bei der Bank hoch. Das Senden per EBICS ist in banking v16.8.0 abgeschaltet, siehe [SEPA Payment Order](https://github.com/alyf-de/banking/blob/v16.8.0/banking/docs/en/banking/sepa-payment-order.md#send-via-ebics-currently-disabled).

Für EBICS nutzt die App die Python-Bibliothek fintech, die nicht unter einer Open-Source-Lizenz steht, siehe [README](../README.md#lizenz). ALYF erwirbt dafür eine Lizenz und erhält und speichert dazu Host-ID, Partner-ID und User-ID des EBICS-Zugangs. Löscht man den EBICS-Benutzer, widerruft ALYF die Lizenz und löscht die Angaben ([EBICS-Dokumentation](https://github.com/alyf-de/banking/blob/v16.8.0/banking/docs/en/banking/ebics-integration.md)). Kundennummer und API-Token des Abonnements gehören in die Bankeneinstellungen (Banking Settings).

## Insights

- **Repository:** [frappe/insights](https://github.com/frappe/insights) (Frappe Insights), Lizenz AGPL-3.0: Das sagt die Lizenzdatei [license.txt](https://github.com/frappe/insights/blob/v3.51.0/license.txt) zum gepinnten Tag, und so führt GitHub das Repository. `app_license` in `insights/hooks.py` nennt dagegen „GNU GPLv3“; maßgeblich ist die Lizenzdatei.
- **Name in bench:** `insights`
- **Dokumentation:** [docs.frappe.io/insights](https://docs.frappe.io/insights)
- **Versionen:** eine eigene Versionsreihe, im Image v3.51.0 aus der Reihe 3, freigegeben für Frappe ab 15 und vor 18 (`[tool.bench.frappe-dependencies]` in der `pyproject.toml`). Insights steht deshalb in `INDEPENDENTLY_VERSIONED`, und `bump` hebt es nur innerhalb der Hauptversion 3 an.

Insights ist ein Werkzeug für Auswertungen (Business Intelligence), mit dem auch Benutzer ohne SQL Berichte und Dashboards bauen sollen. Nach seinem [README](https://github.com/frappe/insights/blob/v3.51.0/README.md) verbindet es Daten aus mehreren Datenbanken, Dateien und Tabellen, baut Abfragen Schritt für Schritt im Query Builder mit Tabellen, Joins, Filtern und Berechnungen, zeigt Ergebnisse als Diagramme und stellt sie per Drag-and-drop zu Dashboards mit Filtern zusammen. Die Oberfläche liegt unter `/insights`. Benachrichtigungen (Insights Alert) gehen per E-Mail, Telegram oder Webhook.

- **Dashboards von ERPNext und HRMS.** ERPNext v16.61.0 bringt Arbeitsmappen für Insights mit, „Business Overview“, „Receivables“, „Assets“, „Buying“, „Selling“ und „Stock“, HRMS v16.60.1 „Attendance“, „Employee Lifecycle“, „Expense Claims“, „Recruitment“, „Human Resource“ und „Payroll“ (jeweils unter `<modul>/insights_workbook/`). Insights importiert die Arbeitsmappen, die die installierten Apps mitbringen, bei seiner Installation und nach jedem `bench migrate` (`insights/migrate.py`). Das Feld „Dashboards“ der Systemeinstellungen von Frappe v16.61.0, Insights oder Classic, vorgegeben Insights, legt fest, wie die Standard-Dashboards öffnen, die eine Fassung für Insights mitbringen; ohne die App Insights öffnen sie klassisch. Dafür ergänzt Insights Dashboard, Dashboard-Diagramm (Dashboard Chart) und Zahlenkarte (Number Card) um ein Feld, das auf ein Dashboard oder Diagramm von Insights zeigt, und Desk zeigt diese als Inseln (`insights/desk.py`).
- **Datenbanken.** Die eigene Datenbank der Site ist als Datenquelle „Site DB“ dabei. Für weitere Quellen bringt Insights die Python-Bibliothek ibis mit den Treibern für DuckDB, MariaDB und MySQL, SQLite, ClickHouse und PostgreSQL mit. BigQuery, das das README nennt, und MSSQL stehen in der `pyproject.toml` von v3.51.0 auskommentiert; ihre Treiber sind nicht im Image.
- **Datenspeicher.** Tabellen, die Insights in seinen eigenen Speicher importiert, legt es als DuckDB-Datei unter `private/files/insights_data_warehouse/insights.duckdb` der Site ab, im Container also im Volume `sites`. Sie ist eine Kopie der Quelldaten und kommt mit `bench backup --with-files` in die Sicherung.
- **Telemetrie.** Insights meldet Ereignisse über die Telemetrie von Frappe ([docs/telemetry.md](https://github.com/frappe/insights/blob/v3.51.0/docs/telemetry.md)). Frappe v16.61.0 sendet nur, wenn `pulse_api_key` in der Konfiguration steht und in den Systemeinstellungen „Allow Sending Usage Data for Improving Applications“ an ist (`frappe/utils/telemetry/pulse/client.py`). Das Image und die Beispiele setzen `pulse_api_key` nicht.

Im Image:

- **Python-Pakete.** Insights legt einige Pakete eng fest, die auch andere Apps nutzen: `sqlglot~=30.22.0`, `SQLAlchemy==2.0.41`, `pandas~=2.3.3` und `duckdb~=1.4.3`, dazu `ibis-framework~=11.0.0`, `python-telegram-bot==21.4` und `psycopg[binary]` (`pyproject.toml`). sqlglot kommt sonst nur über sql_metadata, eine Abhängigkeit von Frappe, die `sqlglot>=30.12.0,<31.0.0` zulässt, ins Image; mit Insights gilt deshalb die Version aus der Reihe 30.22, nicht die neueste, die Frappe allein bekäme. Der Site-Test prüft mit `pip check`, dass sich alle Pakete des Images vertragen, und schreibt die Version von sqlglot ins Log.
- **Oberfläche.** Die Oberfläche unter `/insights` und die Inseln für Desk baut der Build des Images aus `insights/frontend`. Der Site-Test prüft, dass beide Inseln in `assets.json` stehen und nginx sie ausliefert, und dass jede Arbeitsmappe, die eine App mitbringt, auf der Site steht.

## CRM

- **Repository:** [frappe/crm](https://github.com/frappe/crm) (Frappe CRM), Lizenz AGPL-3.0: Das sagt die Lizenzdatei [LICENSE](https://github.com/frappe/crm/blob/v16.5.0/LICENSE) zum gepinnten Tag, `app_license` in `crm/hooks.py` nennt „AGPLv3“.
- **Name in bench:** `crm`
- **Dokumentation:** [docs.frappe.io/crm](https://docs.frappe.io/crm)
- **Versionen:** die Reihe v16 für Frappe 16 (`frappe >=16.0.0,<17.0.0`), im Image v16.5.0. Das „Latest release“ auf GitHub kann ein Release der Reihe v15 sein; `check-versions` und `bump` bleiben wie bei jeder App auf der Hauptversion von Frappe.
- **Optional.** CRM ist im Image, aber die Beispiele installieren es nicht, siehe unten.

Frappe CRM ist ein CRM für Vertriebsteams. Nach seinem [README](https://github.com/frappe/crm/blob/v16.5.0/README.md) bündelt es Leads und Deals mit Aktivitäten, Kommentaren, Notizen und Aufgaben auf einer Seite, zeigt sie in einer Kanban-Ansicht und in eigenen Ansichten mit Filtern, Sortierung und Spalten. Eingebaut sind Telefonie über Twilio und Exotel, auch mit Aufzeichnung der Gespräche; WhatsApp geht über die App Frappe WhatsApp, die nicht im Image ist. Die Oberfläche liegt unter `/crm`. CRM hat eigene DocTypes wie CRM Lead und CRM Deal, neben Lead und Chance (Opportunity) aus ERPNext.

- **ERPNext.** Die Anbindung an ERPNext steht in den ERPNext CRM Settings und ist vorgegeben aus. Eingeschaltet arbeitet sie mit ERPNext auf derselben oder einer anderen Site, kann beim Wechsel eines Deals in einen gewählten Status einen Kunden anlegen und gleicht Artikel in beide Richtungen ab (`crm/fcrm/doctype/erpnext_crm_settings`).
- **Anreicherung über die Website** (Domain Enrichment). CRM kann die öffentliche Website eines Leads, Deals oder einer Organisation abrufen und daraus Felder wie Name, Beschreibung, Logo, Branche, E-Mail-Adressen, Telefonnummern und Profile in sozialen Netzwerken füllen, ohne Dienste Dritter ([README der Anreicherung](https://github.com/frappe/crm/blob/v16.5.0/crm/domain_enrichment/README.md)). Für neue Datensätze geschieht das automatisch nur, wenn in den CRM Enrichment Settings „Auto-enrich new records“ an ist; vorgegeben ist es aus. Die Abrufe gehen vom Server der Site aus ins Internet.
- **Eingriffe in Frappe.** CRM ersetzt die Klassen von Kontakt (Contact) und E-Mail-Vorlage (Email Template) durch eigene, erweitert Datenimport (Data Import) und Zuweisungsregel (Assignment Rule) und regelt, wer Datenimporte sieht (`override_doctype_class`, `extend_doctype_class` und `permission_query_conditions` in `crm/hooks.py`). Das gilt auf der ganzen Site, auch für ERPNext. Keine andere App im Image ersetzt diese Klassen.
- **Python-Pakete.** CRM bringt `twilio==8.5.0`, den Client für Twilio, und `tldextract` mit (`pyproject.toml`).

Installieren und entfernen: Wer CRM will, nimmt `--install-app crm` nach `insights` in `create-site` von [examples/compose.yaml](../examples/compose.yaml) oder `crm` in die Liste des Helm-Beispiels in [Betrieb](betrieb.md#auf-kubernetes) auf, oder installiert es auf einer bestehenden Site:

```bash
docker compose exec backend bench --site <site> install-app crm
```

Meldet bench dabei „App crm not in apps.txt“, fehlt die App in der Liste im Volume `sites`, siehe [Updates](betrieb.md#updates).

Entfernen geht mit `bench --site <site> uninstall-app crm`. Das löscht alle Daten von CRM auf der Site, also vorher sichern, siehe [Sicherungen](betrieb.md#sicherungen).

## Briefbote

- **Repository:** [encircle360-oss/briefbote](https://github.com/encircle360-oss/briefbote), Lizenz AGPL-3.0-or-later
- **Name in bench:** `briefbote`
- **Dokumentation:** [docs](https://github.com/encircle360-oss/briefbote/tree/v0.3.1/docs) im Repository

Briefbote bringt Druckformate für die Geschäftsdokumente deutscher Unternehmen nach DIN 5008 mit den Angaben, die das Gesetz verlangt, siebzehn in v0.3.1, darunter die Schlussrechnung als Variante der „Rechnung“:

| Druckformat | Beleg (DocType) | Wofür |
|---|---|---|
| [Rechnung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/rechnung.md) | Ausgangsrechnung (Sales Invoice) | Rechnung, Rechnungskorrektur, Stornorechnung oder kaufmännische Gutschrift, je nach Beleg |
| [Gutschrift](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/gutschrift.md) | Eingangsrechnung (Purchase Invoice) | Gutschrift im Gutschriftsverfahren |
| [Leistungsnachweis](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/leistungsnachweis.md) | Ausgangsrechnung (Sales Invoice) | die Stunden einer Rechnung aus ihren Stundenzetteln |
| [Angebot](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/angebot.md) | Angebot (Quotation) | Angebot mit „Gültig bis“ und Alternativpositionen |
| [Auftragsbestätigung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/auftragsbestaetigung.md) | Kundenauftrag (Sales Order) | Bestätigung mit Liefertermin und Zahlungsbedingungen |
| [Lieferschein](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/lieferschein.md) | Lieferschein (Delivery Note) | an die Lieferanschrift, mit Empfangsbestätigung, Preise nur nach Einstellung |
| [Mahnung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/mahnung.md) | Mahnung (Dunning) | Zahlungserinnerung und Mahnung nach Mahnstufe, Verzugszinsen und Pauschale nur, wo sie rechtmäßig sind |
| [Zahlungsbestätigung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/zahlungsbestaetigung.md) | Zahlungseingang (Payment Entry) | Bestätigung eines gebuchten Zahlungseingangs |
| [Quittung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/zahlungsbestaetigung.md) | Zahlungseingang (Payment Entry) | Quittung nach § 368 BGB mit Linien für die Unterschrift |
| [Bestellung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/bestellung.md) | Bestellung (Purchase Order) | Bestellschein mit Lieferterminen und Lieferanschrift |
| [Anfrage](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/anfrage.md) | Anfrage (Request for Quotation) | Anfrage an Lieferanten ohne Preise, mit Bedarfsterminen |
| [Lieferantenrücksendung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/lieferantenruecksendung.md) | Rücksendung eines Wareneingangs (Purchase Receipt) | Rücksendung an den Lieferanten mit der zurückgehenden Menge |
| [Packliste](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/packliste.md) | Packliste (Packing Slip) | Packstücke eines Lieferscheins mit Gewichten |
| [Zahlungsavis](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/zahlungsavis.md) | Zahlungsausgang (Payment Entry, Pay) | Ankündigung einer Überweisung an einen Lieferanten mit seinen Rechnungen |
| [Anzahlungsrechnung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/anzahlungsrechnung.md) | Proforma-Rechnung (Proforma Invoice) zum Kundenauftrag | Rechnung über eine Anzahlung vor der Leistung (§ 14 Abs. 5 UStG) |
| [Proforma-Rechnung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/proforma-rechnung.md) | Proforma-Rechnung (Proforma Invoice) zum Kundenauftrag | Proforma-Rechnung, ausdrücklich keine Rechnung im Sinne des § 14 UStG |
| [Schlussrechnung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/rechnung.md#anzahlungen-und-schlussrechnung) | Ausgangsrechnung (Sales Invoice) | Variante der „Rechnung“, die erhaltene Anzahlungen abzieht |
| [Geschäftsbrief](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/geschaeftsbrief-format.md) | Geschäftsbrief (Business Letter) von erpnext_germany | freier Brief; Briefbote legt das Format nur an, wo erpnext_germany installiert ist, im Image also immer |

**Status: Alpha, in Entwicklung, noch nicht einsatzfähig.** Die rechtlichen Texte und Regeln der Dokumente hat noch keine Steuerberatung und keine Rechtsanwältin geprüft; jede Seite der Dokumentation von Briefbote führt unter „Offen für die fachliche Prüfung“, was vor dem echten Einsatz zu klären ist.

> **Warnung: Die Umsatzsteuer einer Anzahlung steht in ERPNext doppelt in den Büchern.** Das gilt für jede Site mit ERPNext 16.61, auch ohne Briefbote. Ein Zahlungseingang mit „Advance Taxes and Charges“ bucht die Umsatzsteuer der Anzahlung beim Eingang, die Ausgangsrechnung über die ganze Leistung bucht sie noch einmal, und das Zuordnen der Anzahlung bucht am Steuerkonto nichts um. Bis eine Korrektur gebucht ist, steht die Umsatzsteuer der Anzahlung zweimal im Hauptbuch, ERPNext führt die Schlussrechnung um sie zu hoch offen, und eine Umsatzsteuer-Voranmeldung aus dem Hauptbuch zählt sie doppelt. Briefbote druckt den Restbetrag nach § 14 Abs. 5 UStG und korrigiert die Bücher nicht; wie zu korrigieren ist, klärt die Steuerberatung. Einzelheiten stehen in der Dokumentation [Anzahlungsrechnung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/anzahlungsrechnung.md).

Einrichtung, siehe [Einrichtung](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/einrichtung.md):

- Nach der Installation steht in der Leiste von ERPNext „Geschäftspost“. Dort gibt es je Unternehmen die Einstellungen Geschäftspost (Business Document Settings) mit Briefform, Papier, Logo, Angaben für den Fuß, Bankkonten, Steuerfällen, Basiszinssätzen, Mahnstufen und den Einstellungen des Lieferscheins. Die Schaltfläche „Einstellungen prüfen“ sagt, was fehlt, etwa ein Bankkonto oder ein Block des Fußes, der mehr als vier Zeilen bräuchte.
- **Fuß.** Seit v0.2.1 ordnet der Fuß seine bis zu vier Blöcke selbst in gleich breiten Spalten, je höchstens vier Zeilen; die frühere Einstellung „Spalten des Fußes“ ist ausgeblendet und wirkt nicht mehr. Ohne gewähltes Bankkonto bitten Rechnung und Mahnung nicht um Überweisung, sondern zeigen oben einen Befund.
- **Standard-Druckformate setzt die App nicht.** Wer die Formate von Briefbote als Standard will, setzt sie je DocType über „Customize Form“ (Feld Default Print Format), seit v0.3.0 auch für Geschäftsbrief, Anfrage, Packzettel und Zahlungsausgang.
- **Anzahlungs- und Proforma-Rechnungen.** Vor dem Einsatz die Warnung oben und die Grenzen auf der Seite „Anzahlungsrechnung“ lesen, dann in den Selling Settings „Enable Proforma Invoice“ einschalten und für Anzahlungsrechnungen einen eigenen Nummernkreis anlegen. Die Anzahlungsrechnung ist ein PDF, keine E-Rechnung.
- **Geschäftsbrief.** Das Druckformat und seine Einträge im Menü legt Briefbote nur an, wo erpnext_germany installiert ist; im Image ist das immer so, und `bench migrate` legt sie auf bestehenden Sites an.
- **Mahnarten ohne Zinsen und Gebühr.** Briefbote empfiehlt, in jeder Mahnart (Dunning Type) Zinssatz und Mahngebühr auf 0 zu setzen. Dann bucht ERPNext keine Zinsen ab Fälligkeit, und jede Mahnung erinnert an die offenen Rechnungen; Verzugszinsen und die Pauschale von 40 Euro druckt die Mahnung nur, wo sie rechtmäßig sind.
- **Basiszinssätze.** Ein Patch trägt bei `bench migrate` die Basiszinssätze der Bundesbank in bestehende Einstellungen ein; zum 1. Januar und 1. Juli kommt der neue Satz von Hand dazu.

Im Image:

- **PDF-Generatoren.** Die Formate legen keinen Generator fest; es gilt der Generator der Druckeinstellungen. Falz- und Lochmarken stehen seit v0.3.1 auf jeder Seite eines Ausdrucks, mit beiden Generatoren, vorher nur auf der ersten. Schlusstexte bleiben mit der letzten Position und den Summen zusammen. Gleich viele Seiten mit beiden Generatoren sagt Briefbote seit v0.3.0 nicht mehr zu: wkhtmltopdf 0.12.6 lässt nach einem Seitenumbruch Leerraum unter der ersten Zeile einer Tabelle, so dass ein Dokument mit wkhtmltopdf eine Seite mehr brauchen kann, etwa die Rechnung RE-2026-0121 aus dem Nachweis von Briefbote (4 statt 3 Seiten). Chromium ist der vorgegebene Generator. Entwürfe und stornierte Belege tragen „ENTWURF“ oder „STORNIERT“ mit Chromium schräg über jeder Seite, mit wkhtmltopdf über der ersten, auch nach der Wandlung in PDF/A durch eu_einvoice. Der Site-Test druckt jedes Format mit beiden Generatoren, dazu die Schlussrechnung mit ihrer Anzahlung, einen Geschäftsbrief über drei Seiten und die Rechnungen, deren Ende nahe am Seitenende liegt. Er verlangt jeweils gleich viele Seiten, außer bei den Fällen, die er mit ihren genauen Seitenzahlen als bekannte Abweichung führt, und prüft das Zeichen eines Entwurfs nach der Wandlung.
- **Schrift.** Die Formate setzen Inter und betten die Schrift als Data-URL ein, so dass ein Ausdruck nicht von den Schriften des Images abhängt und nichts aus dem Netz lädt. Der Site-Test prüft, dass die PDFs nur eingebettete Schriften enthalten, Inter, wo die Einstellungen die eingebettete Schrift wählen.

Für Ausdrucke gilt der [Haftungsausschluss von Briefbote](https://github.com/encircle360-oss/briefbote/blob/v0.3.1/docs/haftungsausschluss.md).

## Steuerbote

- **Repository:** [encircle360-oss/steuerbote](https://github.com/encircle360-oss/steuerbote), Lizenz AGPL-3.0-or-later
- **Name in bench:** `steuerbote`
- **Dokumentation:** [docs](https://github.com/encircle360-oss/steuerbote/tree/v0.15.3/docs) im Repository

Steuerbote bringt Steuermeldungen aus ERPNext an ELSTER: die Umsatzsteuer-Voranmeldung, die Dauerfristverlängerung mit Sondervorauszahlung und die Zusammenfassende Meldung, dazu die Jahresmeldungen, also Umsatzsteuer-, Körperschaftsteuer- und Gewerbesteuererklärung und E-Bilanz, und den Jahresabschluss mit der XBRL-Datei für die Offenlegung im Unternehmensregister. Prüfen, Testsenden und Senden über ERiC gehen nur mit `linux/amd64`, siehe unten. Die Voranmeldung rechnet es aus dem Hauptbuch und vergleicht Beleg für Beleg die gebuchte Steuer mit der Steuer, die sich aus der Bemessungsgrundlage ergibt. Die Vorgaben für SKR03 und SKR04 enthalten auch die Kontonummern der SKR-Vorlagen von ERPNext.

**Status: in Entwicklung, nicht einsatzfähig.** Ohne eigene Hersteller-ID läuft jede Übermittlung über ERiC nur als Simulation. Bis dahin geht die Voranmeldung als XML-Datei und die Zusammenfassende Meldung als CSV-Datei über den Import in Mein ELSTER, siehe [Abgabe über Mein ELSTER](https://github.com/encircle360-oss/steuerbote/blob/v0.15.3/docs/abgabe-mein-elster.md) und [Zusammenfassende Meldung](https://github.com/encircle360-oss/steuerbote/blob/v0.15.3/docs/zm.md). Den Vordruck USt 1 H und die Erklärungen trägt man nach dem Druckformat in Mein ELSTER von Hand ein; eine E-Bilanz nimmt Mein ELSTER nicht an, ihre XBRL-Datei geht an die Steuerberatung.

Im Image:

- **ERiC ist nicht dabei.** ERiC, die Bibliothek der Finanzverwaltung für die Übermittlung, darf nur als Teil des eigenen Produkts weitergegeben werden. Jeder Betreiber lädt ERiC für Linux x86_64 selbst aus dem ELSTER-Entwicklerbereich und richtet es in den ERiC-Einstellungen ein, siehe [ERiC](https://github.com/encircle360-oss/steuerbote/blob/v0.15.3/docs/eric.md).
- **Plattform.** ERiC braucht Linux x86_64 mit glibc ab 2.28 und mindestens 5 GiB freien Speicher. Das Image für `linux/amd64` ist auf Debian trixie gebaut, das glibc 2.41 mitbringt. Im Image für `linux/arm64` ist Steuerbote installiert, ERiC läuft dort aber nicht; was ERiC braucht, also Prüfen, Testsenden und Senden an ELSTER, geht nur mit `linux/amd64`. Wer ERiC nutzt, betreibt deshalb alle Dienste aus dem Image auf `linux/amd64`, in einem Kubernetes-Cluster mit Knoten beider Plattformen per `kubernetes.io/arch: amd64` im `nodeSelector` jedes Dienstes und Jobs des Charts. Die Abgabe als XML-Datei über Mein ELSTER braucht ERiC nicht und geht auf beiden Plattformen.
- **Ablage.** Die eingerichtete Laufzeit liegt außerhalb jeder Site in `sites/eric` der Bench, im Container also im Volume `sites`. Sie bleibt bei einem Wechsel des Images erhalten, `bench backup` sichert sie aber nicht. `steuerbote_eric_root` in `common_site_config.json` legt ein anderes Verzeichnis fest.
- **Worker.** Die Einrichtung von ERiC sowie Prüfen, Testsenden und Senden laufen als Hintergrundjobs in der Queue `long`, im Beispiel also im Dienst `queue-long`. Das Archiv von ERiC muss deshalb in diesem Container liegen; am einfachsten im Volume `sites`, das alle Dienste teilen.

Für Steuermeldungen gilt der [Haftungsausschluss von Steuerbote](https://github.com/encircle360-oss/steuerbote/blob/v0.15.3/README.md#haftungsausschluss).

## Zusammenspiel der Apps

- **HRMS und erpnext_germany:** Dienstreisen legen Spesenabrechnungen von HRMS an, die Krankenkassen hängen an HRMS. Deshalb kommt HRMS zuerst.
- **erpnext_datev und erpnext_pdf-on-submit:** Wer für dieselbe Belegart beide nutzt, wählt in den DATEV Unternehmen Online-Einstellungen „Anhänge anfügen“. PDF on Submit hängt das PDF an, und erpnext_datev schickt diesen Anhang.
- **banking und erpnext_germany:** erpnext_germany ergänzt die Eingangsrechnung um „Dienstreise“, „Dienstreise-Mitarbeiter“ und „An Mitarbeiter zahlen“. Das letzte Feld markiert eine Rechnung, die ein Mitarbeiter vorgestreckt hat, mit oder ohne Dienstreise. Sind „Dienstreise-Mitarbeiter“ und „An Mitarbeiter zahlen“ gesetzt, geht ein SEPA-Zahlungsauftrag dazu an den Mitarbeiter statt an den Lieferanten; banking zeigt dann statt „Lieferanten-Bankkonto“ das Feld „Mitarbeiter-Bankkonto“.
- **banking und HRMS:** Banktransaktionen lassen sich gegen offene Spesenabrechnungen abgleichen, und aus einer genehmigten Spesenabrechnung entsteht direkt ein SEPA-Zahlungsauftrag.
- **ERPNext und Steuerbote:** Die Vorgaben von Steuerbote für SKR03 und SKR04 kennen die Kontonummern der SKR-Vorlagen von ERPNext.
- **Briefbote und erpnext_germany:** Briefbote nimmt die Registerangaben des Unternehmens aus erpnext_germany, wenn die Einstellungen Geschäftspost keine haben, und den Grund einer Steuerbefreiung aus dem Feld `tax_exemption_reason` der Ausgangsrechnung, wenn der Steuerfall keinen nennt.
- **Insights, ERPNext und HRMS:** Insights importiert die Arbeitsmappen, die ERPNext und HRMS mitbringen, und die Standard-Dashboards öffnen in ihrer Fassung für Insights, solange „Dashboards“ in den Systemeinstellungen auf Insights steht.
- **CRM und Insights:** CRM v16.5.0 bringt selbst eine Arbeitsmappe „CRM“ für Insights mit (`crm/fcrm/insights_workbook`), die Insights bei der Installation von CRM importiert.
- **CRM und ERPNext:** CRM legt auf Wunsch Kunden in ERPNext an und gleicht Artikel ab, siehe [CRM](#crm). Lead und Chance von ERPNext bleiben daneben bestehen; welches CRM eine Firma nutzt, entscheidet sie.
- **Briefbote, eu_einvoice und erpnext_pdf-on-submit:** eu_einvoice bettet sein XML auch in das PDF eines Druckformats von Briefbote ein, wenn es über den PDF-Download entsteht. PDF on Submit hängt beim Buchen ein PDF mit dem Druckformat seiner Einstellungen an; mit „Rechnung“ entsteht so das PDF, das aufbewahrt wird.

## Nicht im Image

- **ERiC** für Steuerbote, aus Lizenzgründen, siehe oben.
- **Compendium**, die Anzeige der Dokumentation von eu_einvoice und banking in Desk.
- **Weitere Apps.** Vorschläge für Apps, die deutsche Unternehmen brauchen, gehen als Issue an dieses Repository, siehe [Roadmap](roadmap.md).
