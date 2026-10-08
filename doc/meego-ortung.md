# N950 — Ortung für einen selbstgebauten MeeGo-Port

Gerät: **RM680 = N950**, MeeGo 1.2 Harmattan, Kernel 2.6.32.54, armv7l, Qt **4.7.4**.
Aegis: `Current mode: open`. Zugang: Hotspot `user@172.28.172.2`.

**Wichtig vorweg:** Die Hotspot-WLAN der Jolla (`wlan0`) ging **mitten in der Messung
aus** (jetzt `state DOWN`, Jolla nur noch auf Mobilfunk `ccmni2`). Danach war die N950
weder über `172.28.172.2` noch über `192.168.1.8` erreichbar. Der **Live-Ortungsversuch
(Punkt 2) konnte nicht mehr laufen**; die Kernaussage steht trotzdem fest, weil sie aus
den D-Bus-Policies und der gemessenen Kennung der ssh-Shell folgt (die Policy ist die
Durchsetzung, nicht eine Vermutung). Was offen blieb, steht unten in „Offen".

---

## Kernaussage (teils gemessen, teils gefolgert)

**Gemessen:** Die Sitzungsbus-Policy für `com.nokia.positioningd.client` ist
**default-deny** auf der Schnittstelle `com.nokia.positioningd.client` und nur für
`creds="Location"` erlaubt. **Gemessen:** Ein Prozess ohne Manifest/ohne Token (die
ssh-Shell) trägt **kein** `Location`.

