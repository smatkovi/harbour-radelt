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

    const double step = distanceBetween(last, point);
    int seconds = 0;
    if (point.time.isValid() && last.time.isValid())
        seconds = last.time.secsTo(point.time);

    if (seconds > 0 && step / seconds > MaximumPlausibleSpeed)
        return false;

    // A fix that only jitters on the spot must not add distance: with a
    // 10 m scatter and a fix a second, standing at a traffic light for two
    // minutes would otherwise "ride" a kilometre. The threshold is tied to
    // the reported accuracy, generously, and never below 3 m.
    double jitter = 3.0;
    if (point.hasAccuracy())
        jitter = qMax(jitter, point.accuracy * 0.5);
    if (step < jitter) {
        // Still record the point -- the line should show the stop -- but
        // neither distance nor moving time grows.
        m_points.append(point);
        return true;
    }

    m_distance += step;
    if (seconds > 0) {
        const double speed = step / seconds;
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

    m_points.append(point);
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
