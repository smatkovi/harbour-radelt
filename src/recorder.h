#ifndef RECORDER_H
#define RECORDER_H

#include <QObject>
#include <QDateTime>
#include <QTimer>

#include "track.h"

#if QT_VERSION >= 0x050000
#include <QGeoPositionInfo>
#include <QGeoPositionInfoSource>
#else
// Harmattan carries the positioning in QtMobility, in its own namespace. The
// class names and signals are the same, which is why everything below this
// point compiles unchanged for both.
#include <QGeoPositionInfo>
#include <QGeoPositionInfoSource>
QTM_USE_NAMESPACE
#endif

// Records a ride from the satellite receiver.
//
// The rule it follows is Kuri's (gitlab.com/elBoberido/kuri): ask the
// receiver for satellite fixes once a second, and treat a reading as stale
// when nothing has arrived for a couple of intervals -- a phone in a pocket
// in a street canyon stops reporting rather than reporting nonsense, and the
// page must say so instead of showing the last accuracy forever.
class Recorder : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool recording READ isRecording NOTIFY recordingChanged)
    Q_PROPERTY(bool paused READ isPaused WRITE setPaused NOTIFY pausedChanged)
    Q_PROPERTY(bool positionValid READ positionValid NOTIFY positionChanged)
    Q_PROPERTY(double latitude READ latitude NOTIFY positionChanged)
    Q_PROPERTY(double longitude READ longitude NOTIFY positionChanged)
    Q_PROPERTY(double accuracy READ accuracy NOTIFY accuracyChanged)
    Q_PROPERTY(double distance READ distance NOTIFY statisticsChanged)
    Q_PROPERTY(double ascent READ ascent NOTIFY statisticsChanged)
    Q_PROPERTY(int movingSeconds READ movingSeconds NOTIFY statisticsChanged)
    Q_PROPERTY(int totalSeconds READ totalSeconds NOTIFY statisticsChanged)
    Q_PROPERTY(double averageSpeed READ averageSpeed NOTIFY statisticsChanged)
    Q_PROPERTY(double currentSpeed READ currentSpeed NOTIFY statisticsChanged)
    Q_PROPERTY(int pointCount READ pointCount NOTIFY statisticsChanged)
    Q_PROPERTY(bool sourceAvailable READ sourceAvailable CONSTANT)

public:
    explicit Recorder(QObject *parent = 0);
    ~Recorder();

    bool isRecording() const { return m_recording; }
    bool isPaused() const { return m_paused; }
    void setPaused(bool paused);

    bool positionValid() const { return m_positionValid; }
    double latitude() const { return m_latitude; }
    double longitude() const { return m_longitude; }
    double accuracy() const { return m_accuracy; }

    double distance() const { return m_track.distance(); }
    double ascent() const { return m_track.ascent(); }
    int movingSeconds() const { return m_track.movingSeconds(); }
    int totalSeconds() const;
    double averageSpeed() const { return m_track.averageSpeed(); }
    double currentSpeed() const { return m_currentSpeed; }
    int pointCount() const { return m_track.count(); }
    bool sourceAvailable() const { return m_source != 0; }

    const Track &track() const { return m_track; }
    QDateTime startedAt() const { return m_startedAt; }

public slots:
    // Switches the receiver on without recording: the page shows the
    // accuracy while the rider waits for a fix, which is the only honest
    // way to start a ride -- starting on a 500 m fix puts the first
    // kilometre in the wrong street.
    void startPositioning();
    void stopPositioning();

    void start();
    void stop();
    void reset();

signals:
    void recordingChanged();
    void pausedChanged();
    void positionChanged();
    void accuracyChanged();
    void statisticsChanged();

private slots:
    void positionUpdated(const QGeoPositionInfo &update);
    void positionTimeout();
    void accuracyOutdated();
    void tick();

private:
    QGeoPositionInfoSource *m_source;
    Track m_track;
    QTimer m_accuracyTimer;
    QTimer m_tickTimer;
    QDateTime m_startedAt;
    QDateTime m_pausedAt;
    int m_pausedSeconds;
    double m_latitude;
    double m_longitude;
    double m_accuracy;
    double m_currentSpeed;
    bool m_positionValid;
    bool m_recording;
    bool m_paused;
    bool m_positioning;
};

#endif