**Gefolgert** (nicht live beobachtet): Ein selbstgebautes Programm mit dieser
Token-losen Kennung bekommt beim ersten `send` an `com.nokia.positioningd.client`
`org.freedesktop.DBus.Error.AccessDenied` vom **dbus-daemon**, bevor positioningd die
Anfrage sieht — also **„Dienst verweigert" auf Bus-Ebene**, unabhängig vom GPS-Empfang,
auch im Freien. Dass QtMobility `PositionSource` **genau diese** Schnittstelle benutzt,
ist gefolgert aus (a) der Policy, die sie als Client-Schnittstelle benennt, und (b) den
drei lebenden `com.nokia.qlocation.I…`-Namen auf dem Sitzungsbus (Rückrufnamen aktiver
QtLocation-Clients) — der direkte Beleg via `strings libQtLocation` brach mit der
Verbindung ab (siehe „Offen").

**Einschränkung:** `deny send_interface=X` trifft nur Nachrichten mit **exakt** dieser
Schnittstelle. Benutzt das QtLocation-Plugin intern eine andere Schnittstelle, griffe
die Sperre nicht — deshalb ist der `strings`-Check offen und der Live-Lauf der sauberste
Beweis.

### Beleg 1 — Kennung der ssh-Shell (`accli -I`)
```
Current mode: open
Credentials:
    UID::user  GID::users
    GRP::adm  GRP::dialout  GRP::pulse-access  GRP::users  GRP::input
```
Kein `Location`, kein `LocationFW`, kein `LocationControl`. Das misst **einen Prozess
ohne Manifest/ohne Token**. Ob ein per `aegis-dpkg` installiertes Paket mit einem
`Location` **anfordernden** Manifest dieses Token doch erhält, ist damit **nicht**
beantwortet (siehe Punkt 3) — das Request-Token `Location` ist eine andere Klasse als
die in der Erinnerung gemessenen `CAP::`-Capabilities.

### Beleg 2 — D-Bus-Policy `/etc/dbus-1/session.d/aegis.positioningd.conf`
```
<policy context="default">
  <deny send_destination="com.nokia.positioningd.client"
        send_interface="com.nokia.positioningd.client"/>
</policy>
<policy creds="Location">
  <allow send_destination="com.nokia.positioningd.client"
         send_interface="com.nokia.positioningd.client"/>
</policy>
```
(Analog verlangt `com.nokia.positioningd.settings` die Kennung
`positioningd::LocationControl`.) Das System-Gegenstück `nped_dbus.conf`/
`aegis.npe-maemo0.conf` schützt `com.nokia.location.nped` hinter
`npe-maemo0::LocationFW`; positioningd selbst hält diese Kennung und vermittelt — die
Hürde für uns liegt also allein am Client→positioningd-Übergang.

---

## 1. Ortungs-Grundlage auf dem Gerät (gemessen)

**Pakete** (`dpkg -l`):
- `libqtm-location 1.2.1+213+0m8` — Qt-Mobility-Location-Modul (das, was der Port nutzt)
- `positioningd 0.8.9` — Positionsdienst (läuft, pid 1013, als `user`)
- `npe-maemo0 0.30` — Nokia Positioning Engine; `nped` läuft (pids 1335/1381, als `location`)
- `gypsy-daemon 0.7-5` — installiert, **läuft nicht** (nicht in `ps`)
- `liblocationextras 0.0.21`, `liblocationpicker 0.6.1`, `location-ui 1.2`,
  `locationsettings 2.7`, `location-settings-dadd`
- **`gpscon 0.0.12ham1`** — vom Nutzer installiertes GPS-Konsolenprogramm, liegt in
  `/opt/gpscon/bin/gpscon` (Paket vom März 2026)
- `calendarfeed-location-mod` (unabhängig)
- **Kein** `liblocation0` (die alte Maemo-5-API), nur `-extras`/`-picker`.

**Bibliotheken:**
- `/usr/lib/libQtLocation.so.1.2.1` (Symlinks `.1`, `.1.2`)
- `/usr/lib/liblocationextras.so.1.0.0`, `/usr/lib/liblocationpicker.so.0.6.1`

**QML-Module** (`/usr/lib/qt4/imports/`):
- `QtMobility/location/` → `libdeclarative_location.so` + `qmldir`
  (`qmldir`: `plugin declarative_location`) → nutzbar als `import QtMobility.location 1.2`
- weitere QtMobility-Module: connectivity, contacts, feedback, gallery, messaging,
  organizer, publishsubscribe, sensors, serviceframework, systeminfo
- unter `com/nokia/`: OMB, OviNotifications, controlpanel, extras, **meego**, odml
- **Keine** `qmlviewer`/`qmlscene`/`qml`-Binärdateien vorhanden → Offscreen-QML-Probe
  braucht PySide (QtDeclarative), nicht qmlscene.

**D-Bus-Namen (live):**
- Systembus: `com.nokia.location.nped`, `com.nokia.positioningd.odnp`
- Sitzungsbus: `com.nokia.positioningd.client`, `.context`, `.settings` und **drei
  aktive** `com.nokia.qlocation.I…`-Clients (laufende QtLocation-Verbraucher)
- Service-Dateien: `com.nokia.positioningd.client.service`
  (`Exec=/usr/bin/positioningd`), `.context`, `.settings`, `com.nokia.location.ui`,
  System: `odnpd`, `slpgwd`, `fpcd`, `positioningd.odnp`

**GPS-Knoten:** `/dev/bcm4751-gps  crw-rw----  root location` (Broadcom BCM4751).
**Kein** `/dev/ttyGPS*`, **kein** `/dev/gps` — also kein NMEA-tty, sondern der
Broadcom-Chipknoten, den `nped` hält. Für `user` nicht les-/schreibbar (user nicht in
Gruppe `location`, gid 30023; die Gruppe ist leer, `nped` läuft als Benutzer `location`).

---

## 2. Der entscheidende Versuch — NICHT ausgeführt (Verbindung weg)

Geplant war eine PySide-Offscreen-Probe (`import QtMobility.location 1.2;
PositionSource{active:true}`, `QApplication` ohne Fenster, Timeout ~60 s) mit
`dbus-monitor --session` nebenher, um „AccessDenied vom Bus" sauber von „keine Position
trotz durchgelassener Anfrage" zu trennen. Die Jolla-Hotspot-WLAN fiel aus, bevor die
Probe lief.

**Was ohne Live-Lauf feststeht (gefolgert):** Der Ausgang ist durch die Policy
determiniert — `PositionSource` ohne `Location`-Kennung bekommt `AccessDenied` beim
ersten `send` an `com.nokia.positioningd.client`; das ist **„verweigert", nicht „kein
Empfang"**. **Vermutung** (nicht gemessen, auch nicht quellenbelegt): wie QtMobility den
Busfehler nach oben meldet — vermutlich als ungültige Quelle / ausbleibende
`positionChanged`-Signale statt als geworfener Fehler.

**Was ein Live-Lauf noch gebracht hätte** (offen): die exakte Fehlersignatur, die
Reaktion von QtMobility darauf, und — falls wider Erwarten durchgelassen — Empfang/
Fix-Zeit. Drinnen hätte ohnehin höchstens die Netzortung (nped/odnp) grob geliefert.

---

## 3. Wege, falls verweigert — geprüft auf vorhandene Mittel

Rangfolge nach dem, was auf dem Gerät **existiert**:

1. **gpscon als Existenzbeweis zuerst nachmessen (aussichtsreichster Erkenntnisgewinn).**
   `/opt/gpscon/bin/gpscon` ist ein **nicht von Nokia stammendes** GPS-Programm, das der
   Nutzer per `aegis-dpkg` installiert hat und das vermutlich GPS bekommt. Wenn ja, trägt
   sein Binary nachweislich die nötige Kennung — dann ist der Weg „eigenes Paket **mit
   korrektem aegis-Manifest, per `aegis-dpkg` installiert**" doch gangbar, und die
   pauschale Aussage „Location bringt bei selbstgebauten Paketen nichts" wäre auf
   „nichts **ohne** passende Herkunft/Manifest" zu präzisieren. **Zu messen:**
   `accli -F /opt/gpscon/bin/gpscon` (welche Credentials das Binary deklariert) und ein
   kurzer `gpscon`-Lauf (kommt ein Fix?). Das beantwortet Punkt 3 direkter als jede
   Vermutung. *(diese Sitzung nicht gemessen)*

   Auf dem Gerät stehen zwei Gegenkandidaten zur pauschalen „Location geht nicht"-These:
   `gpscon 0.0.12ham1` **und** `calendarfeed-location-mod 0.4.3` — beides Community-Pakete
   mit Ortungsbezug. Bekommt eines davon eine Position, hat ein unsigniertes Paket die
   nötige Kennung erhalten.

2. **Privilegierter Helfer, der die Ortung hält, + eigener Socket zur UI.** Robustes
   Muster, deckt sich mit den Daemons des Nutzers (knopfwacht, brücke, Rust-Daemons via
   Sitzungsbus). **Bedingung aus der Erinnerung** (aegis-fremde-herkunft /
   aegis-keine-faehigkeiten-selbstgebaut): Rechte holt **nur** `sudo` **und nur bei
   Herkunft aus `aegis-dpkg`** — ein loses Binary in `/home/user` unter `sudo` reicht
   also **nicht**; der Helfer muss **paketiert und per `aegis-dpkg -i` installiert** sein.
   `opensh` existiert laut Erinnerung auf keinem der Geräte. Vorhanden sind `sudo`
   (N950: passwortlos bestätigt) und `/usr/bin/aegis-exec`. **Noch zu bestätigen:** ob
   `aegis-exec`/`sudo` im Open-Mode die `Location`-Kennung an das Kind vergibt. *(nicht
   gemessen)*

3. **aegis-Manifest mit `Location` im eigenen Paket** — die Auftragsbehauptung „bringt
   bei selbstgebauten Paketen nichts, nachgemessen" bezieht sich laut Erinnerung
   (aegis-keine-faehigkeiten-selbstgebaut) auf **`CAP::`** (POSIX-Capabilities). Für das
   **Request-Token `Location`** (andere Klasse) ist der Nachweis **offen**; Punkt 1
   (gpscon / calendarfeed-location-mod) entscheidet das direkt. Nicht erneut die
   `CAP::`-Falle messen.

4. **Direkt `/dev/bcm4751-gps`** — `root:location`, `crw-rw----`, Broadcom-Binärprotokoll
   (kein NMEA), wird von `nped` gehalten. Als `user` nicht zu öffnen; als root/`location`
   möglich, aber Protokoll-Reverse-Engineering und Konflikt mit nped. **Verworfen.**

**Aussichtsreichster Weg:** erst **gpscon** (und `calendarfeed-location-mod`) nachmessen
(Punkt 1). Zeigt eines GPS, dann ein eigenes Paket mit demselben Manifest/Herkunftsweg
(per `aegis-dpkg`) bzw. ein kleiner, ebenso installierter Location-Helfer (Punkt 2); der
Port selbst bleibt unprivilegiert und bezieht die Position vom Helfer.

---

## 4. Nebenbefunde

- **Blanco-Icon-Maske:** `/usr/share/themes/blanco/meegotouch/icons/icon-l-*.png`
  vorhanden (z. B. `icon-l-accounts.png`, `icon-l-browser.png` …) — Vorlage da.
- **Qt-Fassung:** `qmake` als `user` **nicht gefunden** (keine Qt-Dev-Tools installiert);
  Laufzeit **Qt 4.7.4** steht aus `dpkg` fest (`libqtcore4 4.7.4~git20120327-0maemo1+0m8`,
  `libQtCore.so.4.7.4`).
- **QML unter `com/nokia/`:** OMB, OviNotifications, controlpanel, extras, meego, odml.
- **Freier Speicher:** `/` 1,6 G frei (57 % belegt), `/home` 459 M frei (76 %),
  `/tmp` tmpfs **nur 4 M**, `/dev/shm` 64 M, `/home/user/MyDocs` (vfat, noexec) 1,0 G frei.
- **Ortungseinstellungen:** `df` zeigt ein `aegisfs` auf `/home/user/.positioningd/private`
  (dazu `.odnp`, `.odnp-fpcd`, `.slpgwd`). **Vermutung:** die Ortungs-Ein/Aus- und
  SUPL-Einstellungen liegen dort (aegis-geschützt), nicht in gconf — das erklärt den
  leeren `gconftool-2 -R /system/nokia/location`-Lauf.
- **mcetool:** `which mcetool` als `user` leer; `/usr/sbin` diese Sitzung nicht geprüft.
  Laut früherer Messung (n950-anruf-audio: `mcetool --block`) existiert es auf der N950 —
  wahrscheinlich `/usr/sbin/mcetool`. *(diese Sitzung nicht bestätigt)*
- **Werkzeuge vorhanden:** `python2.6`, `python3.11`, `python-dbus 0.83.1`; aegis-Satz
  inkl. `accli`, `aegis-exec`, `aegis-dpkg`, `invoker`. `qmlscene`/`qmlviewer` **fehlen**.

---

## Offen (durch Hotspot-Ausfall abgebrochen)

- **Schärfster Test — lebende Clients auflösen:** die drei `com.nokia.qlocation.I…`-Namen
  per `dbus-send --session --dest=org.freedesktop.DBus / org.freedesktop.DBus.GetConnectionUnixProcessID string:<name>`
  zu PIDs auflösen, dann `ps`, `dpkg -S <binary>` und `accli -p <pid>` (als root). Das
  zeigt Prozesse, die **gerade jetzt** durch die Policy kommen, und aus welchem Paket mit
  welcher Herkunft — beantwortet Punkt 2/3 direkter als jede Vermutung.
- **`accli -F /opt/gpscon/bin/gpscon`** + kurzer gpscon-Lauf (und dasselbe für
  `calendarfeed-location-mod`) — Existenzbeweis „nicht-Nokia-Paket bekommt GPS".
- **Live-PositionSource-Probe** mit `dbus-monitor --session`-Mitschnitt — direkte
  Beobachtung von AccessDenied vs. Empfang/Timing; braucht PySide (kein qmlscene).
- **`strings /usr/lib/libQtLocation.so.1.2.1`** nach `com.nokia.positioningd`/`/com/nokia`
  — bestätigt, dass das Plugin wirklich `com.nokia.positioningd.client` ruft (sonst
  griffe die `send_interface`-Sperre nicht).
- **`accli -p 1013`/`-p 1335`** (Kennungen positioningd/nped) — als root geplant,
  Hintergrund-Lauf hing an der ersten PID und brach mit dem Verbindungsabbruch ab (nur
  Teilausgabe). **Nächstes Mal:** einzeln bzw. mit `timeout` davor, nicht fünf `accli`
  in einem Skript.
- **PySide-QtDeclarative-Verfügbarkeit** (`python -c "from PySide import QtDeclarative,
  QtGui"`) — Vorbedingung der Offscreen-Probe, nicht bestätigt.
- **Ortungs-Ein/Aus-Zustand:** `gconftool-2 -R /system/nokia/location` kam **leer**
  zurück (rc 0); Zustand vermutlich im aegisfs `.positioningd/private` (s. o.), ungeklärt.
- **`/usr/sbin/mcetool`** bestätigen (als `user` nicht im PATH).
- **Aufräumen ausstehend:** `/home/user/p1.sh` (die accli-Probe) liegt noch auf der N950
  — konnte nicht gelöscht werden, Gerät weg. Bei nächstem Zugang:
  `rm -f /home/user/p1.sh`.
- **Zugang:** N950 nur über die Jolla-Hotspot-WLAN erreichbar; die ist aus (`wlan0`
  `state DOWN`, Jolla auf Mobilfunk). Für die Fortsetzung muss der Hotspot wieder an
  (geräteseitig durch den Nutzer — vom Arbeitsgerät aus habe ich ihn bewusst nicht
  angeschaltet).
