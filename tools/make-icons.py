#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Die Startsymbole fuer beide Ausgaben aus dem Original der Android-App.

Die Vorlage ist das Symbol der Android-App (rotes Feld, weisses Rad). Beide
Zielsysteme schneiden ihre Symbole zu einem Squircle, aber zu einem anderen:

* Harmattan nimmt die Silhouette der Standard-Apps, und die ist nicht
  nachgebaut, sondern der Alphakanal eines Blanco-Icons
  (/usr/share/themes/blanco/meegotouch/icons/icon-l-*.png, hier als
  mask-icon-l.png in ~/ps/meego-icon-tool).
* Sailfish nimmt eine Superellipse |x|^2.8 + |y|^2.8 = 1 bei 0.98 Radius --
  an einem Stock-Icon nachgemessen, 0,34 % Abweichung.

Beides wird vierfach gezeichnet und erst am Schluss verkleinert; die Kurve
franst sonst aus. Das Original bringt selbst schon ein abgerundetes Quadrat
mit, dessen Ecken weiter aussen liegen als der Squircle -- deshalb wird das
Bild leicht vergroessert (BLEED), damit der Schnitt durch das rote Feld geht
und nicht die alte Kontur stehen laesst.
"""
import os
import sys

from PIL import Image

HIER = os.path.dirname(os.path.abspath(__file__))
WURZEL = os.path.dirname(HIER)
QUELLE = os.path.join(HIER, "original", "original-450.png")
MEEGO_MASKE = "/home/defaultuser/ps/meego-icon-tool/mask-icon-l.png"

UEBERABTASTUNG = 4
SFOS_GROESSEN = (86, 108, 128, 172)
MEEGO_GROESSEN = (80, 64)
EXPONENT = 2.8
RADIUS = 0.98
BLEED = 1.07


def vorlage():
    """Das Original auf sein sichtbares Rechteck beschnitten."""
    bild = Image.open(QUELLE).convert("RGBA")
    kasten = bild.split()[3].getbbox()
    return bild.crop(kasten) if kasten else bild


def grundfarbe(bild):
    """Die haeufigste deckende Farbe auf halber Hoehe -- das rote Feld.

    Damit werden die Ecken gefuellt, die das abgerundete Quadrat des
    Originals leer laesst; sonst sieht man unter dem Squircle durch.
    """
    proben = {}
    breite, hoehe = bild.size
    px = bild.load()
    for x in range(breite):
        for y in (hoehe // 2, hoehe // 2 - 1):
            r, g, b, a = px[x, y]
            if a > 200:
                proben[(r, g, b)] = proben.get((r, g, b), 0) + 1
    return max(proben.items(), key=lambda e: e[1])[0] if proben else (192, 13, 13)


def gefuellt(bild, kante):
    """Quadratische Flaeche in der Grundfarbe, das Original mittig darauf."""
    grund = grundfarbe(bild)
    innen = int(round(kante * BLEED))
    skaliert = bild.resize((innen, innen), Image.LANCZOS)
    flaeche = Image.new("RGBA", (kante, kante), grund + (255,))
    versatz = (kante - innen) // 2
    flaeche.paste(skaliert, (versatz, versatz), skaliert)
    return flaeche


def sfos_maske(kante):
    maske = Image.new("L", (kante, kante), 0)
    px = maske.load()
    mitte = (kante - 1) / 2.0
    radius = mitte * RADIUS
    for y in range(kante):
        dy = (abs(y - mitte) / radius) ** EXPONENT
        for x in range(kante):
            if dy + (abs(x - mitte) / radius) ** EXPONENT <= 1.0:
                px[x, y] = 255
    return maske


def meego_maske(kante):
    if not os.path.exists(MEEGO_MASKE):
        raise SystemExit("Blanco-Maske fehlt: %s" % MEEGO_MASKE)
    stock = Image.open(MEEGO_MASKE).convert("RGBA")
    return stock.split()[3].resize((kante, kante), Image.LANCZOS)


def schneiden(bild, maske_bauen, groesse):
    kante = groesse * UEBERABTASTUNG
    flaeche = gefuellt(bild, kante)
    flaeche.putalpha(maske_bauen(kante))
    return flaeche.resize((groesse, groesse), Image.LANCZOS)


def main():
    ziel_meego = os.path.join(WURZEL, "meego", "icons")
    os.makedirs(ziel_meego, exist_ok=True)
    bild = vorlage()
    print("Vorlage %dx%d, Grundfarbe #%02x%02x%02x" % (bild.size + grundfarbe(bild)))
    for groesse in SFOS_GROESSEN:
        # sailfishapp expects icons/<kante>x<kante>/<ziel>.png
        ordner = os.path.join(WURZEL, "icons", "%dx%d" % (groesse, groesse))
        os.makedirs(ordner, exist_ok=True)
        pfad = os.path.join(ordner, "harbour-radelt.png")
        schneiden(bild, sfos_maske, groesse).save(pfad)
        print("sfos  ", pfad)
    for groesse in MEEGO_GROESSEN:
        pfad = os.path.join(ziel_meego, "icon-%d.png" % groesse)
        schneiden(bild, meego_maske, groesse).save(pfad)
        print("meego ", pfad)


if __name__ == "__main__":
    sys.exit(main())
