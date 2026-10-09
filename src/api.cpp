#include "api.h"

#include "http.h"
#include "json.h"
#include "ridestore.h"
#include "settings.h"
#include "track.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDebug>
#include <QLocale>
#include <QUrl>

namespace
{
const char *BaseUrl = "https://dashboard.radelt.at/api/v2";

// Das Salz der Anmelde-Signatur, wortwoertlich aus dem Binaer der
// Original-App. Ohne die Signatur nimmt der Server keine Anmeldung an.
const char *LoginSalt = "TourDeBoedele";

// Die Protokollfassung, die wir dem Server nennen: seine Kopfzeile
// x-minimum-required-app-version steht derzeit auf 10.3.0.
const char *ProtocolVersion = "10.4.2";

// Laravel's own date format, which is what the app's binary carries.
QString stamp(const QDateTime &when)
{
    return when.toUTC().toString("yyyy-MM-dd HH:mm:ss");
}
}

Api::Api(Settings *settings, RideStore *rides, QObject *parent) :
    QObject(parent),
    m_settings(settings),
    m_rides(rides),
#if QT_VERSION >= 0x050000
    m_http(new NetworkHttp(this)),
#else
    m_http(new ProcessHttp(this)),
#endif
    m_nextTag(1),
    m_open(0),
    m_searching(false)
{
    connect(m_http, SIGNAL(finished(int,int,QByteArray,QString)),
            this, SLOT(replyFinished(int,int,QByteArray,QString)));
    connect(m_http, SIGNAL(cookie(QString,QString)),
            this, SLOT(cookieReceived(QString,QString)));
}

QString Api::displayName() const
{
    const QString first = m_person.value("firstName").toString();
    const QString last = m_person.value("lastName").toString();
    const QString name = (first + " " + last).trimmed();
    if (!name.isEmpty())
        return name;
    if (m_person.contains("nickname"))
        return m_person.value("nickname").toString();
    return m_settings->email();
}

void Api::setError(const QString &text)
{
    if (m_lastError == text)
        return;
    m_lastError = text;
    emit lastErrorChanged();
}

void Api::setToken(const QString &token)
{
    if (m_token == token)
        return;
    m_token = token;
    m_settings->setToken(token);
    emit loggedInChanged();
}

int Api::send(Kind kind, const QString &verb, const QString &path,
              const QVariantMap &body, const QString &rideId)
{
    QStringList headers;
    if (!m_token.isEmpty()) {
        // Nachgemessen am Original (doc/api-echte-antworten.md): die
        // Plattform weist ueber den Keks fw_login aus. Derselbe Wert als
        // "Authorization: Bearer" gibt 401 -- der Token ist ein Keks.
        headers << "Cookie" << ("fw_login=" + m_token);
    }

    Pending pending;
    pending.kind = kind;
    pending.rideId = rideId;
    pending.remoteId = 0;

    const int tag = m_nextTag++;
    m_pending.insert(tag, pending);
    ++m_open;
    emit busyChanged();

    m_http->request(tag, verb, QString::fromLatin1(BaseUrl) + path,
                    body.isEmpty() ? QByteArray() : Json::serialise(body), headers);
    return tag;
}

void Api::login(const QString &user, const QString &password)
{
    setError(QString());

    // Der Anmelde-Koerper stammt aus dem rekonstruierten Dart-Abbild der
    // Original-App (_$LoginRequestToJson, siehe doc/api.md §11) und ist am
    // Server geprueft. Zwei Dinge daran sind nicht zu erraten:
    //
    //   * Die Kennung heisst "user", nicht "email" -- obwohl die
    //     Registrierung auf derselben Schnittstelle "email" nimmt.
    //   * Es gibt eine Signatur "secure" ueber Kennung und Passwort mit
    //     einem festen Salz. Ohne sie antwortet der Server auf jeden
    //     Versuch mit authentication_failed, egal wie richtig der Rest ist.
    const QByteArray roh = (user + password + QLatin1String(LoginSalt)).toUtf8();
    const QString secure =
        QString::fromLatin1(QCryptographicHash::hash(roh, QCryptographicHash::Md5).toHex());

    QVariantMap body;
    body.insert("secure", secure);
    body.insert("user", user);
    body.insert("password", password);
    // Kein Push-Dienst in dieser App; das Feld gehoert aber in den Koerper.
    body.insert("oneSignalUserId", QVariant());
    body.insert("platform", "android");
    // Der Server verlangt eine Fassung, die nicht aelter ist als die in
    // seinem Kopf x-minimum-required-app-version (derzeit 10.3.0). Das ist
    // die Fassung der Original-App, nicht unsere eigene Zaehlung -- sie
    // sagt dem Server, welches Protokoll wir sprechen.
    body.insert("appVersion", ProtocolVersion);
    body.insert("language", QLocale::system().name().left(2));

    m_settings->setEmail(user);
    send(LoginRequest, "POST", "/login", body);
}

