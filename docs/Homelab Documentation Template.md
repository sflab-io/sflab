# Homelab Dokumentation

**Version:** 1.0
**Erstellt am:** 22.10.25
**Letzte Aktualisierung:** 22.10.25
**Autor:** Sebastian Freund

---

## Inhaltsverzeichnis

1. [Übersicht](#übersicht)
2. [Netzwerk-Architektur](#netzwerk-architektur)
3. [Hardware-Inventar](#hardware-inventar)
4. [Services und Anwendungen](#services-und-anwendungen)
5. [Sicherheit](#sicherheit)
6. [Backup und Disaster Recovery](#backup-und-disaster-recovery)
7. [Monitoring und Wartung](#monitoring-und-wartung)
8. [Dokumentation der Konfigurationen](#dokumentation-der-konfigurationen)
9. [Troubleshooting](#troubleshooting)
10. [Zukünftige Erweiterungen](#zukünftige-erweiterungen)

---

## 1. Übersicht

### 1.1 Zielsetzung

**Zweck des Homelabs:**
- Lernumgebung für neue Technologien
- Hosting von privaten Services
- Netzwerk-Sicherheit und Segmentierung testen
- Self-Hosting von Anwendungen

**Anforderungen:**
- [Liste die wichtigsten Anforderungen auf]
- Beispiele:
  - 24/7 Verfügbarkeit für kritische Services
  - Getrennte Netzwerke für IoT-Geräte
  - Remote-Zugriff von außerhalb

### 1.2 Architektur-Diagramm

```
[Füge hier ein ASCII-Diagramm oder Link zu einem Netzwerk-Diagramm ein]

Internet
   |
[DSL Modem] --- [Router/Firewall WAN] --- [Firewall] --- [Switch]
                                                            |- [Firewall]
                                                            |- [Access Point] [weitere Geräte]
                                                            |- [Raspberry PI]
                                                            |- [Proxmox Host]
```

### 1.3 Technologie-Stack

| Komponente | Technologie |
|------------|-------------|
| Virtualisierung | [z.B. Proxmox VE] |
| Firewall | [z.B. OPNsense] |
| DNS | [z.B. Pi-hole, AdguardHome, BIND9, Unbound] |
<!--| Reverse Proxy | [z.B. Nginx, Traefik] |-->
<!--| Container | [z.B. Docker, LXC] |-->
<!--| Backup | [z.B. Proxmox Backup Server] |-->
<!--| Monitoring | [z.B. Prometheus, Grafana] |-->

---

## 2. Netzwerk-Architektur

### 2.1 VLAN-Übersicht

| VLAN Name  | VLAN ID | Subnetz         | Gateway      | Zweck                | DHCP-Range |
|------------|---------|-----------------|--------------|----------------------|------------|
| Management | 1       | 192.168.1.0/24  | 192.168.1.1  | Infrastruktur-Geräte | [Range]    |
| User       | 10      | 192.168.10.0/24 | 192.168.10.1 | Arbeitsgeräte        | [Range]    |
| IoT        | 20      | 192.168.20.0/24 | 192.168.20.1 | Smart-Home-Geräte    | [Range]    |
| Guest      | 30      | 192.168.30.0/24 | 192.168.30.1 | Gast-WLAN            | [Range]    |

### 2.2 Firewall-Regeln

#### Inter-VLAN Routing

| Von VLAN   | Zu VLAN        | Erlaubte Dienste | Beschreibung                                    |
|------------|----------------|------------------|-------------------------------------------------|
| User (10)  | Management (1) | SSH, HTTPS       | Admin-Zugriff auf Infrastruktur                 |
| User (10)  | IoT (20)       | HTTP, HTTPS      | Zugriff auf IoT Web-Interfaces                  |
| IoT (20)   | User (10)      | VERWEIGERT       | IoT-Geräte dürfen nicht auf User-Netz zugreifen |
| Guest (30) | ALLE           | VERWEIGERT       | Nur Internet-Zugriff                            |

#### WAN-Regeln

- **Eingehend:** [Beschreibe eingehende Regeln]
  - Port 443: Reverse Proxy für Services
  - Port [weitere Ports]
- **Ausgehend:** [Beschreibe ausgehende Regeln]
  - Standard: Erlaubt
  - Blockiert: [spezifische Ports/Services]

### 2.3 DNS-Konfiguration

**Primary DNS Server:**
- Hostname: [Name]
- IP-Adresse: [IP]
- Software: [z.B. BIND9, Pi-hole]

**DNS-Zonen:**
```
# Interne Zone
home.sflab.io    -> [IP des DNS Servers]

# A-Records
router.homelab.local     -> 192.168.1.1
proxmox.homelab.local    -> 192.168.1.12
nas.homelab.local        -> [IP]
```

**Forwarders:**
- Primär: [z.B. 1.1.1.1]
- Sekundär: [z.B. 8.8.8.8]

### 2.4 DHCP-Konfiguration

**DHCP Server:** [Gerät, das DHCP bereitstellt]

**Statische Leases:**

| Hostname | MAC-Adresse | IP-Adresse | VLAN   | Beschreibung   |
|----------|-------------|------------|--------|----------------|
| [Name]   | [MAC]       | [IP]       | [VLAN] | [Beschreibung] |

**Dynamische Pools:**

| VLAN       | Pool-Start     | Pool-Ende      | Lease-Zeit |
|------------|----------------|----------------|------------|
| User (10)  | 192.168.10.100 | 192.168.10.200 | 24h        |
| IoT (20)   | 192.168.20.100 | 192.168.20.200 | 24h        |
| Guest (30) | 192.168.30.100 | 192.168.30.200 | 2h         |

---

## 3. Hardware-Inventar

### 3.1 Netzwerk-Hardware

#### Router/Firewall
- **Gerät:** [Modell]
- **Hardware-Specs:**
  - CPU: [Details]
  - RAM: [Größe]
  - Storage: [Größe und Typ]
- **Netzwerk-Interfaces:**
  - WAN: [Interface, IP]
  - LAN: [Interface, IP]
- **Software:** [z.B. OPNsense, Version]
- **Seriennummer:** [Nummer]
- **Anschaffungsdatum:** [Datum]
- **Garantie bis:** [Datum]

#### Switch(es)
- **Gerät:** [Modell]
- **Anzahl Ports:** [Anzahl]
- **PoE-fähig:** [Ja/Nein, Watt]
- **Management:** [Managed/Unmanaged]
- **IP-Adresse:** [IP]
- **Port-Belegung:**

| Port | Verbunden mit | VLAN | Beschreibung |
|------|---------------|------|--------------|
| 1 | Router (LAN) | Trunk (All) | Uplink |
| 2 | Access Point | Trunk (10,30) | WLAN |
| 3 | Proxmox Host | Trunk (All) | Virtualisierung |
| 4 | NAS | 1 | Storage |
| 5 | DNS Server | 1 | DNS/DHCP |
| 6-8 | [Frei] | - | Reserve |

#### Wireless Access Point(s)
- **Gerät:** [Modell]
- **IP-Adresse:** [IP]
- **SSIDs:**

| SSID | VLAN | Sicherheit | Passwort-Hinweis |
|------|------|------------|------------------|
| [Name] | 10 | WPA3 | [Ort des Passworts] |
| [Name]-Guest | 30 | WPA3 | [Ort des Passworts] |

### 3.2 Server-Hardware

#### Proxmox Host
- **Gerät:** [Modell]
- **Hardware-Specs:**
  - CPU: [Modell, Kerne, Threads]
  - RAM: [Größe, Typ, MHz]
  - Storage:
    - System: [Typ, Größe]
    - VM Storage: [Typ, Größe]
  - Netzwerk: [Anzahl NICs, Geschwindigkeit]
- **IPMI/iLO:**
  - IP-Adresse: [IP]
  - Zugang: [Hinweis auf Passwort-Speicherort]
- **BIOS-Version:** [Version]
- **Proxmox Version:** [Version]

#### NAS (falls vorhanden)
- **Gerät:** [Modell]
- **Laufwerke:**
  - Anzahl: [Anzahl]
  - Typ: [HDD/SSD]
  - Größe: [pro Laufwerk]
  - RAID-Level: [Level]
  - Nutzbare Kapazität: [Gesamt]

### 3.3 Weitere Geräte

#### DNS/DHCP Server
- **Gerät:** [z.B. Raspberry Pi 5]
- **IP-Adresse:** [IP]
- **Funktion:** Primary DNS, DHCP
- **Software:** [z.B. BIND9, Pi-hole]

#### Zusätzliche Geräte
- [Liste weitere Geräte auf]

### 3.4 Client-Geräte

#### Workstations
- **Gerät:** [Modell]
- **Netzwerk:**
  - Kabelgebunden: [IP, VLAN]
  - WLAN: [IP, VLAN, SSID]

#### Mobile Geräte
- [Liste auf, falls relevant für statische Leases]

#### IoT-Geräte
- [Liste Smart-Home-Geräte auf]
  - Smart Home Bridge: [Modell, IP]
  - Smart Speakers: [Anzahl, Modell]
  - Smart TV: [Modell, IP]
  - [weitere]

---

## 4. Services und Anwendungen

### 4.1 Virtuelle Maschinen

| VM-ID | Name | OS | vCPU | RAM | Storage | IP-Adresse | VLAN | Zweck | Autostart |
|-------|------|----|----|-----|---------|------------|------|-------|-----------|
| [ID] | [Name] | [OS] | [Kerne] | [GB] | [GB] | [IP] | [VLAN] | [Beschreibung] | [Ja/Nein] |

### 4.2 Container (LXC/Docker)

| Container-ID | Name | Typ | RAM | Storage | IP-Adresse | VLAN | Zweck | Autostart |
|--------------|------|-----|-----|---------|------------|------|-------|-----------|
| [ID] | [Name] | [LXC/Docker] | [GB] | [GB] | [IP] | [VLAN] | [Beschreibung] | [Ja/Nein] |

### 4.3 Service-Details

#### [Service Name 1]
- **Typ:** [VM/Container/Bare Metal]
- **Hostname:** [Name]
- **IP-Adresse:** [IP]
- **Port(s):** [Ports]
- **URL:** [falls zutreffend]
- **Zweck:** [Beschreibung]
- **Zugriff:**
  - Intern: [ja/nein]
  - Extern: [ja/nein, wie]
- **Authentifizierung:** [Methode]
- **Backup:** [ja/nein, wie oft]
- **Abhängigkeiten:** [andere Services]
- **Konfigurationsdateien:** [Speicherort]

#### [Service Name 2]
[Wiederhole die Struktur für jeden Service]

### 4.4 Reverse Proxy Konfiguration

**Reverse Proxy:** [z.B. Nginx Proxy Manager, Traefik]
- **IP-Adresse:** [IP]
- **Management-URL:** [URL]

**Proxy-Hosts:**

| Domain/Subdomain | Ziel-IP | Ziel-Port | SSL | Beschreibung |
|------------------|---------|-----------|-----|--------------|
| [domain.com] | [IP] | [Port] | [ja/nein] | [Service] |

---

## 5. Sicherheit

### 5.1 Zugriffskontrolle

#### Passwort-Management
- **Passwort-Manager:** [Tool]
- **Speicherort:** [Hinweis]
- **Passwort-Policy:**
  - Mindestlänge: [Anzahl Zeichen]
  - Komplexität: [Anforderungen]
  - Rotation: [Intervall]

#### SSH-Konfiguration
- **SSH-Keys:** [Speicherort]
- **SSH-Zugriff:**
  - Root-Login: [erlaubt/verboten]
  - Passwort-Auth: [aktiviert/deaktiviert]
  - Key-Only: [ja/nein]
  - Port: [Standard/Custom]

#### VPN-Zugriff
- **VPN-Typ:** [z.B. WireGuard, OpenVPN]
- **Server-IP:** [IP]
- **Port:** [Port]
- **Client-Konfigurationen:** [Speicherort]

### 5.2 Firewall-Strategie

**Default Policy:**
- Inter-VLAN: Deny All (Whitelist-Ansatz)
- WAN Ingress: Deny All
- WAN Egress: Allow All

**Logging:**
- Geblockte Verbindungen: [ja/nein]
- Log-Speicherort: [Ort]
- Log-Rotation: [Intervall]

### 5.3 Updates und Patches

| System | Update-Strategie | Letztes Update | Geplantes Update |
|--------|------------------|----------------|------------------|
| Proxmox | [monatlich/bei Bedarf] | [Datum] | [Datum] |
| OPNsense | [automatisch/manuell] | [Datum] | [Datum] |
| VMs | [je nach Service] | [Datum] | [Datum] |

---

## 6. Backup und Disaster Recovery

### 6.1 Backup-Strategie

**3-2-1 Regel:**
- 3 Kopien der Daten
- 2 verschiedene Medien
- 1 Kopie offsite

**Backup-Zeitplan:**

| System | Typ | Häufigkeit | Aufbewahrung | Speicherort | Letztes Backup |
|--------|-----|------------|--------------|-------------|----------------|
| Proxmox VMs | [Full/Incremental] | [täglich/wöchentlich] | [Tage] | [Ort] | [Datum] |
| Konfigurationen | [Export] | [wöchentlich] | [unbegrenzt] | [Git-Repo] | [Datum] |
| NAS-Daten | [Snapshot/Rsync] | [täglich] | [Tage] | [Ort] | [Datum] |

### 6.2 Backup-Verifizierung

- **Test-Restores:** [Häufigkeit]
- **Letzter Test:** [Datum]
- **Ergebnis:** [Erfolgreich/Fehlgeschlagen]

### 6.3 Disaster Recovery Plan

#### Kritische Services (Priorität 1)
1. [Service Name] - RTO: [Zeit], RPO: [Zeit]
2. [Service Name] - RTO: [Zeit], RPO: [Zeit]

#### Wichtige Services (Priorität 2)
1. [Service Name] - RTO: [Zeit], RPO: [Zeit]

#### Optionale Services (Priorität 3)
1. [Service Name] - RTO: [Zeit], RPO: [Zeit]

#### Recovery-Schritte

**Kompletter Hardware-Ausfall:**
1. [Schritt 1]
2. [Schritt 2]
3. [...]

**Einzelne VM/Container Ausfall:**
1. [Schritt 1]
2. [Schritt 2]
3. [...]

**Netzwerk-Ausfall:**
1. [Schritt 1]
2. [Schritt 2]
3. [...]

---

## 7. Monitoring und Wartung

### 7.1 Monitoring-Tools

**Monitoring-Stack:**
- **Tool:** [z.B. Prometheus + Grafana]
- **Dashboard-URL:** [URL]
- **Metriken:**
  - CPU-Auslastung
  - RAM-Nutzung
  - Storage-Kapazität
  - Netzwerk-Traffic
  - Service-Verfügbarkeit

**Alert-Konfiguration:**

| Alert | Schwellwert | Benachrichtigung | Empfänger |
|-------|-------------|------------------|-----------|
| CPU > 80% | 80% | [E-Mail/Telegram] | [Empfänger] |
| RAM > 90% | 90% | [E-Mail/Telegram] | [Empfänger] |
| Storage > 85% | 85% | [E-Mail/Telegram] | [Empfänger] |
| Service Down | - | [E-Mail/Telegram] | [Empfänger] |

### 7.2 Wartungsplan

**Regelmäßige Aufgaben:**

| Aufgabe | Häufigkeit | Verantwortlich | Letzte Durchführung |
|---------|------------|----------------|---------------------|
| System-Updates | [Intervall] | [Person] | [Datum] |
| Backup-Verifizierung | [Intervall] | [Person] | [Datum] |
| Log-Review | [Intervall] | [Person] | [Datum] |
| Zertifikat-Erneuerung | [bei Bedarf] | [Person] | [Datum] |
| Hardware-Reinigung | [Intervall] | [Person] | [Datum] |

### 7.3 Log-Management

**Zentrale Logs:**
- **Log-Server:** [IP/Hostname]
- **Log-Tool:** [z.B. Graylog, ELK]
- **Retention:** [Tage]

**Wichtige Log-Dateien:**

| System | Log-Pfad | Zweck |
|--------|----------|-------|
| Proxmox | /var/log/pve/ | System-Logs |
| OPNsense | /var/log/ | Firewall-Logs |
| [Service] | [Pfad] | [Zweck] |

---

## 8. Dokumentation der Konfigurationen

### 8.1 Konfigurations-Backup

**Git-Repository:**
- **Repository-URL:** [URL]
- **Lokaler Pfad:** [Pfad]
- **Gesicherte Konfigurationen:**
  - `/etc/` Verzeichnisse
  - Docker Compose Files
  - Firewall-Regeln Export
  - [weitere]

### 8.2 Wichtige Konfigurationsdateien

| System | Datei | Pfad | Beschreibung |
|--------|-------|------|--------------|
| [System] | [Dateiname] | [Pfad] | [Beschreibung] |

### 8.3 Netzwerk-Diagramme

- **Physische Topologie:** [Speicherort/Link]
- **Logische Topologie:** [Speicherort/Link]
- **VLAN-Diagramm:** [Speicherort/Link]
- **Rack-Layout:** [Speicherort/Link] (falls zutreffend)

---

## 9. Troubleshooting

### 9.1 Häufige Probleme

#### Kein Internet-Zugriff
**Symptome:** [Beschreibung]
**Diagnose:**
```bash
# Befehle zur Diagnose
ping 8.8.8.8
traceroute google.com
```
**Lösung:** [Schritte zur Behebung]

#### VM startet nicht
**Symptome:** [Beschreibung]
**Diagnose:** [Schritte]
**Lösung:** [Schritte zur Behebung]

#### [Weiteres Problem]
**Symptome:** [Beschreibung]
**Diagnose:** [Schritte]
**Lösung:** [Schritte zur Behebung]

### 9.2 Nützliche Befehle

```bash
# Netzwerk-Diagnose
ip addr show
ip route show
ping -c 4 [IP]
traceroute [IP/Domain]
nslookup [Domain]
tcpdump -i [Interface]

# Proxmox
pct list                    # Container auflisten
qm list                     # VMs auflisten
pvesm status                # Storage Status
pveversion                  # Version anzeigen

# System
htop                        # Prozesse anzeigen
df -h                       # Speicherplatz
free -h                     # RAM-Nutzung
systemctl status [service]  # Service-Status
journalctl -u [service]     # Service-Logs
```

### 9.3 Kontakte und Support

| Kategorie | Kontakt | Telefon | E-Mail | Verfügbarkeit |
|-----------|---------|---------|--------|---------------|
| ISP | [Name] | [Nummer] | [E-Mail] | [Zeiten] |
| Hardware-Vendor | [Name] | [Nummer] | [E-Mail] | [Zeiten] |
| [Community/Forum] | - | - | [Link] | [24/7] |

---

## 10. Zukünftige Erweiterungen

### 10.1 Geplante Projekte

#### Kurzfristig (0-3 Monate)
- [ ] IoT-Geräte in separates VLAN (20) verschieben
- [ ] [Weiteres Projekt]
- [ ] [Weiteres Projekt]

#### Mittelfristig (3-12 Monate)
- [ ] [Projekt]
- [ ] [Projekt]
- [ ] [Projekt]

#### Langfristig (12+ Monate)
- [ ] [Projekt]
- [ ] [Projekt]
- [ ] [Projekt]

### 10.2 Hardware-Upgrades

| Komponente | Aktuell | Geplant | Grund | Kosten (ca.) | Zeitrahmen |
|------------|---------|---------|-------|--------------|------------|
| [Teil] | [Spec] | [Spec] | [Grund] | [EUR] | [Datum] |

### 10.3 Software/Services

| Service | Zweck | Priorität | Status | Geplant für |
|---------|-------|-----------|--------|-------------|
| [Name] | [Beschreibung] | [Hoch/Mittel/Niedrig] | [Geplant] | [Datum] |

### 10.4 Lernziele

- [ ] [Technologie/Skill]
- [ ] [Technologie/Skill]
- [ ] [Technologie/Skill]

---

## Anhang

### A. Glossar

| Begriff | Bedeutung |
|---------|-----------|
| VLAN | Virtual Local Area Network |
| DHCP | Dynamic Host Configuration Protocol |
| DNS | Domain Name System |
| [weiterer Begriff] | [Bedeutung] |

### B. Referenzen

- [Herstellerdokumentation]
- [Tutorial-Links]
- [Community-Ressourcen]

### C. Änderungshistorie

| Datum | Version | Änderung | Autor |
|-------|---------|----------|-------|
| [Datum] | 1.0 | Initiale Dokumentation | [Name] |
| [Datum] | [Version] | [Änderung] | [Name] |

---

**Notizen:**
- Dieses Template ist als Ausgangspunkt gedacht und sollte an die individuellen Bedürfnisse angepasst werden
- Sensible Informationen (Passwörter, externe IPs) sollten NICHT in dieser Dokumentation gespeichert werden
- Halte die Dokumentation aktuell - dokumentiere Änderungen zeitnah
- Backup dieser Dokumentation nicht vergessen!
