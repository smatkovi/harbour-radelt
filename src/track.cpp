#include "track.h"

#include <QXmlStreamReader>
#include <QXmlStreamWriter>

#include <math.h>

namespace
{
const double EarthRadius = 6371000.0;       // metres, mean
const double Degree = M_PI / 180.0;

// Nothing a bicycle does: 30 m/s is 108 km/h. A fix that implies more is a
// jump of the receiver, not a sprint, and it would otherwise add hundreds of
// metres to the distance in one step.
const double MaximumPlausibleSpeed = 30.0;

// The climb is only counted once the smoothed altitude has moved this far.
// Without it the noise of the barometer-less GPS altitude (a few metres from
// fix to fix) sums to hundreds of metres of imaginary climbing per hour.
const double AscentThreshold = 5.0;
}

Track::Track()
{
    clear();
}

void Track::clear()
{
    m_points.clear();
    m_distance = 0;
    m_ascent = 0;
    m_maximumSpeed = 0;
    m_accuracyLimit = 50.0;
    m_standstill = 0.8;                 // 2.9 km/h
    m_movingSeconds = 0;
    m_smoothedAltitude = 0;
    m_haveSmoothed = false;
    m_anchor = TrackPoint();
}

double Track::distanceBetween(const TrackPoint &from, const TrackPoint &to)
{
    // Haversine. Written out rather than taken from QGeoCoordinate because
    // the two editions get that class from different modules with different
    // behaviour, and the distance must not depend on which one is compiled.
    const double lat1 = from.latitude * Degree;
    const double lat2 = to.latitude * Degree;
    const double dLat = (to.latitude - from.latitude) * Degree;
    const double dLon = (to.longitude - from.longitude) * Degree;
    const double a = sin(dLat / 2) * sin(dLat / 2)
                   + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * EarthRadius * atan2(sqrt(a), sqrt(1 - a));
}

bool Track::append(const TrackPoint &point)
{
    if (point.hasAccuracy() && point.accuracy > m_accuracyLimit)
        return false;

    if (m_points.isEmpty()) {
        m_points.append(point);
        m_anchor = point;
        if (point.hasAltitude()) {
            m_smoothedAltitude = point.altitude;
            m_haveSmoothed = true;
        }
        return true;
    }

    const TrackPoint &last = m_points.last();
    if (point.time.isValid() && last.time.isValid()
        && point.time < last.time)
        return false;                   // out of order

    {
        const double leap = distanceBetween(last, point);
        int gap = 0;
        if (point.time.isValid() && last.time.isValid())
            gap = last.time.secsTo(point.time);
        if (gap > 0 && leap / gap > MaximumPlausibleSpeed)
            return false;               // no bicycle does that
    }

    // Distance is measured from the last point that counted, not from the
    // last point that arrived. A standing receiver wanders by about its own
    // accuracy from fix to fix; measured from its neighbour, every one of
    // those steps looks like riding, and two minutes at a traffic light
    // "ride" a few hundred metres. Measured from an anchor that only moves
    // once the threshold is passed, standing still adds nothing at all,
    // while riding still adds everything -- only in steps of a second or
    // two rather than every single fix.
    const double fromAnchor = distanceBetween(m_anchor, point);
    double threshold = 3.0;
    if (point.hasAccuracy())
        threshold = qMax(threshold, point.accuracy);
    if (m_anchor.hasAccuracy())
        threshold = qMax(threshold, m_anchor.accuracy);

    m_points.append(point);
    if (fromAnchor <= threshold)
        return true;                    // in the line, not in the numbers

    int seconds = 0;
    if (point.time.isValid() && m_anchor.time.isValid())
        seconds = m_anchor.time.secsTo(point.time);

    m_distance += fromAnchor;
    if (seconds > 0) {
        const double speed = fromAnchor / seconds;
        if (speed > m_standstill)
            m_movingSeconds += seconds;
        if (speed > m_maximumSpeed && speed < MaximumPlausibleSpeed)
            m_maximumSpeed = speed;
    }

    if (point.hasAltitude()) {
        if (!m_haveSmoothed) {
            m_smoothedAltitude = point.altitude;
            m_haveSmoothed = true;
        } else {
            const double rise = point.altitude - m_smoothedAltitude;
            if (rise > AscentThreshold) {
                m_ascent += rise;
                m_smoothedAltitude = point.altitude;
            } else if (rise < -AscentThreshold) {
                m_smoothedAltitude = point.altitude;
            }
        }
    }

    m_anchor = point;
    return true;
}

