#include "http.h"

#include <QFileInfo>
#include <QStringList>

#if QT_VERSION >= 0x050000

#include <QBuffer>
#include <QNetworkRequest>
#include <QUrl>

NetworkHttp::NetworkHttp(QObject *parent) :
    Http(parent)
{
}

void NetworkHttp::request(int tag, const QString &verb, const QString &url,
                          const QByteArray &body, const QStringList &headers)
{
    QNetworkRequest request((QUrl(url)));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Accept", "application/json");
    for (int i = 0; i + 1 < headers.size(); i += 2)
        request.setRawHeader(headers.at(i).toUtf8(), headers.at(i + 1).toUtf8());

    QNetworkReply *reply = 0;
    if (verb == QLatin1String("GET")) {
        reply = m_manager.get(request);
    } else if (verb == QLatin1String("POST")) {
        reply = m_manager.post(request, body);
    } else if (verb == QLatin1String("PUT")) {
        reply = m_manager.put(request, body);
    } else {
        // DELETE with a body, which /ride/delete wants. Qt 5.6 takes the
        // payload of a custom request only as a device, and the device has
        // to outlive the request -- hence the buffer parented on the reply.
        QBuffer *payload = 0;
        if (!body.isEmpty()) {
            payload = new QBuffer;
            payload->setData(body);
            payload->open(QIODevice::ReadOnly);
        }
        reply = m_manager.sendCustomRequest(request, verb.toLatin1(), payload);
        if (payload)
            payload->setParent(reply);
    }

    m_tags.insert(reply, tag);
    connect(reply, SIGNAL(finished()), this, SLOT(replyFinished()));
}

void NetworkHttp::replyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
    if (!reply)
        return;
    const int tag = m_tags.take(reply);
    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    const QByteArray body = reply->readAll();

    // The platform hands out its token as a cookie, so every answer is
    // searched for one. QNetworkAccessManager keeps its own jar for the
    // running session; this is what survives a restart.
    const QList<QNetworkReply::RawHeaderPair> pairs = reply->rawHeaderPairs();
    for (int i = 0; i < pairs.size(); ++i) {
        if (pairs.at(i).first.toLower() != "set-cookie")
            continue;
        const QByteArray first = pairs.at(i).second.split(';').value(0).trimmed();
        const int equals = first.indexOf('=');
        if (equals > 0)
            emit cookie(QString::fromUtf8(first.left(equals)),
                        QString::fromUtf8(first.mid(equals + 1)));
    }
    // A server answer with success:false still arrives as HTTP 200; only a
    // transport failure counts as an error here, so the API client can tell
    // "no network" from "wrong password".
    const QString error = (status == 0 && reply->error() != QNetworkReply::NoError)
                          ? reply->errorString() : QString();
    reply->deleteLater();
    emit finished(tag, status, body, error);
}

#else

#include <QProcessEnvironment>

ProcessHttp::ProcessHttp(QObject *parent) :
    Http(parent),
    m_program(QProcessEnvironment::systemEnvironment().value("RADELT_FETCH"))
{
    if (m_program.isEmpty())
        m_program = "/opt/harbour-radelt/bin/radelt-fetch";
}

void ProcessHttp::request(int tag, const QString &verb, const QString &url,
                          const QByteArray &body, const QStringList &headers)
{
    if (!QFileInfo(m_program).isExecutable()) {
        emit finished(tag, 0, QByteArray(),
                      tr("The helper %1 is missing").arg(m_program));
        return;
    }

    QStringList arguments;
    arguments << "--method" << verb << "--url" << url;
    arguments << "--header" << "Content-Type: application/json";
    arguments << "--header" << "Accept: application/json";
    for (int i = 0; i + 1 < headers.size(); i += 2)
        arguments << "--header" << (headers.at(i) + ": " + headers.at(i + 1));

    QProcess *process = new QProcess(this);
    m_tags.insert(process, tag);
    connect(process, SIGNAL(finished(int,QProcess::ExitStatus)),
            this, SLOT(processFinished(int,QProcess::ExitStatus)));
    process->start(m_program, arguments);
    if (!body.isEmpty()) {
        // The body goes in through stdin rather than the command line: a
        // track of two thousand points is far past what an argument list
        // takes, and it would stand in the process list.
        process->write(body);
    }
    process->closeWriteChannel();
}

void ProcessHttp::processFinished(int code, QProcess::ExitStatus status)
{
    QProcess *process = qobject_cast<QProcess *>(sender());
    if (!process)
        return;
    const int tag = m_tags.take(process);
    const QByteArray body = process->readAllStandardOutput();
    const QByteArray diagnostics = process->readAllStandardError();
    process->deleteLater();

    int httpStatus = 0;
    const QList<QByteArray> lines = diagnostics.split('\n');
    for (int i = 0; i < lines.size(); ++i) {
        const QByteArray line = lines.at(i).trimmed();
        if (line.startsWith("status:")) {
            httpStatus = line.mid(7).trimmed().toInt();
        } else if (line.startsWith("cookie:")) {
            // radelt-fetch reports every Set-Cookie this way; the token
            // of the platform arrives as one.
            const QByteArray keks = line.mid(7).trimmed();
            const int equals = keks.indexOf('=');
            if (equals > 0)
                emit cookie(QString::fromUtf8(keks.left(equals)),
                            QString::fromUtf8(keks.mid(equals + 1)));
        }
    }

    QString error;
    if (status != QProcess::NormalExit || (code != 0 && httpStatus == 0))
        error = QString::fromUtf8(diagnostics).trimmed();
    if (error.isEmpty() && httpStatus == 0)
        error = tr("No answer from the server");

    emit finished(tag, httpStatus, body, httpStatus ? QString() : error);
}

#endif