void Api::logout()
{
    // There is no logout route: the token is simply dropped. Anything
    // tied to the account goes with it, so a second rider on the same
    // phone does not see the first one's numbers.
    setToken(QString());
    m_person.clear();
    m_dashboard.clear();
    m_bikeNames.clear();
    m_bikeIds.clear();
    m_bikes.clear();
    m_friends.clear();
    m_organisations.clear();
    m_shareUrl.clear();
    m_yearStats.clear();
    m_months.clear();
    m_timeline.clear();
    m_trophies.clear();
    m_openChallenges.clear();
    m_myChallenges.clear();
    m_settings->setToken(QString());
    emit personChanged();
    emit dashboardChanged();
    emit bikesChanged();
    emit communityChanged();
    emit timelineChanged();
    emit challengesChanged();
}

void Api::resume()
{
    const QString token = m_settings->token();
    if (token.isEmpty())
        return;
    m_token = token;
    emit loggedInChanged();
    send(PersonRequest, "GET", "/person", QVariantMap());
}

void Api::refresh()
{
    if (!loggedIn())
        return;
    send(DashboardRequest, "GET", "/dashboard", QVariantMap());
    send(BikesRequest, "GET", "/bikes", QVariantMap());
}

void Api::saveBike(const QVariantMap &bike)
{
    if (!loggedIn())
        return;
    // The fields are the ones the platform hands out in /bikes; an entry
    // without an id is a new bike.
    QVariantMap body;
    if (bike.value("id").toLongLong() > 0)
        body.insert("id", bike.value("id").toLongLong());
    body.insert("name", bike.value("name").toString());
    body.insert("isEbike", bike.value("isEbike").toBool());
    body.insert("isMain", bike.value("isMain").toBool());
    body.insert("entryType", bike.value("entryType").toString().isEmpty()
                             ? QString("DISTANCE") : bike.value("entryType").toString());
    send(BikeSaveRequest, "POST", "/bike/save", body);
}

void Api::deleteBike(qlonglong bikeId)
{
    if (!loggedIn() || bikeId <= 0)
        return;
    QVariantMap body;
    body.insert("id", bikeId);
    send(BikeDeleteRequest, "DELETE", "/bike/delete", body);
}

void Api::fetchCommunity()
{
    if (!loggedIn())
        return;
    send(FriendsRequest, "GET", "/friends", QVariantMap());
    send(OrganisationsRequest, "GET", "/organisations/preferred", QVariantMap());
    send(ShareUrlRequest, "GET", "/friends/getshareurl", QVariantMap());
}

void Api::fetchTimeline()
{
    if (!loggedIn())
        return;
    send(TimelineRequest, "GET", "/timelineevents", QVariantMap());
    send(TrophiesRequest, "GET", "/trophies", QVariantMap());
}

void Api::fetchChallenges()
{
    if (!loggedIn())
        return;
    send(ChallengesRequest, "GET", "/challenges/active", QVariantMap());
}

void Api::joinChallenge(qlonglong challengeId)
{
    if (!loggedIn() || challengeId <= 0)
        return;
    // CampaignSignupRequest aus dem Binär: challengeId, organisationIds,
    // journeyBikeId, journeyDistance. Die Organisationen übernimmt der
    // Dienst aus dem Profil, wenn wir keine nennen; das Rad ist das
    // Hauptrad.
    QVariantMap body;
    body.insert("challengeId", challengeId);
    body.insert("organisationIds", QVariantList());
    const qlonglong rad = bikeIdFor(QString());
    if (rad > 0)
        body.insert("journeyBikeId", rad);
    send(ChallengeActionRequest, "PUT", "/challenges/signup", body);
}

