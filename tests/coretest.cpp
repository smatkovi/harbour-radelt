// Checks the parts of the core that have a right answer: the JSON reader,
// the distance along a track, the filters that keep a standing phone from
// riding kilometres, and the GPX round trip.
//
//     sh tests/run.sh
//
// Plain asserts and one main, so it builds with the same Qt the app uses
// and runs on the device, on the build machine and in the SDK container
// alike -- QtTest is not installed everywhere, and this needs nothing from
// it.
#include <QCoreApplication>
#include <QDateTime>
#include <QStringList>
#include <QTextStream>

#include <math.h>
#include <stdlib.h>

#include <QCryptographicHash>

#include "geojson.h"
#include "json.h"
#include "track.h"

static int failures = 0;
static QTextStream out(stdout);

static void check(bool condition, const QString &what)
{
    if (!condition) {
        out << "FEHLER: " << what << "\n";
        ++failures;
    }
}

static void checkNear(double value, double expected, double tolerance,
                      const QString &what)
{
    if (fabs(value - expected) > tolerance) {
        out << "FEHLER: " << what << " -- " << value << " statt "
            << expected << " (+/- " << tolerance << ")\n";
        ++failures;
    }
}

static TrackPoint point(double latitude, double longitude, int secondsFromStart,
                        double accuracy = 5, double altitude = -32768)
{
    TrackPoint p;
    p.latitude = latitude;
    p.longitude = longitude;
    p.accuracy = accuracy;
    p.altitude = altitude;
    p.time = QDateTime(QDate(2026, 10, 8), QTime(6, 0, 0), Qt::UTC).addSecs(secondsFromStart);
    return p;
}

static void testJson()
{
    QString error;
    const QVariant value = Json::parse(
        "{\"success\":true,\"message\":\"Logindaten ung\\u00fcltig\","
        "\"data\":{\"rideId\":9007199254740993,\"distance\":12.5,"
        "\"points\":[1,2,3],\"nested\":{\"a\":null},\"flag\":false}}", &error);
    check(error.isEmpty(), "einfaches JSON meldet keinen Fehler: " + error);
    check(value.type() == QVariant::Map, "Wurzel ist ein Objekt");

    check(Json::value(value, "success").toBool(), "success ist wahr");
    check(Json::value(value, "message").toString() == QString::fromUtf8("Logindaten ungültig"),
          "\\u-Folge wird entschluesselt");
    // A ride id must survive as an integer: through a double it would come
    // back as 9007199254740992 and the server would not know it.
    check(Json::value(value, "data/rideId").toLongLong() == Q_INT64_C(9007199254740993),
          "grosse Ganzzahl bleibt exakt");
    checkNear(Json::value(value, "data/distance").toDouble(), 12.5, 1e-9,
              "Kommazahl");
    check(Json::value(value, "data/points/1").toInt() == 2, "Listenindex im Pfad");
    check(!Json::value(value, "data/nested/a").isValid(), "null ist ungueltig");
    check(!Json::value(value, "data/flag").toBool(), "false ist falsch");
    check(!Json::value(value, "data/fehlt").isValid(), "fehlender Schluessel");

    // Laravel answers a validation error with field -> list of sentences;
    // the API client shows exactly that, so it has to survive the parser.
    const QVariant problem = Json::parse(
        "{\"success\":false,\"error\":{\"password\":[\"password muss ausgef\\u00fcllt werden.\"]}}");
    check(Json::value(problem, "error/password/0").toString().startsWith("password muss"),
          "Validierungsfehler als Objekt");

    check(!Json::parse("{\"a\":1,}").isValid(), "Komma am Ende wird abgelehnt");
    check(!Json::parse("[1,2").isValid(), "abgeschnittene Liste wird abgelehnt");
    check(!Json::parse("").isValid(), "leere Eingabe wird abgelehnt");

    // Round trip, including the umlaut and a negative number.
    QVariantMap map;
    map.insert("name", QString::fromUtf8("Fahrt über den Berg"));
    map.insert("altitude", -12.5);
    map.insert("count", 7);
    map.insert("ok", true);
    const QVariant again = Json::parse(Json::serialise(map));
    check(Json::value(again, "name").toString() == map.value("name").toString(),
          "Umlaut ueberlebt den Umlauf");
    checkNear(Json::value(again, "altitude").toDouble(), -12.5, 1e-9,
              "negative Zahl ueberlebt");
    check(Json::value(again, "count").toInt() == 7, "Ganzzahl ueberlebt");
    check(Json::value(again, "ok").toBool(), "Wahrheitswert ueberlebt");
}

