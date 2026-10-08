#ifndef HTTP_H
#define HTTP_H

#include <QByteArray>
#include <QObject>
#include <QStringList>

// What the API client needs from the network, and nothing more.
//
// The two editions reach the server by different roads. Sailfish uses
// QNetworkAccessManager. Harmattan cannot: Qt 4.7 there is linked against an
// OpenSSL that no longer gets past a current TLS handshake, so the request
// is handed to a helper program that brings its own TLS (see
// ProcessHttp below and meego/README).
class Http : public QObject
{
    Q_OBJECT
public:
    explicit Http(QObject *parent = 0) : QObject(parent) {}
    virtual ~Http() {}

    // verb is "GET", "POST", "PUT" or "DELETE"; body may be empty.
    // The reply arrives as finished() with the same tag.
    virtual void request(int tag, const QString &verb, const QString &url,
                         const QByteArray &body, const QStringList &headers) = 0;

signals:
    // status is the HTTP status, or 0 when the request never got that far
    // (no network, TLS refused, helper missing). error carries the reason
    // in that case.
    void finished(int tag, int status, const QByteArray &body, const QString &error);
};

#if QT_VERSION >= 0x050000

#include <QHash>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class NetworkHttp : public Http
{
    Q_OBJECT
public:
    explicit NetworkHttp(QObject *parent = 0);
    void request(int tag, const QString &verb, const QString &url,
                 const QByteArray &body, const QStringList &headers);

private slots:
    void replyFinished();

private:
    QNetworkAccessManager m_manager;
    QHash<QObject *, int> m_tags;
};

#else

#include <QHash>
#include <QProcess>

// Harmattan: the request goes out through a helper that speaks current TLS.
//
// The helper is called like curl and must print the body on stdout and the
// HTTP status as the last line of stderr in the form "status: <n>".
// radelt-fetch in meego/fetch does that; the program can be swapped through
// the RADELT_FETCH environment variable, which is how the same code is
// tested against a local server.
class ProcessHttp : public Http
{
    Q_OBJECT
public:
    explicit ProcessHttp(QObject *parent = 0);
    void request(int tag, const QString &verb, const QString &url,
                 const QByteArray &body, const QStringList &headers);

private slots:
    void processFinished(int code, QProcess::ExitStatus status);

private:
    QString m_program;
    QHash<QObject *, int> m_tags;
};

#endif

#endif