void Api::leaveChallenge(qlonglong challengeId)
{
    if (!loggedIn() || challengeId <= 0)
        return;
    QVariantMap body;
    body.insert("challengeId", challengeId);
    send(ChallengeActionRequest, "POST", "/challenges/signoff", body);
}

void Api::addCyclingDay(qlonglong challengeId, const QDate &day)
{
    if (!loggedIn() || challengeId <= 0)
        return;
    // SaveRzaRequest: challengeId, dates, countDay. "dates" ist eine Liste,
    // damit sich mehrere Tage auf einmal nachtragen lassen.
    QVariantMap body;
    body.insert("challengeId", challengeId);
    QVariantList tage;
    tage << (day.isValid() ? day : QDate::currentDate()).toString("yyyy-MM-dd");
    body.insert("dates", tage);
    body.insert("countDay", true);
    send(CyclingDayRequest, "PUT", "/journeylog/save", body);
}

void Api::searchFriends(const QString &text)
{
    if (!loggedIn())
        return;
    if (text.trimmed().length() < 3) {
        // Die Original-App verlangt dasselbe ("Bitte gib mindestens 3
        // Buchstaben ein."); mit weniger antwortet der Server mit einer
        // Fundgrube, die niemandem hilft.
        m_found.clear();
        m_searching = false;
        emit searchChanged();
        return;
    }
    m_searching = true;
    emit searchChanged();
    QString pfad = "/friends/search?query=";
    pfad += QString::fromLatin1(QUrl::toPercentEncoding(text.trimmed()));
    send(SearchRequest, "GET", pfad, QVariantMap());
}

void Api::requestFriend(qlonglong friendId)
{
    if (!loggedIn() || friendId <= 0)
        return;
    QVariantMap body;
    body.insert("friendId", friendId);
    send(FriendActionRequest, "POST", "/friend/request", body);
}

void Api::acceptFriend(qlonglong friendId)
{
    if (!loggedIn() || friendId <= 0)
        return;
    QVariantMap body;
    body.insert("friendId", friendId);
    send(FriendActionRequest, "POST", "/friend/accept", body);
}

void Api::declineFriend(qlonglong friendId)
{
    if (!loggedIn() || friendId <= 0)
        return;
    QVariantMap body;
    body.insert("friendId", friendId);
    send(FriendActionRequest, "POST", "/friend/decline", body);
}

void Api::removeFriend(qlonglong friendId)
{
    if (!loggedIn() || friendId <= 0)
        return;
    QVariantMap body;
    body.insert("friendId", friendId);
    send(FriendActionRequest, "DELETE", "/friend/remove", body);
}