QDateTime Track::start() const
{
    return m_points.isEmpty() ? QDateTime() : m_points.first().time;
}

QDateTime Track::end() const
{
    return m_points.isEmpty() ? QDateTime() : m_points.last().time;
}

int Track::totalSeconds() const
{
    if (m_points.size() < 2)
        return 0;
    const QDateTime from = start();
    const QDateTime to = end();
    if (!from.isValid() || !to.isValid())
        return 0;
    return from.secsTo(to);
}

double Track::averageSpeed() const
{
    if (m_movingSeconds <= 0)
        return 0;
    return m_distance / m_movingSeconds;
}

QByteArray Track::toGpx(const QString &name) const
{
    QByteArray out;
    QXmlStreamWriter xml(&out);
    xml.setAutoFormatting(true);
    xml.writeStartDocument();
    xml.writeStartElement("gpx");
    xml.writeAttribute("version", "1.1");
    xml.writeAttribute("creator", "harbour-radelt");
    xml.writeAttribute("xmlns", "http://www.topografix.com/GPX/1/1");
    xml.writeStartElement("trk");
    xml.writeTextElement("name", name);
    xml.writeStartElement("trkseg");
    for (int i = 0; i < m_points.size(); ++i) {
        const TrackPoint &point = m_points.at(i);
        xml.writeStartElement("trkpt");
        xml.writeAttribute("lat", QString::number(point.latitude, 'f', 7));
        xml.writeAttribute("lon", QString::number(point.longitude, 'f', 7));
        if (point.hasAltitude())
            xml.writeTextElement("ele", QString::number(point.altitude, 'f', 1));
        if (point.time.isValid())
            xml.writeTextElement("time", point.time.toUTC().toString(Qt::ISODate) + "Z");
        if (point.hasAccuracy() || point.speed >= 0) {
            xml.writeStartElement("extensions");
            if (point.hasAccuracy())
                xml.writeTextElement("accuracy", QString::number(point.accuracy, 'f', 1));
            if (point.speed >= 0)
                xml.writeTextElement("speed", QString::number(point.speed, 'f', 2));
            xml.writeEndElement();
        }
        xml.writeEndElement();          // trkpt
    }
    xml.writeEndElement();              // trkseg
    xml.writeEndElement();              // trk
    xml.writeEndElement();              // gpx
    xml.writeEndDocument();
    return out;
}

bool Track::fromGpx(const QByteArray &gpx, QString *name)
{
    clear();
    QXmlStreamReader xml(gpx);
    TrackPoint point;
    bool inPoint = false;
    while (!xml.atEnd()) {
        xml.readNext();
        if (xml.isStartElement()) {
            const QStringRef element = xml.name();
            if (element == QLatin1String("trkpt")) {
                point = TrackPoint();
                point.latitude = xml.attributes().value("lat").toString().toDouble();
                point.longitude = xml.attributes().value("lon").toString().toDouble();
                inPoint = true;
            } else if (inPoint && element == QLatin1String("ele")) {
                point.altitude = xml.readElementText().toDouble();
            } else if (inPoint && element == QLatin1String("time")) {
                QString text = xml.readElementText();
                if (text.endsWith(QLatin1Char('Z')))
                    text.chop(1);
                point.time = QDateTime::fromString(text, Qt::ISODate);
                point.time.setTimeSpec(Qt::UTC);
            } else if (inPoint && element == QLatin1String("accuracy")) {
                point.accuracy = xml.readElementText().toDouble();
            } else if (inPoint && element == QLatin1String("speed")) {
                point.speed = xml.readElementText().toDouble();
            } else if (!inPoint && name && element == QLatin1String("name")) {
                *name = xml.readElementText();
            }
        } else if (xml.isEndElement() && xml.name() == QLatin1String("trkpt")) {
            inPoint = false;
            // Read back without the filters: the file is the record of what
            // was ridden, and re-filtering it would quietly change the
            // distance of a ride that is already closed.
            const double limit = m_accuracyLimit;
            m_accuracyLimit = 1e9;
            append(point);
            m_accuracyLimit = limit;
        }
    }
    return !xml.hasError();
}
