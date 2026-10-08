#ifndef FORMAT_H
#define FORMAT_H

#include <QDateTime>
#include <QObject>
#include <QString>

// Numbers and dates the way they are read on a bicycle: short, and with the
// unit named once beside them rather than repeated in every line.
//
// It lives in C++ rather than in a JavaScript helper because both editions
// need exactly the same output, and Qt 4.7's JavaScript engine formats
// dates differently from Qt 5's.
class Format : public QObject
{
    Q_OBJECT
public:
    explicit Format(QObject *parent = 0) : QObject(parent) {}

    Q_INVOKABLE QString kilometres(double metres) const;
    Q_INVOKABLE QString metres(double metres) const;
    Q_INVOKABLE QString duration(int seconds) const;
    Q_INVOKABLE QString speed(double metresPerSecond) const;
    Q_INVOKABLE QString day(const QDateTime &when) const;
    Q_INVOKABLE QString dayAndTime(const QDateTime &when) const;
};

#endif