void Api::uploadRide(const QString &rideId)
{
    if (!loggedIn()) {
        setError(tr("Not signed in"));
        emit rideUploaded(rideId, false, lastError());
        return;
    }

    const QVariantMap ride = m_rides->ride(rideId);
    if (ride.isEmpty()) {
        emit rideUploaded(rideId, false, tr("Ride is gone"));
        return;
    }

    // Ohne Rad nimmt der Dienst gar nichts an: bikeId ist das einzige
    // Pflichtfeld und wird vor jeder anderen Pruefung aufgeloest -- fehlt
    // es, stuerzt die Route ab (HTTP 500), statt es zu sagen.
    const qlonglong bikeId = bikeIdFor(ride.value("bike").toString());
    if (bikeId <= 0) {
        emit rideUploaded(rideId, false,
                          tr("No bike known yet — open the bikes page once"));
        return;
    }

    // Die Felder sind die von CreateTrackingRequest aus dem Binaer der
    // Original-App (doc/api.md §11).
    QVariantMap body;
    body.insert("bikeId", bikeId);
    const QDateTime start = ride.value("start").toDateTime().toLocalTime();
    body.insert("date", start.toString("yyyy-MM-dd"));
    // Ein unlesbares Datum weist der Dienst **nicht** zurueck, er legt die
    // Fahrt im Jahr -000001 ab. Das Format muss also hier stimmen.
    body.insert("description", ride.value("title").toString().isEmpty()
                               ? ride.value("note").toString()
                               : ride.value("title").toString());
    body.insert("altitude", qRound(ride.value("ascent").toDouble()));
    // **Kilometer, nicht Meter**: die Spalte dahinter heisst km_cache, und
    // die Statistik zaehlt in km. In Metern waere jede Fahrt tausendfach
    // zu lang.
    body.insert("distance", ride.value("distance").toDouble() / 1000.0);
    const int bewegt = ride.value("movingSeconds").toInt();
    const int gesamt = ride.value("totalSeconds").toInt();
    if (gesamt > 0) {
        body.insert("timeStart", stamp(start));
        body.insert("timeEnd", stamp(start.addSecs(gesamt)));
        // Die Pause ist, was zwischen Start und Ende nicht gefahren wurde.
        body.insert("pauseTime", qMax(0, gesamt - bewegt));
    }

    send(RideSaveRequest, "POST", "/ride/save", body, rideId);
}

qlonglong Api::bikeIdFor(const QString &name) const
{
    // Das benannte Rad, sonst das Hauptrad, sonst das erste bekannte.
    for (int i = 0; i < m_bikes.size(); ++i) {
        const QVariantMap bike = m_bikes.at(i).toMap();
        if (!name.isEmpty() && bike.value("name").toString() == name)
            return bike.value("id").toLongLong();
    }
    for (int i = 0; i < m_bikes.size(); ++i) {
        const QVariantMap bike = m_bikes.at(i).toMap();
        if (bike.value("isMain").toBool())
            return bike.value("id").toLongLong();
    }
    return m_bikes.isEmpty() ? 0 : m_bikes.first().toMap().value("id").toLongLong();
}

void Api::uploadPending()
{
    const QList<Ride> pending = m_rides->pending();
    for (int i = 0; i < pending.size(); ++i) {
        const QString id = pending.at(i).id;
        if (!m_queue.contains(id))
            m_queue.append(id);
    }
    // One at a time: the phone is on a bicycle, and twenty parallel
    // requests over a flaky connection only make twenty timeouts.
    if (!m_queue.isEmpty()) {
        const QString next = m_queue.takeFirst();
        uploadRide(next);
    }
}

void Api::sendTrack(const QString &rideId, qlonglong remoteId)
{
    Track track;
    if (!m_rides->loadTrack(rideId, &track) || track.isEmpty())
        return;

    QVariantList points;
    const QList<TrackPoint> &recorded = track.points();
    for (int i = 0; i < recorded.size(); ++i) {
        const TrackPoint &point = recorded.at(i);
        QVariantMap entry;
        // TrackData aus dem Binaer: genau diese fuenf Felder, keine
        // Genauigkeit -- die interessiert den Dienst nicht.
        entry.insert("latitude", point.latitude);
        entry.insert("longitude", point.longitude);
        entry.insert("speed", point.speed >= 0 ? point.speed : 0.0);
        entry.insert("altitude", point.hasAltitude() ? point.altitude : 0.0);
        entry.insert("timestamp", stamp(point.time));
        points.append(entry);
    }

    QVariantMap body;
    body.insert("rideId", remoteId);
    body.insert("trackData", points);

    send(TrackSaveRequest, "PUT", "/ride/track/save", body, rideId);
}

void Api::cookieReceived(const QString &name, const QString &value)
{
    // fw_login is the platform's token: a year's worth of login, handed
    // out by /login and expected back on every call.
    if (name == QLatin1String("fw_login") && !value.isEmpty())
        setToken(value);
}

