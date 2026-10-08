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
    Q_PROPERTY(QVariantMap dashboard READ dashboard NOTIFY dashboardChanged)

public:
    Api(Settings *settings, RideStore *rides, QObject *parent = 0);

    bool loggedIn() const { return !m_token.isEmpty(); }
    bool busy() const { return m_open > 0; }
    QString displayName() const;
    QString lastError() const { return m_lastError; }
    QStringList bikes() const { return m_bikeNames; }
    QVariantMap dashboard() const { return m_dashboard; }

public slots:
    void login(const QString &user, const QString &password);
    void logout();
    // Picks the stored token back up at start; does not ask the network
    // until something is actually wanted from it.
    void resume();

    void uploadRide(const QString &rideId);
    void uploadPending();
    void refresh();                     // dashboard and bikes

signals:
    void loggedInChanged();
    void busyChanged();
    void personChanged();
    void lastErrorChanged();
    void bikesChanged();
    void dashboardChanged();
    void rideUploaded(const QString &rideId, bool ok, const QString &message);
    // The server says this app is too old for it; the pages show a hint.
    void appTooOld(const QString &minimumVersion);

private slots:
    void replyFinished(int tag, int status, const QByteArray &body, const QString &error);

private:
    enum Kind { LoginRequest, PersonRequest, BikesRequest, DashboardRequest,
                RideSaveRequest, TrackSaveRequest };

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
    QString m_token;
    QString m_lastError;
    QStringList m_queue;                // ride ids waiting to go up
    int m_nextTag;
    int m_open;
};

#endif