static void testDistance()
{
    // Vienna, Stephansplatz to Karlsplatz: 913 m by the great circle.
    TrackPoint a = point(48.208354, 16.372504, 0);
    TrackPoint b = point(48.200833, 16.369167, 120);
    checkNear(Track::distanceBetween(a, b), 866, 25, "Entfernung in Wien");

    // A degree of latitude is 111.2 km anywhere.
    TrackPoint north = point(48.0, 16.0, 0);
    TrackPoint further = point(49.0, 16.0, 3600);
    checkNear(Track::distanceBetween(north, further), 111195, 100,
              "ein Breitengrad");

    check(Track::distanceBetween(a, a) == 0.0, "Punkt auf sich selbst");
}

static void testTrack()
{
    Track track;
    // A straight ride east at about 18 km/h: a fix a second, five metres
    // apart.
    const double step = 0.0000673;      // ~5 m of longitude at 48 degrees
    for (int i = 0; i < 100; ++i)
        track.append(point(48.2, 16.37 + i * step, i));
    check(track.count() == 100, "alle Punkte angenommen");
    checkNear(track.distance(), 495, 15, "Strecke der geraden Fahrt");
    check(track.movingSeconds() > 90, "Fahrzeit laeuft mit");
    checkNear(track.averageSpeed() * 3.6, 18, 2.0, "Schnitt in km/h");

    // Standing still with a scattering receiver must not add distance.
    Track standing;
    for (int i = 0; i < 60; ++i) {
        const double jitter = (i % 2 ? 1 : -1) * 0.000018;   // ~2 m
        standing.append(point(48.2 + jitter, 16.37 - jitter, i, 8));
    }
    checkNear(standing.distance(), 0, 1.0, "Zittern im Stand zaehlt nicht");
    check(standing.movingSeconds() == 0, "Stand ist keine Fahrzeit");

    // A fix worse than the limit is dropped.
    Track filtered;
    filtered.setAccuracyLimit(25);
    filtered.append(point(48.2, 16.37, 0, 10));
    check(!filtered.append(point(48.21, 16.38, 10, 400)),
          "ungenauer Punkt wird verworfen");
    check(filtered.count() == 1, "und landet nicht in der Spur");

    // A jump no bicycle can make is dropped as well: 2 km in 10 s.
    Track jumping;
    jumping.append(point(48.2, 16.37, 0, 10));
    check(!jumping.append(point(48.22, 16.37, 10, 10)), "Sprung wird verworfen");

    // The climb is only counted beyond the noise of the GPS altitude.
    Track climbing;
    for (int i = 0; i < 40; ++i) {
        const double noise = (i % 2 ? 2.0 : -2.0);
        climbing.append(point(48.2 + i * 0.0002, 16.37, i * 5, 8, 200 + noise));
    }
    checkNear(climbing.ascent(), 0, 1.0, "Hoehenrauschen ist kein Anstieg");

    Track hill;
    for (int i = 0; i < 40; ++i)
        hill.append(point(48.2 + i * 0.0002, 16.37, i * 5, 8, 200 + i * 10));
    checkNear(hill.ascent(), 390, 20, "echter Anstieg wird gezaehlt");
}

static void testLoginSignature()
{
    // Die Anmelde-Signatur der Plattform: md5(Kennung + Passwort + Salz),
    // klein geschriebene Hex-Ziffern. Der Wert hier ist mit demselben
    // Verfahren erzeugt, das am Server "success:true" geliefert hat --
    // bricht das Verfahren, bricht die Anmeldung, und zwar still.
    const QByteArray roh = QByteArray("probe") + "geheim" + "TourDeBoedele";
    const QString secure = QString::fromLatin1(
        QCryptographicHash::hash(roh, QCryptographicHash::Md5).toHex());
    // Fester Sollwert: md5("probe" + "geheim" + "TourDeBoedele").
    check(secure == QLatin1String("49c51e15e64e28ecd6c5a24f8b347117"),
          "Signatur trifft den Sollwert -- sonst lehnt der Server jede Anmeldung ab");
}

