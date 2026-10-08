#ifndef RIDESTORE_H
#define RIDESTORE_H

#include <QAbstractListModel>
#include <QDateTime>
#include <QList>
#include <QString>
#include <QVariantMap>

#include "track.h"

class Recorder;

// One ride as it sits on the phone.
//
// The line itself is a GPX file beside the record; everything the list and
// the upload need is in here, so showing twenty rides does not mean parsing
// twenty XML files.
struct Ride
{
    Ride() : distance(0), ascent(0), movingSeconds(0), totalSeconds(0),
             uploaded(false), remoteId(0), manual(false) {}

    QString id;                 // "2026-10-08T173012" -- also the file name
    QDateTime start;
    double distance;            // metres
    double ascent;              // metres
    int movingSeconds;
    int totalSeconds;
    QString title;
    QString note;
    QString bike;               // the bike chosen for this ride
    bool uploaded;
    qlonglong remoteId;         // the server's id once it took the ride
    bool manual;                // typed in rather than recorded

    QVariantMap toMap() const;
    static Ride fromMap(const QVariantMap &map);
};

// The rides on disk, newest first, as a model the pages can show.
class RideStore : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int pendingCount READ pendingCount NOTIFY countChanged)
    Q_PROPERTY(double totalDistance READ totalDistance NOTIFY countChanged)
    Q_PROPERTY(double todayDistance READ todayDistance NOTIFY countChanged)
    Q_PROPERTY(double seasonDistance READ seasonDistance NOTIFY countChanged)

public:
    enum Role {
        IdRole = Qt::UserRole + 1,
        StartRole,
        DistanceRole,
        AscentRole,
        MovingSecondsRole,
        TotalSecondsRole,
        TitleRole,
        NoteRole,
        BikeRole,
        UploadedRole,
        RemoteIdRole,
        ManualRole
    };

    explicit RideStore(QObject *parent = 0);

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role) const;
#if QT_VERSION >= 0x050000
    QHash<int, QByteArray> roleNames() const;
#endif

    int count() const { return m_rides.size(); }
    int pendingCount() const;
    double totalDistance() const;
    double todayDistance() const;
    // What the platform counts: the season runs from 20 March to 30
    // September, and the app's big number is the sum inside it.
    double seasonDistance() const;

    // The store writes the recording; it is given the recorder at start so
    // the pages can end a ride with a single call.
    void setRecorder(Recorder *recorder) { m_recorder = recorder; }
    Q_INVOKABLE QString saveRecording(const QString &title, const QString &bike,
                                      const QString &note);

    // Writes the recorded line and its record; returns the new ride's id.
    QString addRecorded(const Track &track, const QString &title,
                        const QString &bike, const QString &note);
    // A ride the rider types in: kilometres and a date, no line.
    Q_INVOKABLE QString addManual(const QDateTime &when, double kilometres,
                                  const QString &title, const QString &bike,
                                  const QString &note);

    Q_INVOKABLE QVariantMap ride(const QString &id) const;
    Q_INVOKABLE bool remove(const QString &id);
    Q_INVOKABLE QString gpxPath(const QString &id) const;
    Q_INVOKABLE bool loadTrack(const QString &id, Track *track) const;

    void markUploaded(const QString &id, qlonglong remoteId);
    QList<Ride> pending() const;

    QString directory() const { return m_directory; }

signals:
    void countChanged();

private:
    void load();
    bool write(const Ride &ride);
    int indexOf(const QString &id) const;
    QString recordPath(const QString &id) const;

    QString m_directory;
    QList<Ride> m_rides;
    Recorder *m_recorder;
};

#endif
