#ifndef GEOJSON_H
#define GEOJSON_H

#include <QString>
#include <QVariantList>
#include <QVariantMap>

// Die Plattform schickt die Orte zum Sammeln als GeoJSON. Darin stehen die
// Koordinaten als **[Laenge, Breite]** -- umgekehrt zu allem anderen in
// dieser App und zu allem, was man beim Lesen erwartet. Ein Dreher hier
// faellt nirgends auf: die App zeigt dann einfach Orte, die im Meer
// liegen, und sortiert sie nach einer unsinnigen Entfernung.
//
// Deshalb steckt das Flachlegen in einer eigenen Funktion, die der Test
// gegen einen echten, gemessenen Ort prueft (tests/coretest.cpp).
namespace Geo
{

inline QVariantMap ortFlach(const QVariantMap &roh, const QString &strecke)
{
    QVariantMap ort(roh);
    const QVariantList koordinaten =
        roh.value("geometry").toMap().value("coordinates").toList();
    double laenge = 0;
    double breite = 0;
    const bool vorhanden = koordinaten.size() >= 2;
    if (vorhanden) {
        laenge = koordinaten.at(0).toDouble();
        breite = koordinaten.at(1).toDouble();
    }
    ort.insert("longitude", laenge);
    ort.insert("latitude", breite);
    ort.insert("hasPosition", vorhanden);
    ort.insert("routeName", strecke);
    // Der Dienst nennt es singleAlreadyCollected; collectedAt kommt beim
    // Einsammeln dazu.
    const bool gesammelt = roh.value("singleAlreadyCollected").toBool()
                        || (roh.contains("collectedAt")
                            && !roh.value("collectedAt").isNull());
    ort.insert("collected", gesammelt);
    ort.remove("geometry");
    return ort;
}

}

#endif
