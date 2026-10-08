#include "recorder.h"

#include <QDebug>

namespace
{
const int UpdateIntervalMs = 1000;
// Two intervals plus a little: at one fix a second, nothing for three
// seconds means the receiver lost the sky, not that it is slow.
const int AccuracyOutdatedMs = 3500;
}

Recorder::Recorder(QObject *parent) :
    QObject(parent),
    m_source(QGeoPositionInfoSource::createDefaultSource(this)),
    m_pausedSeconds(0),
    m_latitude(0),
    m_longitude(0),
    m_accuracy(-1),
    m_currentSpeed(-1),
    m_positionValid(false),
    m_recording(false),
    m_paused(false),
    m_positioning(false)
{
    if (m_source) {
        // Satellites only. The network method would answer within seconds
        // with a cell-tower position good to a kilometre, and those fixes
        // make the first minutes of every ride a straight line between
        // masts.
        m_source->setPreferredPositioningMethods(QGeoPositionInfoSource::SatellitePositioningMethods);
        const int minimum = m_source->minimumUpdateInterval();
        m_source->setUpdateInterval(qMax(UpdateIntervalMs, minimum));
        connect(m_source, SIGNAL(positionUpdated(QGeoPositionInfo)),
                this, SLOT(positionUpdated(QGeoPositionInfo)));
        connect(m_source, SIGNAL(updateTimeout()), this, SLOT(positionTimeout()));
    } else {
        qWarning() << "radelt: no position source -- recording will not work";
    }

    m_accuracyTimer.setSingleShot(true);
    m_accuracyTimer.setInterval(AccuracyOutdatedMs);
    connect(&m_accuracyTimer, SIGNAL(timeout()), this, SLOT(accuracyOutdated()));

    // The clock on the page must run even while no fix arrives, otherwise a
    // ride that pauses under a bridge looks frozen.
    m_tickTimer.setInterval(1000);
    connect(&m_tickTimer, SIGNAL(timeout()), this, SLOT(tick()));
}

Recorder::~Recorder()
{
    if (m_source)
        m_source->stopUpdates();
}

void Recorder::startPositioning()
{
    if (m_positioning || !m_source)
        return;
    m_positioning = true;
    m_source->startUpdates();
    m_accuracyTimer.start();
}

void Recorder::stopPositioning()
{
    if (!m_positioning)
        return;
    if (m_recording)
        return;                     // a running recording keeps the receiver
    m_positioning = false;
    if (m_source)
        m_source->stopUpdates();
    m_accuracyTimer.stop();
    accuracyOutdated();
}

void Recorder::start()
{
    if (m_recording)
        return;
    reset();
    startPositioning();
    m_startedAt = QDateTime::currentDateTime();
    m_recording = true;
    m_paused = false;
    m_tickTimer.start();
    emit recordingChanged();
    emit pausedChanged();
}

void Recorder::stop()
{
    if (!m_recording)
        return;
    m_recording = false;
    m_paused = false;
    m_tickTimer.stop();
    emit recordingChanged();
    emit pausedChanged();
    emit statisticsChanged();
}

void Recorder::reset()
{
    m_track.clear();
    m_startedAt = QDateTime();
    m_pausedAt = QDateTime();
    m_pausedSeconds = 0;
    m_currentSpeed = -1;
    emit statisticsChanged();
}

void Recorder::setPaused(bool paused)
{
    if (paused == m_paused || !m_recording)
        return;
    m_paused = paused;
    if (paused) {
        m_pausedAt = QDateTime::currentDateTime();
    } else if (m_pausedAt.isValid()) {
        // The break does not count towards the ride: the rider stopped for
        // a coffee, and the average speed should not remember it.
        m_pausedSeconds += m_pausedAt.secsTo(QDateTime::currentDateTime());
        m_pausedAt = QDateTime();
    }
    emit pausedChanged();
    emit statisticsChanged();
}

int Recorder::totalSeconds() const
{
    if (!m_startedAt.isValid())
        return 0;
    int seconds = m_startedAt.secsTo(QDateTime::currentDateTime()) - m_pausedSeconds;
    if (m_paused && m_pausedAt.isValid())
        seconds -= m_pausedAt.secsTo(QDateTime::currentDateTime());
    return qMax(0, seconds);
}

void Recorder::positionUpdated(const QGeoPositionInfo &update)
{
    if (!update.isValid())
        return;

    m_latitude = update.coordinate().latitude();
    m_longitude = update.coordinate().longitude();
    m_positionValid = true;

    if (update.hasAttribute(QGeoPositionInfo::HorizontalAccuracy))
        m_accuracy = update.attribute(QGeoPositionInfo::HorizontalAccuracy);
    else
        m_accuracy = -1;

    if (update.hasAttribute(QGeoPositionInfo::GroundSpeed))
        m_currentSpeed = update.attribute(QGeoPositionInfo::GroundSpeed);
    else
        m_currentSpeed = -1;

    m_accuracyTimer.start();
    emit positionChanged();
    emit accuracyChanged();

    if (!m_recording || m_paused)
        return;

    TrackPoint point;
    point.latitude = m_latitude;
    point.longitude = m_longitude;
    if (update.coordinate().type() == QGeoCoordinate::Coordinate3D)
        point.altitude = update.coordinate().altitude();
    point.accuracy = m_accuracy;
    point.speed = m_currentSpeed;
    point.time = update.timestamp().toUTC();
    if (!point.time.isValid())
        point.time = QDateTime::currentDateTimeUtc();

    if (m_track.append(point))
        emit statisticsChanged();
}

void Recorder::positionTimeout()
{
    accuracyOutdated();
}

void Recorder::accuracyOutdated()
{
    if (m_accuracy < 0 && !m_positionValid)
        return;
    m_accuracy = -1;
    m_currentSpeed = -1;
    emit accuracyChanged();
}

void Recorder::tick()
{
    emit statisticsChanged();
}
