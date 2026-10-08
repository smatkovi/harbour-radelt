#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QSettings>
#include <QString>

// What the app remembers between starts.
//
// The organisation and application name must match the identity in the
// desktop file; on Sailfish a mismatch means the sandbox hands the app a
// different, empty store every time it is started from the icon, and the
// app forgets everything it was told.
class Settings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString email READ email WRITE setEmail NOTIFY emailChanged)
    Q_PROPERTY(bool uploadAutomatically READ uploadAutomatically
               WRITE setUploadAutomatically NOTIFY uploadAutomaticallyChanged)
    Q_PROPERTY(bool keepDisplayOn READ keepDisplayOn WRITE setKeepDisplayOn
               NOTIFY keepDisplayOnChanged)
    Q_PROPERTY(double accuracyLimit READ accuracyLimit WRITE setAccuracyLimit
               NOTIFY accuracyLimitChanged)

public:
    explicit Settings(QObject *parent = 0);

    QString email() const;
    void setEmail(const QString &email);

    // Not a property: the token has no business in QML.
    QString token() const;
    void setToken(const QString &token);

    bool uploadAutomatically() const;
    void setUploadAutomatically(bool automatic);

    bool keepDisplayOn() const;
    void setKeepDisplayOn(bool keep);

    double accuracyLimit() const;
    void setAccuracyLimit(double metres);

signals:
    void emailChanged();
    void uploadAutomaticallyChanged();
    void keepDisplayOnChanged();
    void accuracyLimitChanged();

private:
    QSettings m_store;
};

#endif
