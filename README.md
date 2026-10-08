# Radelt

Kilometer für die Plattform **Österreich radelt** (radelt.at) — auf Sailfish OS
und auf MeeGo Harmattan (Nokia N9/N950). Die App zeichnet eine Fahrt mit dem
Satellitenempfänger auf, behält sie als GPX auf dem Telefon und überträgt die
Kilometer ins Konto auf radelt.at. Fahrten lassen sich auch von Hand eintragen.

Das ist eine eigenständige Neuimplementierung, kein Port der Flutter-App und
nichts, was mit der Österreichischen Energieagentur zu tun hat. Die
Schnittstelle wurde aus der öffentlichen Android-App herausgelesen; was
gemessen und was erschlossen ist, steht in [doc/api.md](doc/api.md).

## Was drin ist

* Aufzeichnen mit dem Satellitenempfänger: Strecke, Fahrzeit, Schnitt,
  Höhenmeter, Genauigkeitsanzeige, Pause.
* Jede Fahrt als GPX unter `~/.local/share/harbour-radelt/rides/`.
* Fahrt von Hand eintragen (Tag und Kilometer).
* Anmelden am radelt.at-Konto, Fahrten einzeln oder im Stapel übertragen;
  was nicht durchkam, bleibt als „nicht übertragen" stehen.
* Startsymbol in der jeweiligen Squircle-Silhouette des Systems.

## Aufbau

| Verzeichnis | Inhalt |
|---|---|
| `src/` | der gemeinsame Kern: Aufzeichner, Fahrtenspeicher, GPX, JSON, API-Client |
| `qml/` | die Sailfish-Oberfläche (Silica) |
| `meego/` | die Harmattan-Ausgabe: eigenes `main.cpp`, `com.nokia.meego`-QML, Paketierung |
| `meego/fetch/` | `radelt-fetch`, der TLS-Helfer in Rust — Qt 4.7 auf Harmattan kommt an keinen heutigen Server heran |
| `tools/` | Icons, RPM-Bau, QML-Prüfung |
| `doc/` | die herausgelesene Schnittstelle und die Ortungslage am N950 |

Der Kern ist für beide Qt-Fassungen geschrieben (`#if QT_VERSION`): Qt 5 mit
QtPositioning und QNetworkAccessManager, Qt 4.7 mit QtMobility-Location und
dem Rust-Helfer.

## Bauen

Sailfish (beide Architekturen, je Ziel ein frischer Baum):

    sh tools/build-rpms.sh            # -> ~/ps/rpms/radelt/*.rpm

MeeGo Harmattan:

    sh meego/remote-build.sh          # -> ~/ps/rpms/radelt/*.deb

Symbole neu erzeugen (aus `tools/original/original-450.png`):

    python3 tools/make-icons.py

Prüfen, ohne zu bauen:

    sh tools/qml-laden.sh             # Silica-QML, auf dem Sailfish-Gerät
    sh meego/tests/check-qml.sh       # Harmattan-QML, auf dem Baurechner

## Ortung auf dem N9/N950

Der Sitzungs-D-Bus lässt nur Prozesse mit der aegis-Kennung `Location` an
`com.nokia.positioningd.client`. Das Paket fordert sie im `_aegis`-Manifest an
und **muss mit `aegis-dpkg -i` installiert werden**; ein `dpkg -i` bringt die
Kennung nicht. Einzelheiten und Belege in
[doc/meego-ortung.md](doc/meego-ortung.md).

## Lizenz

GPL-3.0-or-later. Das Startsymbol stammt aus der Android-App und gehört deren
Rechteinhabern.
