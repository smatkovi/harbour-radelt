#ifndef STUBS_H
#define STUBS_H

#include <QAbstractListModel>
#include <QDate>
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

// Die Attrappe spiegelt src/api.h. Sie muss mitwachsen: eine Seite, die
// eine Eigenschaft anspricht, die es hier nicht gibt, faellt dem Pruefer
// sonst nicht auf -- und ein Connections-Block auf ein Signal, das es
// nicht gibt, ist in QML ein harter Fehler. Was hier fehlt, findet erst
// das Geraet.
class StubApi : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loggedIn READ flag NOTIFY loggedInChanged)
    Q_PROPERTY(bool busy READ flag NOTIFY busyChanged)
    Q_PROPERTY(QString displayName READ text NOTIFY personChanged)
    Q_PROPERTY(QString lastError READ text NOTIFY lastErrorChanged)
    Q_PROPERTY(QStringList bikes READ list NOTIFY bikesChanged)
    Q_PROPERTY(QVariantList bikeList READ vlist NOTIFY bikesChanged)
    Q_PROPERTY(QVariantList friends READ vlist NOTIFY communityChanged)
    Q_PROPERTY(QVariantList organisations READ vlist NOTIFY communityChanged)
    Q_PROPERTY(QString shareUrl READ text NOTIFY communityChanged)
    Q_PROPERTY(QVariantList foundPeople READ vlist NOTIFY searchChanged)
    Q_PROPERTY(bool searching READ flag NOTIFY searchChanged)
    Q_PROPERTY(QVariantMap dashboard READ map NOTIFY dashboardChanged)
    Q_PROPERTY(QVariantList openChallenges READ vlist NOTIFY challengesChanged)
    Q_PROPERTY(QVariantList myChallenges READ vlist NOTIFY challengesChanged)
    Q_PROPERTY(QVariantList goals READ vlist NOTIFY goalsChanged)
    Q_PROPERTY(QVariantList goalTemplates READ vlist NOTIFY goalsChanged)
    Q_PROPERTY(QVariantMap person READ map NOTIFY personChanged)
    Q_PROPERTY(QVariantList news READ vlist NOTIFY newsChanged)
    Q_PROPERTY(QVariantList sponsors READ vlist NOTIFY newsChanged)
    Q_PROPERTY(QVariantList notifications READ vlist NOTIFY newsChanged)
    Q_PROPERTY(QVariantMap yearStats READ map NOTIFY dashboardChanged)
    Q_PROPERTY(QVariantList months READ vlist NOTIFY dashboardChanged)
    Q_PROPERTY(QVariantList timeline READ vlist NOTIFY timelineChanged)
    Q_PROPERTY(QVariantList trophies READ vlist NOTIFY timelineChanged)
    Q_PROPERTY(QVariantList journeyLogs READ vlist NOTIFY journeyLogsChanged)
    Q_PROPERTY(qlonglong journeyChallenge READ bignumber NOTIFY journeyLogsChanged)
    Q_PROPERTY(QVariantList poiRoutes READ vlist NOTIFY poisChanged)
    Q_PROPERTY(QVariantList pois READ vlist NOTIFY poisChanged)
    Q_PROPERTY(QString poiMessage READ text NOTIFY poisChanged)
public:
    bool flag() const { return false; }
    QString text() const { return QString(); }
    QStringList list() const { return QStringList(); }
    QVariantList vlist() const { return QVariantList(); }
    QVariantMap map() const { return QVariantMap(); }
    qlonglong bignumber() const { return 0; }

    Q_INVOKABLE void fetchChallenges() {}
    Q_INVOKABLE void joinChallenge(qlonglong) {}
    Q_INVOKABLE void leaveChallenge(qlonglong) {}
    Q_INVOKABLE void fetchJourneyLogs(qlonglong) {}
    Q_INVOKABLE void saveCyclingDays(qlonglong, const QStringList &, bool) {}
    Q_INVOKABLE void deleteCyclingDays(qlonglong, const QStringList &) {}
    Q_INVOKABLE void addCyclingDay(qlonglong, const QDate &) {}
    Q_INVOKABLE QVariantList monthGrid(int, int) const { return QVariantList(); }
    Q_INVOKABLE int loggedDayCount() const { return 0; }
    Q_INVOKABLE bool dayIsLogged(const QString &) const { return false; }
    Q_INVOKABLE void fetchPois(qlonglong) {}
    Q_INVOKABLE void collectHere(double, double) {}
    Q_INVOKABLE void markPoiFound(qlonglong) {}
    Q_INVOKABLE double metresBetween(double, double, double, double) const { return 0; }
    Q_INVOKABLE void fetchGoals() {}
    Q_INVOKABLE void saveGoal(const QString &, const QString &, double,
                              const QDate &, const QDate &, qlonglong) {}
    Q_INVOKABLE void deleteGoal(qlonglong) {}
    Q_INVOKABLE void selectGoal(qlonglong, bool) {}
    Q_INVOKABLE void updatePerson(const QVariantMap &) {}
    Q_INVOKABLE void setVisibleForFriends(bool) {}
    Q_INVOKABLE void updateRemoteRide(qlonglong, const QVariantMap &) {}
    Q_INVOKABLE void deleteRemoteRide(qlonglong) {}
    Q_INVOKABLE void fetchNews() {}
    Q_INVOKABLE void searchFriends(const QString &) {}
    Q_INVOKABLE void requestFriend(qlonglong) {}
    Q_INVOKABLE void acceptFriend(qlonglong) {}
    Q_INVOKABLE void declineFriend(qlonglong) {}
    Q_INVOKABLE void removeFriend(qlonglong) {}
public slots:
    void login(const QString &, const QString &) {}
    void logout() {}
    void resume() {}
    void uploadRide(const QString &) {}
    void uploadPending() {}
    void refresh() {}
    void saveBike(const QVariantMap &) {}
    void deleteBike(qlonglong) {}
    void fetchCommunity() {}
    void fetchTimeline() {}
signals:
    void changed();
    void loggedInChanged();
    void busyChanged();
    void personChanged();
    void lastErrorChanged();
    void bikesChanged();
    void communityChanged();
    void searchChanged();
    void timelineChanged();
    void challengesChanged();
    void newsChanged();
    void goalsChanged();
    void dashboardChanged();
    void journeyLogsChanged();
    void poisChanged();
    void rideUploaded(const QString &rideId, bool ok, const QString &message);
    void appTooOld(const QString &minimumVersion);
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
