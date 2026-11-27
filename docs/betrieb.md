# Betrieb

Diese Seite beschreibt, wie das Image läuft: mit docker compose nach [examples/compose.yaml](../examples/compose.yaml) oder auf Kubernetes mit dem Helm-Chart von Frappe. Dazu kommen Volumes, Sicherungen, Updates, Scheduler und Worker und der Reverse Proxy davor. Was im Image steckt, beschreibt [Architektur](architektur.md), welche Tags es gibt, [Versionierung](versionierung.md).

Die Befehle unten laufen im Verzeichnis mit `compose.yaml`. `<site>` steht für den Namen der Site, im Beispiel `erp.localhost`.

## Dienste

Alle Dienste mit Ausnahme von Datenbank und Redis laufen aus demselben Image, nur mit anderem Befehl. Das Beispiel übernimmt Aufbau und Befehle aus `pwd.yml` von [frappe_docker](https://github.com/frappe/frappe_docker) v4.2.0.

| Dienst | Aufgabe |
|---|---|
| `configurator` | läuft bei jedem `docker compose up` einmal und schreibt Datenbank, Redis, Port des Websockets und `chromium_path` in `sites/common_site_config.json` |
| `create-site` | läuft bei jedem `docker compose up` einmal und legt die Site mit allen Apps außer dem optionalen CRM an, wenn es sie noch nicht gibt |
| `backend` | gunicorn auf Port 8000 |
| `frontend` | nginx auf Port 8080, im Beispiel als Port 8080 des Rechners veröffentlicht |
| `websocket` | socket.io auf Port 9000 für Benachrichtigungen und Aktualisierungen in Echtzeit |
| `queue-short`, `queue-long` | Worker für Hintergrundjobs, `queue-short` für die Queues `short` und `default`, `queue-long` für `long`, `default` und `short` |
| `scheduler` | startet die geplanten Jobs der Apps |
| `db` | MariaDB 11.8 mit `utf8mb4` und `utf8mb4_unicode_ci` |
| `redis-cache`, `redis-queue` | Redis 6.2 für Cache und Queues |

## Mit docker compose

Den ersten Start beschreibt der [Schnellstart](../README.md#schnellstart). Danach gilt:

```bash
docker compose ps                        # state of all services
docker compose logs -f backend           # logs of one service
docker compose exec backend bench --site <site> list-apps
docker compose down                      # stops everything, the volumes stay
```

`docker compose down -v` löscht zusätzlich alle Volumes und damit Datenbank, Sites und Dateien.

Einstellungen im Beispiel:

- **Image und Tag** stehen einmal unter `x-erpnext`, Site-Name und Passwörter einmal unter `x-site`. Für eine dauerhafte Installation gehört dort ein volles Tag wie `16.60.0-1` hin, siehe [Versionierung](versionierung.md#wie-nutzer-pinnen).
- **Der Name der Site** ist `erp.localhost`. Soll die Site unter einer eigenen Domain laufen, ist es am einfachsten, die Site von Anfang an nach der Domain zu nennen, etwa `erp.example.com`. bench hat keinen Befehl, der eine Site umbenennt.
- **Passwörter** setzt `create-site` nur beim Anlegen der Site, MariaDB das Root-Passwort nur beim ersten Start. Das Passwort des Administrators ändert danach `bench --site <site> set-admin-password`.
- **Projektname** ist `erpnext_germanized` (Feld `name` oben in der Datei). Die Volumes heißen deshalb etwa `erpnext_germanized_sites`, gleich in welchem Verzeichnis die Datei liegt.

## Auf Kubernetes

Für Kubernetes gibt es das offizielle Helm-Chart [frappe/helm](https://github.com/frappe/helm), Chart `erpnext` aus dem Repository `https://helm.erpnext.com`. Das Chart ist für die Images aus frappe_docker gebaut und startet dieselben Befehle wie das Beispiel für docker compose: `nginx-entrypoint.sh`, gunicorn, `bench worker`, `bench schedule` und `socketio.js`. Dieses Image hat denselben Aufbau. Diese Werte reichen für eine Site mit allen Apps außer dem optionalen CRM, hier für das Chart in Version 8.0.93:

```yaml
# custom-values.yaml for the chart erpnext 8.0.93
image:
  repository: ghcr.io/encircle360-oss/erpnext_germanized
  tag: "16.60.0-1"
  pullPolicy: IfNotPresent

persistence:
  worker:
    storageClass: CHANGE_ME # a storage class with ReadWriteMany

mariadb-sts:
  enabled: true
  rootPassword: CHANGE_ME
  image:
    tag: "11.8"
  myCnf: |
    [mysqld]
    skip-character-set-client-handshake
    skip-innodb-read-only-compressed
    character-set-server=utf8mb4
    collation-server=utf8mb4_unicode_ci
    innodb-snapshot-isolation=OFF

jobs:
  createSite:
    enabled: true
    siteName: erp.example.com
    adminPassword: CHANGE_ME
    installApps:
      - erpnext
      - hrms
      - erpnext_germany
      - erpnext_datev
      - eu_einvoice
      - pdf_on_submit
      - banking
      - insights
      # - crm # optional, see docs/apps.md
      - briefbote
      - steuerbote
```

```bash
helm repo add frappe https://helm.erpnext.com
helm upgrade --install frappe-bench --namespace erpnext --create-namespace frappe/erpnext --version 8.0.93 -f custom-values.yaml
```

Geprüft ist das Beispiel gegen das Chart 8.0.93: `helm template` rendert es ohne Fehler, kubeconform findet in den Manifesten keinen Fehler, und die Jobs `jobs.configure` und `jobs.createSite` nehmen die MariaDB des Charts mit dem Passwort aus `mariadb-sts.rootPassword`. Eine neuere Version des Charts kann Werte umbenennen, deshalb steht die Version im Befehl.

- **Image:** `image.repository` und `image.tag` gelten für alle Pods und Jobs des Charts, die Frappe ausführen.
- **Speicher:** Das Chart legt für `sites` ein Volume mit `ReadWriteMany` an (`persistence.worker`), denn Backend, Worker, Scheduler und Websocket teilen es. Ohne `persistence.worker.storageClass` bricht `helm` mit einem Fehler ab, außer `persistence.worker.existingClaim` nennt ein vorhandenes Volume. Die Storage Class muss `ReadWriteMany` können; das README des Charts nennt Möglichkeiten und lässt auf einem Cluster mit nur einem Knoten auch `ReadWriteOnce` unter `persistence.worker.accessModes` zu.
- **Datenbank:** Ohne weitere Werte legt das Chart keine Datenbank an. `mariadb-sts` startet MariaDB als StatefulSet des Charts, mit einem eigenen Volume aus der Standard-Storage-Class des Clusters, sofern `mariadb-sts.persistence.storageClass` keine andere nennt. Statt der Vorgabe `mariadb:10.6` des Charts nimmt das Beispiel MariaDB 11.8 mit den Einstellungen des Site-Tests, darunter `innodb-snapshot-isolation=OFF`. `myCnf` ersetzt die Vorgabe des Charts ganz, deshalb stehen dort alle Zeilen. Eine MariaDB außerhalb des Charts braucht dieselben Einstellungen. Für sie stehen statt `mariadb-sts` diese Werte in der Datei, dazu ein vorher angelegtes Secret mit dem Root-Passwort:

  ```yaml
  dbHost: mariadb.example.com
  dbPort: 3306
  dbRootUser: root
  dbExistingSecret: erpnext-db-root
  dbExistingSecretPasswordKey: password
  ```

- **Apps** stehen unter `jobs.createSite.installApps` in der Reihenfolge von `apps.json` und mit den Namen, die bench kennt, also `pdf_on_submit` statt `erpnext_pdf-on-submit`. Frappe CRM ist im Image, wird aber nur installiert, wo man es will: Dafür kommt `crm` an seiner Stelle nach `insights` in die Liste, oder man installiert es später, siehe [Apps](apps.md#crm). Statt `adminPassword` kann `adminExistingSecret` auf ein vorhandenes Secret zeigen.
- **Chromium:** Anders als das Beispiel für docker compose setzt das Chart `chromium_path` nicht. Ohne den Eintrag lädt Frappe beim ersten PDF mit dem Generator „chrome“, der Vorgabe der Druckeinstellungen, in jedem Pod, der ein PDF erzeugt, ein eigenes Chromium aus dem Internet, siehe [Architektur](architektur.md#chromium). Weil `common_site_config.json` im Volume `sites` liegt, reicht es, den Eintrag einmal zu setzen: `kubectl --namespace erpnext exec deploy/frappe-bench-erpnext-gunicorn -- bench set-config -g chromium_path /usr/lib/chromium/chromium-headless-shell`.
- **Migration und Sicherung** laufen als Jobs des Charts. `jobs.migrate` mit `siteName` schaltet den Wartungsmodus ein, führt `bench migrate` aus und schaltet ihn wieder aus, auch wenn die Migration fehlschlägt: Die drei Befehle stehen mit `;` hintereinander, und der Job endet mit dem Ergebnis des letzten. Ob die Migration gelungen ist, zeigt deshalb nur das Log des Jobs. `jobs.backup` mit `siteName` und `withFiles` legt eine Sicherung im Volume `sites` an.
- Alle Werte nennt das [README des Charts](https://github.com/frappe/helm/blob/main/erpnext/README.md), ihre Vorgaben stehen in seiner [values.yaml](https://github.com/frappe/helm/blob/main/erpnext/values.yaml).

Ein volles Tag mit `pullPolicy: IfNotPresent` hält die Pods auf der Version, die eingetragen ist. Bewegliche Tags führen mit `Always` beim nächsten Neustart eines Pods zu einer neuen Version ohne Migration.

## Volumes

| Volume | Inhalt | Sichern |
|---|---|---|
| `sites` | alle Sites mit `site_config.json`, öffentlichen und privaten Dateien und Sicherungen unter `<site>/private/backups`, dazu `common_site_config.json` und `apps.txt` | ja |
| `db-data` | die Datenbanken von MariaDB | ja, über `bench backup` oder einen Dump |
| `logs` | Logdateien der Bench | nach Bedarf |
| `redis-queue-data` | Daten der Queue | nein |

`site_config.json` enthält das Passwort der Datenbank der Site und den Schlüssel `encryption_key`. Mit ihm verschlüsselt Frappe gespeicherte Passwörter, etwa die von E-Mail-Konten. Geht der Schlüssel verloren, lassen sich diese Passwörter nicht mehr entschlüsseln. Behandle das Volume `sites` und jede Sicherung deshalb wie ein Geheimnis.

Steuerbote legt die Laufzeit von ERiC, wenn sie eingerichtet ist, unter `sites/eric` ab, also ebenfalls im Volume `sites`. `bench backup` sichert sie nicht mit, denn sie liegt außerhalb jeder Site, siehe [Apps](apps.md#steuerbote).

## Sicherungen

```bash
docker compose exec backend bench --site <site> backup --with-files
```

`bench backup` schreibt nach `sites/<site>/private/backups/` vier Dateien: die Datenbank (`…-database.sql.gz`), die öffentlichen und die privaten Dateien (`…-files.tar`, `…-private-files.tar`) und die Konfiguration der Site (`…-site_config_backup.json`). Jeder Dateiname beginnt mit Zeitstempel und Site-Name, im Namen mit Unterstrichen statt Punkten, etwa `20261118_120000-erp_localhost-database.sql.gz`. Ohne `--with-files` entstehen nur Datenbank und Konfiguration. `--site all` sichert alle Sites, `--compress` packt die Dateien als `.tgz`. Mit „Backups verschlüsseln“ in den Systemeinstellungen verschlüsselt Frappe die Sicherungen mit gpg, das im Image enthalten ist; der Schlüssel steht dann ebenfalls in `site_config.json`.

Die Sicherungen liegen im selben Volume wie die Site. Erst eine Kopie an einem anderen Ort schützt vor dem Verlust des Volumes:

```bash
docker compose cp backend:/home/frappe/frappe-bench/sites/<site>/private/backups ./backups
```

Wiederherstellen in eine bestehende Site, hier `erp.localhost` mit einer Sicherung im Volume:

```bash
docker compose exec backend bench --site erp.localhost restore \
  /home/frappe/frappe-bench/sites/erp.localhost/private/backups/20261118_120000-erp_localhost-database.sql.gz \
  --with-public-files /home/frappe/frappe-bench/sites/erp.localhost/private/backups/20261118_120000-erp_localhost-files.tar \
  --with-private-files /home/frappe/frappe-bench/sites/erp.localhost/private/backups/20261118_120000-erp_localhost-private-files.tar
```

`restore` fragt nach dem Root-Passwort der Datenbank. bench führt seine Befehle im Verzeichnis `sites` aus, deshalb stehen die Pfade oben vollständig da. Kommt die Sicherung von einer anderen Installation, gehört der `encryption_key` aus `…-site_config_backup.json` in die `site_config.json` der Site, sonst bleiben die gespeicherten Passwörter unlesbar.

## Updates

Ein Update ist ein Wechsel des Image-Tags. Die Daten bleiben in den Volumes, `bench migrate` bringt danach die Datenbank auf den Stand der neuen Apps.

1. **Lesen**, was sich ändert: den Abschnitt im [Changelog](../CHANGELOG.md), die Release-Notes des Releases und bei neuen Versionen von ERPNext oder den Apps deren Release-Notes.
2. **Sichern:** `docker compose exec backend bench --site <site> backup --with-files` und die Sicherung aus dem Volume kopieren, siehe oben.
3. **Wartungsmodus einschalten:** `docker compose exec backend bench --site <site> set-maintenance-mode on`. Die Site lässt dann nur noch Lesen zu und lehnt Änderungen ab, und der Scheduler lässt sie aus. Soll sie gar keine Anfragen annehmen wie vor Frappe v16.61.0, setzt `bench --site <site> set-config -p allow_reads_during_maintenance 0` das (`frappe/app.py`).
4. **Neues Tag eintragen** unter `x-erpnext` in `compose.yaml`, dann:

   ```bash
   docker compose pull
   docker compose up -d
   ```

5. **Migrieren:** `docker compose exec backend bench --site <site> migrate`, bei mehreren Sites `--site all`.
6. **Cache leeren:** `docker compose exec backend bench --site <site> clear-cache`, sobald alle Dienste aus dem neuen Image laufen. Der Cache in Redis, den alle Dienste teilen, kann noch die Namen der Asset-Bündel des alten Images enthalten. Der PDF-Generator auf Chromium-Basis meldet dann „Attempted Unauthorized File Access in PDF Generator“, und dem PDF fehlt das Druck-Stylesheet von Frappe.
7. **Wartungsmodus ausschalten:** `docker compose exec backend bench --site <site> set-maintenance-mode off`.

Schlägt die Migration fehl, bleibt der Wartungsmodus an. Das Log von `bench migrate` nennt den Patch, der gescheitert ist.

**Neue App aus dem Image installieren:** `bench --site <site> install-app <app>` nimmt nur Apps, die in `sites/apps.txt` stehen, und diese Datei liegt im Volume `sites`, nicht im Image. Nach dem Update auf ein Image mit einer neuen App nennt sie die App erst, wenn sie neu geschrieben ist. Das Beispiel für docker compose schreibt sie bei jedem `docker compose up` im Dienst `configurator`, das Helm-Chart im Job `jobs.configure`, solange er eingeschaltet ist. Wo dieser Job abgeschaltet ist, meldet bench „App <app> not in apps.txt“; dann vorher in einem Pod des Backends im Verzeichnis des Bench `ls -1 apps > sites/apps.txt` ausführen, wie es der Job tut.

**Zurück zur vorigen Version** geht es nur mit der Sicherung aus Schritt 2. `bench migrate` ändert die Datenbank, und die Patches von Frappe und den Apps laufen nur vorwärts: Das vorige Tag allein läuft nicht sicher auf einer migrierten Datenbank. Also das vorige Tag eintragen, `docker compose up -d` und die Site aus der Sicherung wiederherstellen.

Auf Kubernetes gilt dieselbe Reihenfolge: Sicherung über `jobs.backup`, neues `image.tag`, dann `jobs.migrate`. Während der Rollout Pods beider Images gleichzeitig laufen lässt, zeigen die Namen der Asset-Bündel im gemeinsamen Cache auf die Dateien des einen oder des anderen Images; in dieser Zeit keine Belege anlegen oder drucken. Laufen alle Pods aus dem neuen Image, einmal `bench --site <site> clear-cache` in einem davon ausführen, etwa `kubectl --namespace erpnext exec deploy/frappe-bench-erpnext-gunicorn -- bench --site <site> clear-cache`. Anders als oben bleibt der Wartungsmodus nach einer fehlgeschlagenen Migration nicht an: `jobs.migrate` schaltet ihn in jedem Fall aus, und nur das Log des Jobs zeigt, ob `bench migrate` durchgelaufen ist, siehe [Auf Kubernetes](#auf-kubernetes).

## Scheduler und Worker

- **Scheduler.** Der Dienst `scheduler` (`bench schedule`) startet die geplanten Jobs aller Sites. Davon hängen etwa Versand und Abruf von E-Mails ab, ebenso die regelmäßige Prüfung der USt-IdNr. in erpnext_germany: Der Scheduler legt die Prüfungen an, die Abfrage bei VIES läuft dann als Hintergrundjob in der Queue `long`. Der Einrichtungsassistent schaltet den Scheduler einer Site ein. Den Zustand zeigt `docker compose exec backend bench --site <site> scheduler status`.
- **Worker.** Hintergrundjobs laufen in den Diensten `queue-short` und `queue-long`. Lange Jobs, etwa die Übermittlung von Steuerbote und die Prüfung der USt-IdNr. bei VIES, laufen in der Queue `long`, im Beispiel also nur im Dienst `queue-long`. Fehlen die Worker, bleiben Hintergrundjobs liegen, etwa PDFs von PDF on Submit, die im Hintergrund entstehen sollen. `docker compose exec backend bench --site <site> show-pending-jobs` zeigt, was wartet.
- Mehr Last verteilt sich auf zusätzliche Worker: `docker compose up -d --scale queue-short=2`.

## Reverse Proxy

Der Dienst `frontend` spricht nur HTTP. Für den Betrieb im Netz gehört ein Reverse Proxy mit TLS davor, etwa Caddy, Traefik oder nginx. Das Image richtet sich dabei nach diesen Umgebungsvariablen des Dienstes `frontend` (`nginx-entrypoint.sh` aus frappe_docker):

| Variable | Vorgabe | Bedeutung |
|---|---|---|
| `FRAPPE_SITE_NAME_HEADER` | `$host` | welche Site eine Anfrage bekommt; das Beispiel setzt den Namen der einen Site, damit sie unter jedem Hostnamen antwortet |
| `UPSTREAM_REAL_IP_ADDRESS` | `127.0.0.1` | Adresse des Reverse Proxy, dem nginx die Client-Adresse glaubt |
| `UPSTREAM_REAL_IP_HEADER` | `X-Forwarded-For` | Header mit der Client-Adresse |
| `UPSTREAM_REAL_IP_RECURSIVE` | `off` | `on`, wenn mehrere Proxys hintereinander stehen |
| `PROXY_READ_TIMEOUT` | `120` | Sekunden, die nginx auf das Backend wartet |
| `CLIENT_MAX_BODY_SIZE` | `50m` | größte Anfrage, also auch der größte Upload |
| `NGINX_LISTEN_PORT` | `8080` | Port von nginx im Container |

Der Reverse Proxy

- leitet alle Anfragen an Port 8080 des Dienstes `frontend` weiter,
- reicht den Header `Host` unverändert durch, wenn `FRAPPE_SITE_NAME_HEADER` auf `$host` steht,
- setzt `X-Forwarded-For` und `X-Forwarded-Proto: https`, damit Frappe die Client-Adresse und HTTPS erkennt,
- lässt unter `/socket.io` WebSocket-Verbindungen durch (Header `Upgrade` und `Connection`).

Damit Links in E-Mails die öffentliche Adresse tragen, gehört sie in die Konfiguration der Site: `docker compose exec backend bench --site <site> set-config host_name https://erp.example.com`.

Läuft der Reverse Proxy auf demselben Rechner, veröffentlicht `frontend` seinen Port besser nur lokal, also `127.0.0.1:8080:8080` statt `8080:8080` unter `ports`.
