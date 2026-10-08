#include "format.h"

#include <QLocale>

QString Format::kilometres(double metres) const
{
    const double km = metres / 1000.0;
    // Under ten kilometres the second decimal is what tells a ride to the
    // baker from one to the next street; above it, it is noise.
    return QLocale().toString(km, 'f', km < 10 ? 2 : 1);
}

QString Format::metres(double metres) const
{
    return QLocale().toString(qRound(metres));
}

QString Format::duration(int seconds) const
{
    if (seconds < 0)
        seconds = 0;
    const int hours = seconds / 3600;
    const int minutes = (seconds % 3600) / 60;
    if (hours > 0)
        return QString("%1:%2 h").arg(hours).arg(minutes, 2, 10, QLatin1Char('0'));
    return QString("%1:%2 min").arg(minutes).arg(seconds % 60, 2, 10, QLatin1Char('0'));
}

QString Format::speed(double metresPerSecond) const
{
    if (metresPerSecond <= 0)
        return QLatin1String("–");
    return QLocale().toString(metresPerSecond * 3.6, 'f', 1);
}

QString Format::day(const QDateTime &when) const
{
    if (!when.isValid())
        return QString();
    return QLocale().toString(when.toLocalTime().date(), QLocale::ShortFormat);
}

QString Format::dayAndTime(const QDateTime &when) const
{
    if (!when.isValid())
        return QString();
    const QDateTime local = when.toLocalTime();
    return QLocale().toString(local.date(), QLocale::ShortFormat) + " "
         + local.time().toString("HH:mm");
}
