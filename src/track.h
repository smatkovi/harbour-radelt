#ifndef TRACK_H
#define TRACK_H

#include <QDateTime>
#include <QList>
#include <QString>

// One fix as the receiver delivered it. Altitude, accuracy and speed are
// optional: a fix without them carries a negative value, which no real
// reading can take (altitude below -1000 m is treated as missing, the
// Dead Sea shore being the lowest dry land at -430 m).
struct TrackPoint
{
    TrackPoint() : latitude(0), longitude(0), altitude(-32768), accuracy(-1), speed(-1) {}

    double latitude;
    double longitude;
    double altitude;            // metres, -32768 when unknown
    double accuracy;            // horizontal, metres, -1 when unknown
    double speed;               // m/s, -1 when unknown
    QDateTime time;             // UTC

    bool hasAltitude() const { return altitude > -1000; }
    bool hasAccuracy() const { return accuracy >= 0; }
};

// The recorded line of a ride, plus everything that can be derived from it.
//
// The numbers are computed as the points come in rather than on demand: a
// ride of two hours at one fix a second is seven thousand points, and the
// page shows the distance several times a second.
class Track
{
public:
    Track();

    void clear();
    // Returns false when the point was dropped (too inaccurate, out of
    // order, or a jump no bicycle could make).
    bool append(const TrackPoint &point);

    const QList<TrackPoint> &points() const { return m_points; }
    int count() const { return m_points.size(); }
    bool isEmpty() const { return m_points.isEmpty(); }

    double distance() const { return m_distance; }          // metres
    double ascent() const { return m_ascent; }              // metres climbed
    int movingSeconds() const { return m_movingSeconds; }   // without the stops
    QDateTime start() const;
    QDateTime end() const;
    int totalSeconds() const;                               // start to end
    double averageSpeed() const;                            // m/s, moving time
    double maximumSpeed() const { return m_maximumSpeed; }  // m/s

    // The accuracy a fix must reach to be taken. 50 m is generous on
    // purpose: in a street canyon nothing better arrives for minutes, and a
    // ride that records nothing is worse than one that wanders a little.
    void setAccuracyLimit(double metres) { m_accuracyLimit = metres; }
    double accuracyLimit() const { return m_accuracyLimit; }

    // Below this speed the rider counts as stopped (traffic light, photo).
    void setStandstillSpeed(double metresPerSecond) { m_standstill = metresPerSecond; }

    static double distanceBetween(const TrackPoint &from, const TrackPoint &to);

    // GPX 1.1 with the ride as a single track segment. Readable by every
    // tool that takes GPX, which is how a ride leaves the phone when the
    // upload is not wanted.
    QByteArray toGpx(const QString &name) const;
    bool fromGpx(const QByteArray &gpx, QString *name = 0);

private:
    QList<TrackPoint> m_points;
    double m_distance;
    double m_ascent;
    double m_maximumSpeed;
    double m_accuracyLimit;
    double m_standstill;
    int m_movingSeconds;
    double m_smoothedAltitude;  // the climb is counted on a smoothed line
    bool m_haveSmoothed;
    TrackPoint m_anchor;        // the last point that counted for distance
};

#endif
