#ifndef STUBS_H
#define STUBS_H

#include <QAbstractListModel>
#include <QDateTime>
#include <QObject>
#include <QStringList>
#include <QVariantMap>

// Stand-ins for the five objects the pages talk to.
//
// The checker only parses the QML and resolves its bindings, so the stubs
// need the right names and signatures and nothing else. They are written
// out rather than generated from the real headers because the real ones
// pull in QtMobility, which the build machine's desktop Qt does not have --
// and a stub that silently drifts from the real class is caught by the ARM
// build, which uses the real ones.
class StubFormat : public QObject
{
    Q_OBJECT
public:
    Q_INVOKABLE QString kilometres(double) const { return "0,0"; }
    Q_INVOKABLE QString metres(double) const { return "0"; }
    Q_INVOKABLE QString duration(int) const { return "0:00"; }
    Q_INVOKABLE QString speed(double) const { return "0,0"; }
    Q_INVOKABLE QString day(const QDateTime &) const { return "1.1.2026"; }
    Q_INVOKABLE QString dayAndTime(const QDateTime &) const { return "1.1.2026 00:00"; }
};

class StubRecorder : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool recording READ flag NOTIFY changed)
    Q_PROPERTY(bool paused READ flag WRITE setFlag NOTIFY changed)
    Q_PROPERTY(bool positionValid READ flag NOTIFY changed)
    Q_PROPERTY(double latitude READ number NOTIFY changed)
    Q_PROPERTY(double longitude READ number NOTIFY changed)
    Q_PROPERTY(double accuracy READ number NOTIFY changed)
    Q_PROPERTY(double distance READ number NOTIFY changed)
    Q_PROPERTY(double ascent READ number NOTIFY changed)
    Q_PROPERTY(int movingSeconds READ count NOTIFY changed)
    Q_PROPERTY(int totalSeconds READ count NOTIFY changed)
    Q_PROPERTY(double averageSpeed READ number NOTIFY changed)
    Q_PROPERTY(double currentSpeed READ number NOTIFY changed)
    Q_PROPERTY(int pointCount READ count NOTIFY changed)
    Q_PROPERTY(bool sourceAvailable READ flag CONSTANT)
public:
    bool flag() const { return false; }
    void setFlag(bool) {}
    double number() const { return 0; }
    int count() const { return 0; }
public slots:
    void startPositioning() {}
    void stopPositioning() {}
    void start() {}
    void stop() {}
    void reset() {}
signals:
    void changed();
};

class StubRides : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int pendingCount READ count NOTIFY countChanged)
    Q_PROPERTY(double totalDistance READ number NOTIFY countChanged)
    Q_PROPERTY(double todayDistance READ number NOTIFY countChanged)
    Q_PROPERTY(double seasonDistance READ number NOTIFY countChanged)
public:
    StubRides()
    {
        QHash<int, QByteArray> roles;
        roles.insert(Qt::UserRole + 1, "rideId");
        roles.insert(Qt::UserRole + 2, "start");
        roles.insert(Qt::UserRole + 3, "distance");
        roles.insert(Qt::UserRole + 4, "ascent");
        roles.insert(Qt::UserRole + 5, "movingSeconds");
        roles.insert(Qt::UserRole + 6, "totalSeconds");
        roles.insert(Qt::UserRole + 7, "title");
        roles.insert(Qt::UserRole + 8, "note");
        roles.insert(Qt::UserRole + 9, "bike");
        roles.insert(Qt::UserRole + 10, "uploaded");
        roles.insert(Qt::UserRole + 11, "remoteId");
        roles.insert(Qt::UserRole + 12, "manual");
        setRoleNames(roles);
    }
    int count() const { return 0; }
    double number() const { return 0; }
    int rowCount(const QModelIndex & = QModelIndex()) const { return 0; }
    QVariant data(const QModelIndex &, int) const { return QVariant(); }
    Q_INVOKABLE QVariantMap ride(const QString &) const
    {
        // A ride the pages can read every field off, so a typo in a
        // binding shows up as an undefined property rather than silence.
        QVariantMap map;
        map.insert("id", "2026-01-01T000000");
        map.insert("start", QDateTime::currentDateTime());
        map.insert("distance", 0.0);
        map.insert("ascent", 0.0);
        map.insert("movingSeconds", 0);
        map.insert("totalSeconds", 0);
        map.insert("title", QString());
        map.insert("note", QString());
        map.insert("bike", QString());
        map.insert("uploaded", false);
        map.insert("remoteId", 0);
        map.insert("manual", false);
        return map;
    }
    Q_INVOKABLE bool remove(const QString &) { return true; }
    Q_INVOKABLE QString gpxPath(const QString &) const { return QString(); }
    Q_INVOKABLE QString saveRecording(const QString &, const QString &, const QString &)
    { return QString(); }
    Q_INVOKABLE QString addManual(const QDateTime &, double, const QString &,
                                  const QString &, const QString &)
    { return QString(); }
signals:
    void countChanged();
};

class StubApi : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loggedIn READ flag NOTIFY changed)
    Q_PROPERTY(bool busy READ flag NOTIFY changed)
    Q_PROPERTY(QString displayName READ text NOTIFY changed)
    Q_PROPERTY(QString lastError READ text NOTIFY changed)
    Q_PROPERTY(QStringList bikes READ list NOTIFY changed)
    Q_PROPERTY(QVariantMap dashboard READ map NOTIFY changed)
public:
    bool flag() const { return false; }
    QString text() const { return QString(); }
    QStringList list() const { return QStringList(); }
    QVariantMap map() const { return QVariantMap(); }
public slots:
    void login(const QString &, const QString &) {}
    void logout() {}
    void resume() {}
    void uploadRide(const QString &) {}
    void uploadPending() {}
    void refresh() {}
signals:
    void changed();
    void loggedInChanged();
    void rideUploaded(const QString &rideId, bool ok, const QString &message);
};

class StubSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString email READ text WRITE setText NOTIFY changed)
    Q_PROPERTY(bool uploadAutomatically READ flag WRITE setFlag NOTIFY changed)
    Q_PROPERTY(bool keepDisplayOn READ flag WRITE setFlag NOTIFY changed)
    Q_PROPERTY(double accuracyLimit READ number WRITE setNumber NOTIFY changed)
public:
    QString text() const { return QString(); }
    void setText(const QString &) {}
    bool flag() const { return false; }
    void setFlag(bool) {}
    double number() const { return 50; }
    void setNumber(double) {}
signals:
    void changed();
};

#endif
