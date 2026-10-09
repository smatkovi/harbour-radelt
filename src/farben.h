#ifndef FARBEN_H
#define FARBEN_H

#include <QColor>
#include <QObject>

// Die Hausfarben, an einer Stelle und für beide Ausgaben gleich.
//
// Rot ist das Feld des Original-Symbols, auf den Pixel gemessen (#C00D0D);
// daneben stehen Weiß und Schwarz wie bei Fahrplan AT. Das liegt in C++ und
// nicht als QML-Singleton, weil Qt 4.7 auf Harmattan keine Singletons kennt
// und die Seiten beider Ausgaben dieselben Namen benutzen sollen.
class Farben : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QColor rot READ rot CONSTANT)
    Q_PROPERTY(QColor rotHell READ rotHell CONSTANT)
    Q_PROPERTY(QColor rotDunkel READ rotDunkel CONSTANT)
    Q_PROPERTY(QColor weiss READ weiss CONSTANT)
    Q_PROPERTY(QColor schwarz READ schwarz CONSTANT)
    Q_PROPERTY(QColor grau READ grau CONSTANT)

public:
    explicit Farben(QObject *parent = 0) : QObject(parent) {}

    QColor rot() const { return QColor("#c00d0d"); }
    QColor rotHell() const { return QColor("#e03a3a"); }
    QColor rotDunkel() const { return QColor("#8a0909"); }
    QColor weiss() const { return QColor("#ffffff"); }
    QColor schwarz() const { return QColor("#000000"); }
    QColor grau() const { return QColor("#8c8c8c"); }
};

#endif
