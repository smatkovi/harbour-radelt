#include "settings.h"

Settings::Settings(QObject *parent) :
    QObject(parent),
    m_store("harbour-radelt", "harbour-radelt")
{
}

QString Settings::email() const
{
    return m_store.value("account/email").toString();
}

void Settings::setEmail(const QString &email)
{
    if (email == this->email())
        return;
    m_store.setValue("account/email", email);
    m_store.sync();
    emit emailChanged();
}

QString Settings::token() const
{
    return m_store.value("account/token").toString();
}

void Settings::setToken(const QString &token)
{
    m_store.setValue("account/token", token);
    m_store.sync();
}

bool Settings::uploadAutomatically() const
{
    return m_store.value("upload/automatic", true).toBool();
}

void Settings::setUploadAutomatically(bool automatic)
{
    if (automatic == uploadAutomatically())
        return;
    m_store.setValue("upload/automatic", automatic);
    m_store.sync();
    emit uploadAutomaticallyChanged();
}

bool Settings::keepDisplayOn() const
{
    return m_store.value("display/keepOn", false).toBool();
}

void Settings::setKeepDisplayOn(bool keep)
{
    if (keep == keepDisplayOn())
        return;
    m_store.setValue("display/keepOn", keep);
    m_store.sync();
    emit keepDisplayOnChanged();
}

double Settings::accuracyLimit() const
{
    return m_store.value("recording/accuracyLimit", 50.0).toDouble();
}

void Settings::setAccuracyLimit(double metres)
{
    if (qFuzzyCompare(metres, accuracyLimit()))
        return;
    m_store.setValue("recording/accuracyLimit", metres);
    m_store.sync();
    emit accuracyLimitChanged();
}
