# Homelab

## Uebersicht

In diesem Dokument wird die Architektur und die Komponenten meines Homelabs beschrieben. Ziel ist es, eine modulare und skalierbare Umgebung zu schaffen, die sowohl fuer Entwicklungs- als auch fuer Produktionszwecke genutzt werden kann.

## Komponenten

### **DSL Modem**

Das DSL Modem stellt die Verbindung zum Internet ueber meinen Internetanbieter her.

Geraet: Speedport Smart 4<br>
Ipv4 : 192.168.178.1

### **Router / Firewall**

Die Opnsense Router und Firewall ist verantwortlich fuer die Verwaltung des Datenverkehrs und den Schutz des Netzwerks.

Geraet: Protectli FW4C-0-8-120

- WAN-Schnittstelle: Verbindung zum Internet und anderen externen Netzwerken.

  Network Interface: igc0

  Ipv4: 192.168.178.30

  Das DSL Modem ist mit dem WAN Port per Netzwerkkabel verbunden.

- LAN-Schnittstelle: Verbindung zum internen Netzwerk und den Homelab-Komponenten.

  Network Interface: igc1

  Ipv4: 192.168.1.1

### **Wireless Access Point**

Geraet: Netgear WAX210

Ipv4: 192.168.1.11

WLAN SSID: LAN Solo (VLAN 10)<br>
WLAN SSID: LAN Solo Guest (VLAN 30)

### **BIND 9 DNS**

Wird als Primary DNS Server fuer das Homelab verwendet.

Geraet: Raspberry Pi 5

Ipv4: 192.168.1.12

### **Proxmox VE**

Wird als Virtualisierungsplattform fuer das Homelab verwendet.

Geraet: Minisforum MS-01

Netz Interfaces:

- enp88s0 (Management Interface, VLAN-Aware)

Linux Bridges:

- vmbr0

  bridge ports: enp88s0<br>
  Ipv4: 192.168.1.12/24<br>
  Gateway: 192.168.1.1<br>

## **Workstation**

Geraet: Macbook Pro 2021

Netz Interfaces:

- en10: 192.168.1.30, Kabelgebunden, VLAN 1, statische IP
- en0: 192.168.10.106, WLAN, LAN Solo (VLAN 10), DHCP with static lease

## **Handy**

Eingebunden per WLAN im VLAN 10 (LAN Solo), DHCP

Geraet: iPhone 13
Ipv4: 192.168.10.102

### **IoT Bridge**

Die IoT Bridge verbindet verschiedene Phillips IoT-Geraete mit dem Netzwerk.

Geraet: Phillips Hue Bridge

### **IoT Geraete**

- Home Pod Mini, LAN Solo (VLAN 10)
- Home Pod 2, LAN Solo (VLAN 10)
- Wohnzimmer TV (Sony), LAN Solo (VLAN 10)

Aktuell befinden sich die IoT Geraete im gleichen VLAN wie die Workstation.
Aus Sicherheitsgruenden ist dies nicht optimal.
In Zukunft sollen die IoT Geraete in ein separates VLAN (VLAN 20) verschoben werden, um die Sicherheit zu erhoehen.

### **Netzwerk Switch**

Der Netzwerk Switch verbindet alle Geraete im internen Netzwerk miteinander und ermoeglicht die Kommunikation zwischen ihnen.

Geraet: Netgear GS108Ev4

Ipv4: 192.168.1.10

Port 1: LAN Verbindung zum Router/Firewall (igc1)<br>
Port 2: Verbindung zum Wireless Access Point (WAX210)<br>
Port 3: Verbindung zum Raspberry Pi 5<br>
Port 4: Verbindung zum Minisforum MS-01 Proxmox VE (enp88s0 / vmbr0)<br>
Port 5: Macbook Pro 21<br>
Port 6: Freier Port<br>
Port 7: Freier Port<br>
Port 8: Freier Port<br>

## VLAN Netzarchitektur

| Zweck          | VLAN ID | Subnetz         |
| -------------- | ------- | --------------- |
| **Management** | 1       | 192.168.1.0/24  |
| **USER**       | 10      | 192.168.10.0/24 |
| **IoT**        | 20      | 192.168.20.0/24 |
| **Guest**      | 30      | 192.168.30.0/24 |
