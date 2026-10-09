#ifndef API_H
#define API_H

#include <QDate>
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
    // Aktionen: was man mitmachen kann und was man schon mitmacht.
    Q_PROPERTY(QVariantList openChallenges READ openChallenges NOTIFY challengesChanged)
    Q_PROPERTY(QVariantList myChallenges READ myChallenges NOTIFY challengesChanged)
    Q_PROPERTY(QVariantList goals READ goals NOTIFY goalsChanged)
    Q_PROPERTY(QVariantList goalTemplates READ goalTemplates NOTIFY goalsChanged)
    Q_PROPERTY(QVariantMap person READ person NOTIFY personChanged)
    Q_PROPERTY(QVariantList news READ news NOTIFY newsChanged)
    Q_PROPERTY(QVariantList sponsors READ sponsors NOTIFY newsChanged)
    Q_PROPERTY(QVariantList notifications READ notifications NOTIFY newsChanged)
    // Die Jahreszahlen der Übersicht, flach und schon umgerechnet.
    Q_PROPERTY(QVariantMap yearStats READ yearStats NOTIFY dashboardChanged)
    Q_PROPERTY(QVariantList months READ months NOTIFY dashboardChanged)
    Q_PROPERTY(QVariantList timeline READ timeline NOTIFY timelineChanged)
    // Fahrtenbuch: die eingetragenen Radeltage einer Aktion.
    Q_PROPERTY(QVariantList journeyLogs READ journeyLogs NOTIFY journeyLogsChanged)
    Q_PROPERTY(qlonglong journeyChallenge READ journeyChallenge NOTIFY journeyLogsChanged)
    // Orte sammeln: die Strecken einer Aktion und ihre Orte, flach dazu.
    Q_PROPERTY(QVariantList poiRoutes READ poiRoutes NOTIFY poisChanged)
    Q_PROPERTY(QVariantList pois READ pois NOTIFY poisChanged)
    Q_PROPERTY(QString poiMessage READ poiMessage NOTIFY poisChanged)
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
    QVariantList journeyLogs() const { return m_journeyLogs; }
    qlonglong journeyChallenge() const { return m_journeyChallenge; }
    QVariantList poiRoutes() const { return m_poiRoutes; }
    QVariantList pois() const { return m_pois; }
    QString poiMessage() const { return m_poiMessage; }
    QVariantList openChallenges() const { return m_openChallenges; }
    QVariantList myChallenges() const { return m_myChallenges; }
    QVariantList goals() const { return m_goals; }
    QVariantList goalTemplates() const { return m_goalTemplates; }
    QVariantMap person() const { return m_person; }
    QVariantList news() const { return m_news; }
    QVariantList sponsors() const { return m_sponsors; }
    QVariantList notifications() const { return m_notifications; }

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

    // Aktionen ("Kampagnen"). Fahrtenbuch und Orte haengen an einer
    // Aktion -- ohne Aktionskennung antwortet der Dienst dort mit
    // challenge_not_found. Ziele dagegen gehen auch ohne Aktion, das ist
    // am Server nachgemessen (doc/api.md).
    Q_INVOKABLE void fetchChallenges();
    Q_INVOKABLE void joinChallenge(qlonglong challengeId);
    Q_INVOKABLE void leaveChallenge(qlonglong challengeId);

    // Fahrtenbuch ("Radelt zur Arbeit"). Im Binär sind das drei Routen um
    // denselben Körper: GET /journeylogs?challengeId=N, PUT
    // /journeylog/save und DELETE /journeylog/delete. Alle drei nehmen
    // {challengeId, dates, countDay} -- DeleteRzaRequest::toJson ruft im
    // Binär wörtlich _$SaveRzaRequestToJson auf, die Körper sind also
    // gleich. Am Server nachgemessen: ohne challengeId antwortet die
    // Leseroute mit challenge_not_found (HTTP 400), mit einer Kennung
    // antwortet sie auch dann, wenn man bei der Aktion nicht mitmacht.
    Q_INVOKABLE void fetchJourneyLogs(qlonglong challengeId);
    Q_INVOKABLE void saveCyclingDays(qlonglong challengeId, const QStringList &dates,
                                     bool countDay);
    Q_INVOKABLE void deleteCyclingDays(qlonglong challengeId, const QStringList &dates);
    // "Ich bin heute geradelt": ein einzelner Tag, der häufige Fall.
    Q_INVOKABLE void addCyclingDay(qlonglong challengeId, const QDate &day);

    // Das Gitter für den Fahrtenbuch-Kalender. Die Rechnerei steckt
    // absichtlich hier und nicht in QML: das JavaScript von Qt 4.7 kann
    // "2026-10-09" nicht lesen, und ein halb geparstes Datum fällt erst
    // beim Eintragen auf. Jeder Eintrag hat date (yyyy-MM-dd), day,
    // inMonth und logged.
    Q_INVOKABLE QVariantList monthGrid(int year, int month) const;
    Q_INVOKABLE int loggedDayCount() const { return m_journeyLogs.size(); }
    Q_INVOKABLE bool dayIsLogged(const QString &date) const;

    // Orte sammeln. GET /pois?challengeId=N liefert die Strecken einer
    // Aktion mit ihren Orten (gemessen; ohne den Parameter gibt es eine
    // 500 -- das war kein fehlender Wettbewerb, sondern der fehlende
    // Parameter, siehe doc/api.md §12). Die Koordinaten kommen als
    // GeoJSON, also [Länge, Breite] -- in dieser Reihenfolge.
    Q_INVOKABLE void fetchPois(qlonglong challengeId);
    // Einsammeln wie im Original: die eigene Position als entarteter
    // Kasten an /pois/collect, und was zurückkommt, wird als gefunden
    // gemeldet. Den Abstand entscheidet also der Dienst, nicht wir -- die
    // Original-App hat dafür keinen eigenen Radius (nachgesehen in
    // calculateBounds: bei einem einzigen Punkt fallen die beiden Ecken
    // zusammen).
    Q_INVOKABLE void collectHere(double latitude, double longitude);
    Q_INVOKABLE void markPoiFound(qlonglong poiId);
    // Luftlinie in Metern, damit die Orteseite nach Nähe sortieren kann.
    Q_INVOKABLE double metresBetween(double lat1, double lon1,
                                     double lat2, double lon2) const;

    // Ziele. Datum als reines yyyy-MM-dd -- mit Uhrzeit stürzt die Route
    // ab, und goalId muss bei einem neuen Ziel fehlen oder null sein (eine
    // 0 bringt sie ebenfalls zum Absturz). Alles am Server nachgemessen.
    Q_INVOKABLE void fetchGoals();
    Q_INVOKABLE void saveGoal(const QString &name, const QString &beschreibung,
                              double kilometer, const QDate &von, const QDate &bis,
                              qlonglong goalId);
    Q_INVOKABLE void deleteGoal(qlonglong goalId);
    Q_INVOKABLE void selectGoal(qlonglong goalId, bool dabei);

    // Profil. Ein leerer Körper ist beim Dienst ein Leerlauf und gibt das
    // volle Profil zurück -- deshalb taugt dieselbe Route zum Abrufen.
    // Geprüft werden email, firstName und lastName (HTTP 409); nickname
    // nimmt der Dienst ungeprüft an.
    Q_INVOKABLE void updatePerson(const QVariantMap &felder);
    // Ohne diesen Schalter findet die Freundessuche einen nicht.
    Q_INVOKABLE void setVisibleForFriends(bool sichtbar);

    // Fahrten am Server ändern und löschen (Pflichtfeld rideId).
    Q_INVOKABLE void updateRemoteRide(qlonglong remoteId, const QVariantMap &felder);
    Q_INVOKABLE void deleteRemoteRide(qlonglong remoteId);

    // Nur lesen: Neuigkeiten, Sponsoren, Benachrichtigungen.
    Q_INVOKABLE void fetchNews();

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
    void journeyLogsChanged();
    void poisChanged();
    void challengesChanged();
    void newsChanged();
    void goalsChanged();
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
                SearchRequest, FriendActionRequest, ChallengesRequest,
                ChallengeActionRequest, CyclingDayRequest, PersonUpdateRequest,
                RideUpdateRequest, RideDeleteRequest, NewsRequest,
                SponsorsRequest, NotificationsRequest, GoalsRequest,
                GoalActionRequest, JourneyLogsRequest, JourneyLogActionRequest,
                PoisRequest, PoiCollectRequest, PoiFoundRequest };

    struct Pending
    {
        Pending() : kind(LoginRequest), remoteId(0), challengeId(0) {}
        Kind kind;
        QString rideId;
        qlonglong remoteId;
        qlonglong challengeId;
    };

    int send(Kind kind, const QString &verb, const QString &path,
             const QVariantMap &body, const QString &rideId = QString(),
             qlonglong challengeId = 0);
    void setError(const QString &text);
    void setToken(const QString &token);
    void handleEnvelope(const Pending &pending, const QVariantMap &envelope);
    void sendTrack(const QString &rideId, qlonglong remoteId);
    qlonglong bikeIdFor(const QString &name) const;

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
    QVariantList m_journeyLogs;
    qlonglong m_journeyChallenge;
    qlonglong m_poiChallenge;
    // Die Position, die als Kasten gemeldet wurde -- als Sicherung gegen
    // eine Antwort, die mehr hergibt als das, wovor man steht.
    double m_collectLat;
    double m_collectLon;
    bool m_collecting;
    QVariantList m_poiRoutes;
    QVariantList m_pois;
    QString m_poiMessage;
    QVariantList m_goals;
    QVariantList m_goalTemplates;
    QVariantList m_news;
    QVariantList m_sponsors;
    QVariantList m_notifications;
    QVariantList m_openChallenges;
    QVariantList m_myChallenges;
    QVariantList m_found;
    bool m_searching;
    QString m_token;
    QString m_lastError;
    QStringList m_queue;                // ride ids waiting to go up
    int m_nextTag;
    int m_open;
};

#endif