void Api::replyFinished(int tag, int status, const QByteArray &body, const QString &error)
{
    const Pending pending = m_pending.take(tag);
    if (m_open > 0)
        --m_open;
    emit busyChanged();

    if (!error.isEmpty()) {
        setError(error);
        if (pending.kind == RideSaveRequest || pending.kind == TrackSaveRequest)
            emit rideUploaded(pending.rideId, false, error);
        return;
    }

    if (status == 401) {
        // The token expired or was withdrawn; ask for the password again
        // rather than retrying forever.
        setToken(QString());
        setError(tr("Please sign in again"));
        if (pending.kind == RideSaveRequest || pending.kind == TrackSaveRequest)
            emit rideUploaded(pending.rideId, false, lastError());
        return;
    }

    QString parseError;
    const QVariant parsed = Json::parse(body, &parseError);
    if (parsed.type() != QVariant::Map) {
        setError(tr("The server answered something unexpected (%1)").arg(status));
        qWarning() << "radelt: answer was not JSON" << status << parseError
                   << body.left(200);
        if (pending.kind == RideSaveRequest || pending.kind == TrackSaveRequest)
            emit rideUploaded(pending.rideId, false, lastError());
        return;
    }

    handleEnvelope(pending, parsed.toMap());
}

void Api::handleEnvelope(const Pending &pending, const QVariantMap &envelope)
{
    const bool ok = envelope.value("success").toBool();
    if (!ok) {
        QString message = envelope.value("message").toString();
        const QVariant problem = envelope.value("error");
        if (problem.type() == QVariant::Map) {
            // Laravel's validation answer: field -> list of sentences.
            // Showing them is what makes a wrong guess about the field
            // names visible instead of silent.
            const QVariantMap fields = problem.toMap();
            QStringList parts;
            for (QVariantMap::const_iterator it = fields.constBegin();
                 it != fields.constEnd(); ++it) {
                parts << (it.key() + ": " + it.value().toStringList().join(" "));
            }
            if (!parts.isEmpty())
                message += "\n" + parts.join("\n");
        }
        if (message.isEmpty())
            message = tr("The server refused the request");
        setError(message);
        if (pending.kind == SearchRequest) {
            m_found.clear();
            m_searching = false;
            emit searchChanged();
        }
        if (pending.kind == RideSaveRequest || pending.kind == TrackSaveRequest)
            emit rideUploaded(pending.rideId, false, message);
        return;
    }

    setError(QString());
    const QVariant data = envelope.value("data");
    const QVariantMap map = data.toMap();

    switch (pending.kind) {
    case LoginRequest: {
        // The token usually arrives as the fw_login cookie, which
        // cookieReceived() has already stored by now; the body is only
        // consulted when it did not.
        QString token = map.value("api_token").toString();
        if (token.isEmpty())
            token = map.value("token").toString();
        if (token.isEmpty())
            token = Json::value(data, "user/api_token").toString();
        if (!token.isEmpty())
            setToken(token);
        if (!loggedIn()) {
            setError(tr("The server sent no token"));
            qWarning() << "radelt: login answer without a token" << map.keys();
            return;
        }
        if (map.contains("person"))
            m_person = map.value("person").toMap();
        else
            m_person = map;
        emit personChanged();
        refresh();
        break;
    }
    case PersonRequest:
        m_person = map.contains("person") ? map.value("person").toMap() : map;
        emit personChanged();
        break;
    case BikesRequest: {
        m_bikeNames.clear();
        m_bikeIds.clear();
        m_bikes.clear();
        QVariantList list = data.toList();
        if (list.isEmpty())
            list = map.value("bikes").toList();
        for (int i = 0; i < list.size(); ++i) {
            // Measured against the real answer (doc/api-echte-antworten.md):
            // a bike is { id, name, entryType, isEbike, isMain,
            // canBeDeleted, isBikeDeactivateable, isActive, ... }.
            const QVariantMap bike = list.at(i).toMap();
            const QString name = bike.value("name").toString();
            m_bikeNames << (name.isEmpty() ? tr("Bike %1").arg(i + 1) : name);
            m_bikeIds << bike.value("id").toLongLong();
            m_bikes << bike;
        }
        emit bikesChanged();
        break;
    }
    case BikeSaveRequest:
    case BikeDeleteRequest:
        // The server is the authority on the list; ask it again rather
        // than patching our copy and hoping it matches.
        send(BikesRequest, "GET", "/bikes", QVariantMap());
        break;
    case FriendsRequest:
        m_friends = map.value("friends").toList();
        if (m_friends.isEmpty())
            m_friends = data.toList();
        emit communityChanged();
        break;
    case OrganisationsRequest:
        m_organisations = map.value("organisations").toList();
        if (m_organisations.isEmpty())
            m_organisations = data.toList();
        emit communityChanged();
        break;
    case ChallengesRequest: {
        // Die Antwort trennt, was offen steht, von dem, wo man dabei ist.
        const QVariantMap ch = map.value("challenges").toMap();
        m_openChallenges = ch.value("available").toList();
        m_myChallenges = ch.value("signedup").toList();
        emit challengesChanged();
        break;
    }
    case ChallengeActionRequest:
    case CyclingDayRequest:
        // Der Dienst ist die Wahrheit; neu lesen statt mitrechnen. Das
        // gilt hier besonders: eine 500 heißt bei manchen Routen
        // trotzdem "getan".
        fetchChallenges();
        send(DashboardRequest, "GET", "/dashboard", QVariantMap());
        break;
    case SearchRequest:
        // Die Suche liefert people[] mit kleingeschriebenen Feldern
        // (firstname/lastname), anders als /friends -- gemessen.
        m_found = map.value("people").toList();
        m_searching = false;
        emit searchChanged();
        break;
    case FriendActionRequest:
        // Der Server ist die Wahrheit über den Stand der Freundschaft.
        fetchCommunity();
        break;
    case ShareUrlRequest:
        m_shareUrl = map.value("shareUrl").toString();
        emit communityChanged();
        break;
    case DashboardRequest: {
        m_dashboard = map;
        // Die Jahresstatistik steckt unter dem Jahr als Schlüssel, und die
        // Monate darunter noch einmal unter ihrem ersten Tag. Beides wird
        // hier flach gemacht, damit die Seite nicht raten muss, welches
        // Jahr das laufende ist. Die Schlüssel sind hier snake_case --
        // anders als im Rest der Schnittstelle, gemessen.
        m_yearStats.clear();
        m_months.clear();
        const QVariantMap jahre = map.value("yearlyStatistics").toMap();
        if (!jahre.isEmpty()) {
            // Das höchste Jahr ist das laufende; QVariantMap sortiert nach
            // Schlüssel, also ist der letzte der richtige.
            const QString jahr = jahre.keys().last();
            m_yearStats = jahre.value(jahr).toMap();
            m_yearStats.insert("year", jahr);
            const QVariantMap monate = m_yearStats.value("months").toMap();
            for (QVariantMap::const_iterator it = monate.constBegin();
                 it != monate.constEnd(); ++it) {
                QVariantMap eintrag = it.value().toMap();
                eintrag.insert("month", it.key());
                m_months << eintrag;
            }
            m_yearStats.remove("months");
        }
        // Das Dashboard liefert nebenbei einen frischen Token mit.
        const QString frisch = map.value("apiToken").toString();
        if (!frisch.isEmpty())
            setToken(frisch);
        emit dashboardChanged();
        break;
    }
    case TimelineRequest: {
        m_timeline = data.toList();
        if (m_timeline.isEmpty())
            m_timeline = map.value("timeline").toList();
        if (m_timeline.isEmpty())
            m_timeline = map.value("events").toList();
        emit timelineChanged();
        break;
    }
    case TrophiesRequest: {
        m_trophies = data.toList();
        if (m_trophies.isEmpty())
            m_trophies = map.value("trophies").toList();
        emit timelineChanged();
        break;
    }
    case RideSaveRequest: {
        qlonglong remoteId = map.value("rideId").toLongLong();
        if (!remoteId)
            remoteId = map.value("activityId").toLongLong();
        m_rides->markUploaded(pending.rideId, remoteId);
        emit rideUploaded(pending.rideId, true, envelope.value("message").toString());
        sendTrack(pending.rideId, remoteId);
        if (!m_queue.isEmpty())
            uploadRide(m_queue.takeFirst());
        break;
    }
    case TrackSaveRequest:
        // The ride already counts; the track is the picture that goes with
        // it, so a failure here must not undo the upload.
        break;
    }
}
