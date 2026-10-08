#include "api.h"

#include "http.h"
#include "json.h"
#include "ridestore.h"
#include "settings.h"
#include "track.h"

#include <QDateTime>
#include <QDebug>

namespace
{
const char *BaseUrl = "https://dashboard.radelt.at/api/v2";

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
    m_open(0)
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
    QVariantMap body;
    // The app sends the field as "email" even when a user name is typed;
    // the server takes both in that field.
    body.insert("email", user);
    body.insert("password", password);
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
    m_settings->setToken(QString());
    emit personChanged();
    emit dashboardChanged();
    emit bikesChanged();
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

    QVariantMap body;
    // The field names are the ones the app's own binary carries. distance
    // in metres and duration in seconds follow the units the platform
    // aggregates into its km_* statistics.
    body.insert("distance", ride.value("distance").toDouble());
    const int duration = ride.value("movingSeconds").toInt() > 0
                         ? ride.value("movingSeconds").toInt()
                         : ride.value("totalSeconds").toInt();
    body.insert("duration", duration);
    body.insert("manual", ride.value("manual").toBool());
    body.insert("date", stamp(ride.value("start").toDateTime()));
    // A stable identifier of our own: the server deduplicates on it, so a
    // ride sent twice after a dropped connection does not count twice.
    body.insert("externalId", "harbour-radelt:" + rideId);
    if (!ride.value("note").toString().isEmpty())
        body.insert("comment", ride.value("note").toString());
    const int bike = m_bikeNames.indexOf(ride.value("bike").toString());
    if (bike >= 0 && bike < m_bikeIds.size())
        body.insert("bikeId", m_bikeIds.at(bike));

    send(RideSaveRequest, "POST", "/ride/save", body, rideId);
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
        entry.insert("latitude", point.latitude);
        entry.insert("longitude", point.longitude);
        if (point.hasAltitude())
            entry.insert("altitude", point.altitude);
        if (point.hasAccuracy())
            entry.insert("accuracy", point.accuracy);
        if (point.speed >= 0)
            entry.insert("speed", point.speed);
        entry.insert("timestamp", stamp(point.time));
        points.append(entry);
    }

    QVariantMap body;
    body.insert("rideId", remoteId);
    body.insert("externalId", "harbour-radelt:" + rideId);
    body.insert("points", points);

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
        QVariantList list = data.toList();
        if (list.isEmpty())
            list = map.value("bikes").toList();
        for (int i = 0; i < list.size(); ++i) {
            const QVariantMap bike = list.at(i).toMap();
            const QString name = (bike.value("brand").toString() + " "
                                  + bike.value("model").toString()).trimmed();
            m_bikeNames << (name.isEmpty() ? tr("Bike %1").arg(i + 1) : name);
            m_bikeIds << bike.value("bikeId").toLongLong();
        }
        emit bikesChanged();
        break;
    }
    case DashboardRequest:
        m_dashboard = map;
        emit dashboardChanged();
        break;
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