// Der eine Dreher, der jeden Ort stillschweigend ins Meer setzen wuerde:
// GeoJSON schreibt [Laenge, Breite]. Die Zahlen hier sind eine echte
// Antwort des Dienstes (Ort 49 der passathon-Strecke "Vorarlberg -
// Rheintal 20", gemessen am 09.10.2026) -- 47,4 Grad Nord und 9,66 Grad
// Ost liegt in Lustenau. Vertauscht laege der Ort bei 9,66 Grad Nord im
// Golf von Guinea.
static void testGeoJson()
{
    const QVariant antwort = Json::parse(
        "{\"id\":49,\"name\":\"Mehrfamilienhaus BT 3\","
        "\"description\":\"\",\"image\":\"https://example.invalid/b.jpg\","
        "\"geometry\":{\"type\":\"Point\",\"coordinates\":[9.65851,47.41143]},"
        "\"singleAlreadyCollected\":false}");
    const QVariantMap ort = Geo::ortFlach(antwort.toMap(), "Rheintal 20");

    checkNear(ort.value("latitude").toDouble(), 47.41143, 1e-6,
              "Breite kommt aus der zweiten Koordinate");
    checkNear(ort.value("longitude").toDouble(), 9.65851, 1e-6,
              "Laenge kommt aus der ersten Koordinate");
    check(ort.value("hasPosition").toBool(), "Ort hat eine Position");
    check(!ort.value("collected").toBool(), "noch nicht eingesammelt");
    check(ort.value("routeName").toString() == "Rheintal 20", "Streckenname dabei");
    check(ort.value("id").toLongLong() == 49, "Kennung bleibt");
    check(!ort.contains("geometry"), "die Huelle ist weg");

    // Breite und Laenge duerfen nicht verwechselbar nah beieinander
    // liegen: ein Ort, der in Oesterreich liegt, hat immer eine Breite
    // ueber 46 und eine Laenge unter 18.
    check(ort.value("latitude").toDouble() > 46.0
          && ort.value("longitude").toDouble() < 18.0,
          "der Ort liegt in Oesterreich, nicht im Meer");

    // Ein eingesammelter Ort: der Dienst setzt collectedAt.
    const QVariant zweite = Json::parse(
        "{\"id\":7,\"collectedAt\":\"2026-07-01 10:00:00\","
        "\"geometry\":{\"type\":\"Point\",\"coordinates\":[16.37,48.21]}}");
    const QVariantMap alt = Geo::ortFlach(zweite.toMap(), QString());
    check(alt.value("collected").toBool(), "collectedAt gilt als eingesammelt");

    // Ein Ort ohne Geometrie darf nicht auf 0,0 landen und dort als
    // naechster Ort ganz oben stehen.
    const QVariantMap ohne = Geo::ortFlach(Json::parse("{\"id\":8}").toMap(), QString());
    check(!ohne.value("hasPosition").toBool(), "Ort ohne Geometrie ist erkennbar");
}

static void testGpx()
{
    Track track;
    for (int i = 0; i < 20; ++i)
        track.append(point(48.2 + i * 0.0002, 16.37 + i * 0.0003, i * 2, 7, 180 + i));

    const QByteArray gpx = track.toGpx("Probefahrt");
    check(gpx.contains("<gpx"), "GPX hat ein Wurzelelement");
    check(gpx.contains("Probefahrt"), "Name steht drin");
    check(gpx.contains("<trkpt"), "Punkte stehen drin");

    Track again;
    QString name;
    check(again.fromGpx(gpx, &name), "GPX laesst sich wieder lesen");
    check(name == "Probefahrt", "Name kommt zurueck");
    check(again.count() == track.count(), "gleiche Punktzahl");
    checkNear(again.distance(), track.distance(), 1.0, "gleiche Strecke");
    checkNear(again.ascent(), track.ascent(), 1.0, "gleicher Anstieg");
    check(again.points().first().time == track.points().first().time,
          "Zeitstempel ueberleben (UTC)");
    checkNear(again.points().at(3).accuracy, 7, 0.01, "Genauigkeit ueberlebt");
}

int main(int argc, char *argv[])
{
    QCoreApplication application(argc, argv);

    testJson();
    testDistance();
    testTrack();
    testGpx();
    testGeoJson();
    testLoginSignature();

    out << (failures ? QString("%1 Fehler\n").arg(failures)
                     : QString("alles in Ordnung\n"));
    return failures ? 1 : 0;
}
