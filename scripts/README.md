# MacBook Restic Backup zu TrueNAS

Automatisches Backup-Skript für MacBook mit restic zu einem TrueNAS Server über SFTP.

## Voraussetzungen

### 1. SSH-Zugang zu TrueNAS

- SSH-Key muss bereits eingerichtet sein: `~/.ssh/id_rsa`
- Test der Verbindung:
  ```bash
  ssh -p 22022 -i ~/.ssh/id_rsa rbackup@192.168.30.108
  ```
- Create ssh config (`~/.ssh/config`):
  ```
  Host truenas-backup
    HostName 192.168.30.108
    User rbackup
    Port 22022
    IdentityFile ~/.ssh/id_rsa
  ```

### 2. TrueNAS Dataset

Stelle sicher, dass auf dem TrueNAS Server ein Dataset für Backups existiert:
- Standard-Pfad im Skript: `/mnt/storage/storage-share-smb/rbackup`
- Passe `BACKUP_PATH` in der Konfiguration an, falls nötig

## Konfiguration

Öffne `macbook-backup.sh` und passe folgende Variablen an:

### Backup-Verzeichnisse

```bash
BACKUP_DIRS=(
    "$HOME/Documents"
    "$HOME/Projects"
    "$HOME/Desktop"
    # Füge weitere Verzeichnisse hinzu
)
```

### TrueNAS-Verbindung

```bash
TRUENAS_HOST="192.168.30.108"
TRUENAS_PORT="22022"
TRUENAS_USER="rbackup"
SSH_KEY="$HOME/.ssh/id_rsa"
BACKUP_PATH="/mnt/storage/storage-share-smb/rbackup"
```

### Aufbewahrungsrichtlinie

```bash
KEEP_DAILY=7      # 7 tägliche Backups
KEEP_WEEKLY=4     # 4 wöchentliche Backups
KEEP_MONTHLY=6    # 6 monatliche Backups
KEEP_YEARLY=2     # 2 jährliche Backups
```

### Ausschlussmuster

```bash
EXCLUDE_PATTERNS=(
    "*.tmp"
    "*.cache"
    ".DS_Store"
    "node_modules"
    ".git"
    "Cache"
    "Caches"
    ".Trash"
)
```

## Verwendung

### Interaktives Menü

```bash
./macbook-backup.sh
```

Das Skript zeigt ein interaktives Menü mit folgenden Optionen:
1. Repository initialisieren
2. Backup durchführen
3. Alte Backups aufräumen
4. Snapshots anzeigen
5. Aus Backup wiederherstellen
6. Beenden

### Kommandozeilen-Nutzung

```bash
# Repository initialisieren (nur einmal nötig)
./macbook-backup.sh init

# Backup durchführen
./macbook-backup.sh backup

# Alte Backups aufräumen
./macbook-backup.sh prune

# Snapshots auflisten
./macbook-backup.sh list

# Aus Backup wiederherstellen
./macbook-backup.sh restore
```

## Erste Schritte

### 1. Repository initialisieren

Beim ersten Mal musst du das restic Repository initialisieren:

```bash
./macbook-backup.sh init
```

Du wirst aufgefordert, ein Passwort zu erstellen. **Bewahre dieses Passwort sicher auf!** Ohne das Passwort kannst du deine Backups nicht wiederherstellen.

Das Passwort wird gespeichert in: `~/.config/restic/password`

### 2. Erstes Backup durchführen

```bash
./macbook-backup.sh backup
```

### 3. Snapshots überprüfen

```bash
./macbook-backup.sh list
```

## Automatisierung

### Option 1: launchd (macOS)

Erstelle eine plist-Datei für automatische Backups:

`~/Library/LaunchAgents/com.user.restic-backup.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.restic-backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/seba/projects/sflab/scripts/macbook-backup.sh</string>
        <string>backup</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/restic-backup.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/restic-backup-error.log</string>
</dict>
</plist>
```

Aktivieren:

```bash
launchctl load ~/Library/LaunchAgents/com.user.restic-backup.plist
```

### Option 2: Cron

Füge zu crontab hinzu (`crontab -e`):

```bash
# Täglich um 2:00 Uhr
0 2 * * * /Users/seba/projects/sflab/scripts/macbook-backup.sh backup >> /tmp/restic-backup.log 2>&1
```

## Wiederherstellung

### Einzelne Dateien wiederherstellen

1. Starte das Skript: `./macbook-backup.sh restore`
2. Wähle einen Snapshot aus der Liste
3. Gib den Ziel-Pfad für die Wiederherstellung an

### Mount-Modus (alternativ)

Du kannst Backups auch als Dateisystem mounten und Dateien direkt kopieren:

```bash
# Setup Umgebungsvariablen
export RESTIC_REPOSITORY="sftp:rbackup@192.168.30.108:/mnt/storage/storage-share-smb/rbackup"
export RESTIC_PASSWORD_FILE="$HOME/.config/restic/password"
export RESTIC_SFTP_COMMAND="ssh rbackup@192.168.30.108 -p 22022 -i ~/.ssh/id_rsa -s sftp"

# Mount Point erstellen
mkdir -p ~/restic-mount

# Repository mounten
restic mount ~/restic-mount

# In einem anderen Terminal: Dateien browsen
cd ~/restic-mount/snapshots

# Unmount
umount ~/restic-mount
```

## Wartung

### Repository prüfen

Das Skript prüft automatisch die Repository-Integrität nach dem Pruning. Für manuelle Prüfung:

```bash
export RESTIC_REPOSITORY="sftp:rbackup@192.168.30.108:/mnt/storage/storage-share-smb/rbackup"
export RESTIC_PASSWORD_FILE="$HOME/.config/restic/password"
export RESTIC_SFTP_COMMAND="ssh rbackup@192.168.30.108 -p 22022 -i ~/.ssh/id_rsa -s sftp"

restic check
```

### Statistiken anzeigen

```bash
./macbook-backup.sh list
```

## Troubleshooting

### SSH-Verbindung schlägt fehl

```bash
# Teste SSH-Verbindung manuell
ssh -p 22022 -i ~/.ssh/id_rsa rbackup@192.168.30.108

# Prüfe SSH-Key-Berechtigungen
chmod 600 ~/.ssh/id_rsa
```

### Passwort vergessen

Ohne das Passwort können die Backups **nicht wiederhergestellt** werden. Stelle sicher, dass du das Passwort sicher aufbewahrst!

### Performance-Probleme

- Reduziere die Anzahl der zu sichernden Verzeichnisse
- Füge mehr Ausschlussmuster hinzu (z.B. große Cache-Verzeichnisse)
- Verwende einen schnelleren Netzwerk-Verbindung

## Sicherheitshinweise

1. **Passwort-Datei**: `~/.config/restic/password` hat Berechtigungen `600` (nur Besitzer lesbar)
2. **SSH-Key**: Stelle sicher, dass dein SSH-Key passwortgeschützt ist
3. **Verschlüsselung**: Alle Backups sind mit AES-256 verschlüsselt
4. **Passwort-Backup**: Bewahre das restic-Passwort an einem sicheren Ort auf (z.B. Password-Manager)

## Weitere Informationen

- [Restic Dokumentation](https://restic.readthedocs.io/)
- [Restic GitHub](https://github.com/restic/restic)
