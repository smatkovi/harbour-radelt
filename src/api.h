#ifndef API_H
#define API_H

#include <QHash>
#include <QObject>
#include <QStringList>
#include <QVariantMap>

class Http;
class RideStore;
class Settings;

// The client for the "Österreich radelt" platform at dashboard.radelt.at.
//
// What the original app does is reconstructed from its own binary
// (doc/api.md): token in an Authorization header, every answer wrapped in
// {success, message, error, data} -- and note that a refused login arrives
// as HTTP 200 with success:false, so the status alone says nothing.
//
// Where the reconstruction is not certain -- the exact shape of a ride and
// of its track -- the request is built from the field names that are
// provably in the app, and the server's own error object is kept in
// lastError so a wrong guess shows up as text rather than as silence.
class Api : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loggedIn READ loggedIn NOTIFY loggedInChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString displayName READ displayName NOTIFY personChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QStringList bikes READ bikes NOTIFY bikesChanged)
    // The bikes with everything the pages show: name, e-bike, main bike.
    Q_PROPERTY(QVariantList bikeList READ bikeList NOTIFY bikesChanged)
    Q_PROPERTY(QVariantList friends READ friends NOTIFY communityChanged)
    Q_PROPERTY(QVariantList organisations READ organisations NOTIFY communityChanged)
    Q_PROPERTY(QString shareUrl READ shareUrl NOTIFY communityChanged)
    Q_PROPERTY(QVariantList foundPeople READ foundPeople NOTIFY searchChanged)
    Q_PROPERTY(bool searching READ searching NOTIFY searchChanged)
    Q_PROPERTY(QVariantMap dashboard READ dashboard NOTIFY dashboardChanged)
    // Die Jahreszahlen der Übersicht, flach und schon umgerechnet.
    Q_PROPERTY(QVariantMap yearStats READ yearStats NOTIFY dashboardChanged)
    Q_PROPERTY(QVariantList months READ months NOTIFY dashboardChanged)
    Q_PROPERTY(QVariantList timeline READ timeline NOTIFY timelineChanged)
    Q_PROPERTY(QVariantList trophies READ trophies NOTIFY timelineChanged)

public:
    Api(Settings *settings, RideStore *rides, QObject *parent = 0);

    bool loggedIn() const { return !m_token.isEmpty(); }
    bool busy() const { return m_open > 0; }
    QString displayName() const;
    QString lastError() const { return m_lastError; }
    QStringList bikes() const { return m_bikeNames; }
    QVariantList bikeList() const { return m_bikes; }
    QVariantList friends() const { return m_friends; }
    QVariantList organisations() const { return m_organisations; }
    QString shareUrl() const { return m_shareUrl; }
    QVariantList foundPeople() const { return m_found; }
    bool searching() const { return m_searching; }
    QVariantMap dashboard() const { return m_dashboard; }
    QVariantMap yearStats() const { return m_yearStats; }
    QVariantList months() const { return m_months; }
    QVariantList timeline() const { return m_timeline; }
    QVariantList trophies() const { return m_trophies; }

public slots:
    void login(const QString &user, const QString &password);
    void logout();
    // Picks the stored token back up at start; does not ask the network
    // until something is actually wanted from it.
    void resume();

    void uploadRide(const QString &rideId);
    void uploadPending();
    void refresh();                     // dashboard and bikes

    // Bikes. The platform keeps one "main" bike that every ride falls back
    // to; a bike that already carries rides cannot be deleted, only
    // deactivated, which is why the list hands those flags to the page.
    void saveBike(const QVariantMap &bike);
    void deleteBike(qlonglong bikeId);

    // Community: the friends one rides against, and the organisations one
    // rides for.
    void fetchCommunity();

    // Verlauf und Trophäen für die Verlaufsseite.
    void fetchTimeline();

    // Freund:innen. Die Suche braucht mindestens drei Buchstaben -- so
    // hält es die Original-App, und der Server findet mit weniger ohnehin
    // zu viel. Die Aktionen nehmen alle die Kennung der anderen Person
    // unter dem Namen "friendId" (am Server nachgemessen).
    Q_INVOKABLE void searchFriends(const QString &text);
    Q_INVOKABLE void requestFriend(qlonglong friendId);
    Q_INVOKABLE void acceptFriend(qlonglong friendId);
    Q_INVOKABLE void declineFriend(qlonglong friendId);
    Q_INVOKABLE void removeFriend(qlonglong friendId);

signals:
    void loggedInChanged();
    void busyChanged();
    void personChanged();
    void lastErrorChanged();
    void bikesChanged();
    void communityChanged();
    void searchChanged();
    void timelineChanged();
    void dashboardChanged();
    void rideUploaded(const QString &rideId, bool ok, const QString &message);
    // The server says this app is too old for it; the pages show a hint.
    void appTooOld(const QString &minimumVersion);

private slots:
    void replyFinished(int tag, int status, const QByteArray &body, const QString &error);
    void cookieReceived(const QString &name, const QString &value);

private:
    enum Kind { LoginRequest, PersonRequest, BikesRequest, DashboardRequest,
                RideSaveRequest, TrackSaveRequest, BikeSaveRequest,
                BikeDeleteRequest, FriendsRequest, OrganisationsRequest,
                ShareUrlRequest, TimelineRequest, TrophiesRequest,
                SearchRequest, FriendActionRequest };

    struct Pending
    {
        Pending() : kind(LoginRequest) {}
        Kind kind;
        QString rideId;
        qlonglong remoteId;
    };

    int send(Kind kind, const QString &verb, const QString &path,
             const QVariantMap &body, const QString &rideId = QString());
    void setError(const QString &text);
    void setToken(const QString &token);
    void handleEnvelope(const Pending &pending, const QVariantMap &envelope);
    void sendTrack(const QString &rideId, qlonglong remoteId);

    Settings *m_settings;
    RideStore *m_rides;
    Http *m_http;
    QHash<int, Pending> m_pending;
    QVariantMap m_person;
    QVariantMap m_dashboard;
    QStringList m_bikeNames;
    QList<qlonglong> m_bikeIds;
    QVariantList m_bikes;
    QVariantList m_friends;
    QVariantList m_organisations;
    QString m_shareUrl;
    QVariantMap m_yearStats;
    QVariantList m_months;
    QVariantList m_timeline;
    QVariantList m_trophies;
    QVariantList m_found;
    bool m_searching;
    QString m_token;
    QString m_lastError;
    QStringList m_queue;                // ride ids waiting to go up
    int m_nextTag;
    int m_open;
};

#endif
