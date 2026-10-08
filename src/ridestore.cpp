#include "ridestore.h"

#include "json.h"
#include "recorder.h"

#include <QDir>
#include <QFile>

#if QT_VERSION >= 0x050000
#include <QStandardPaths>
#else
#include <QDesktopServices>
#endif

namespace
{

QString dataDirectory()
{
#if QT_VERSION >= 0x050000
    // AppDataLocation already carries the organisation and application
    // name, and on Sailfish that is what the sandbox grants -- see the
    // Sailjail section of the desktop file.
    QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
#else
    QString base = QDesktopServices::storageLocation(QDesktopServices::DataLocation);
#endif
    if (base.isEmpty())
        base = QDir::homePath() + "/.local/share/harbour-radelt";
    const QString path = base + "/rides";
    QDir().mkpath(path);
    return path;
}

QString isoId(const QDateTime &when)
{
    return when.toUTC().toString("yyyy-MM-ddTHHmmss");
}

}

QVariantMap Ride::toMap() const
{
    QVariantMap map;
    map.insert("id", id);
    map.insert("start", start.toUTC().toString(Qt::ISODate));
    map.insert("distance", distance);
    map.insert("ascent", ascent);
    map.insert("movingSeconds", movingSeconds);
    map.insert("totalSeconds", totalSeconds);
    map.insert("title", title);
    map.insert("note", note);
    map.insert("bike", bike);
    map.insert("uploaded", uploaded);
    map.insert("remoteId", remoteId);
    map.insert("manual", manual);
    return map;
}

Ride Ride::fromMap(const QVariantMap &map)
{
    Ride ride;
    ride.id = map.value("id").toString();
    ride.start = QDateTime::fromString(map.value("start").toString(), Qt::ISODate);
    ride.start.setTimeSpec(Qt::UTC);
    ride.distance = map.value("distance").toDouble();
    ride.ascent = map.value("ascent").toDouble();
    ride.movingSeconds = map.value("movingSeconds").toInt();
    ride.totalSeconds = map.value("totalSeconds").toInt();
    ride.title = map.value("title").toString();
    ride.note = map.value("note").toString();
    ride.bike = map.value("bike").toString();
    ride.uploaded = map.value("uploaded").toBool();
    ride.remoteId = map.value("remoteId").toLongLong();
    ride.manual = map.value("manual").toBool();
    return ride;
}

RideStore::RideStore(QObject *parent) :
    QAbstractListModel(parent),
    m_directory(dataDirectory()),
    m_recorder(0)
{
#if QT_VERSION < 0x050000
    QHash<int, QByteArray> roles;
    roles.insert(IdRole, "rideId");
    roles.insert(StartRole, "start");
    roles.insert(DistanceRole, "distance");
    roles.insert(AscentRole, "ascent");
    roles.insert(MovingSecondsRole, "movingSeconds");
    roles.insert(TotalSecondsRole, "totalSeconds");
    roles.insert(TitleRole, "title");
    roles.insert(NoteRole, "note");
    roles.insert(BikeRole, "bike");
    roles.insert(UploadedRole, "uploaded");
    roles.insert(RemoteIdRole, "remoteId");
    roles.insert(ManualRole, "manual");
    setRoleNames(roles);
#endif
    load();
}

#if QT_VERSION >= 0x050000
QHash<int, QByteArray> RideStore::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(IdRole, "rideId");
    roles.insert(StartRole, "start");
    roles.insert(DistanceRole, "distance");
    roles.insert(AscentRole, "ascent");
    roles.insert(MovingSecondsRole, "movingSeconds");
    roles.insert(TotalSecondsRole, "totalSeconds");
    roles.insert(TitleRole, "title");
    roles.insert(NoteRole, "note");
    roles.insert(BikeRole, "bike");
    roles.insert(UploadedRole, "uploaded");
    roles.insert(RemoteIdRole, "remoteId");
    roles.insert(ManualRole, "manual");
    return roles;
}
#endif

int RideStore::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rides.size();
}

QVariant RideStore::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rides.size())
        return QVariant();
    const Ride &ride = m_rides.at(index.row());
    switch (role) {
    case IdRole: return ride.id;
    case StartRole: return ride.start.toLocalTime();
    case DistanceRole: return ride.distance;
    case AscentRole: return ride.ascent;
    case MovingSecondsRole: return ride.movingSeconds;
    case TotalSecondsRole: return ride.totalSeconds;
    case TitleRole: return ride.title;
    case NoteRole: return ride.note;
    case BikeRole: return ride.bike;
    case UploadedRole: return ride.uploaded;
    case RemoteIdRole: return ride.remoteId;
    case ManualRole: return ride.manual;
    default: return QVariant();
    }
}

int RideStore::pendingCount() const
{
    int pending = 0;
    for (int i = 0; i < m_rides.size(); ++i)
        if (!m_rides.at(i).uploaded)
            ++pending;
    return pending;
}

double RideStore::totalDistance() const
{
    double total = 0;
    for (int i = 0; i < m_rides.size(); ++i)
        total += m_rides.at(i).distance;
    return total;
}

double RideStore::todayDistance() const
{
    const QDate today = QDate::currentDate();
    double total = 0;
    for (int i = 0; i < m_rides.size(); ++i)
        if (m_rides.at(i).start.toLocalTime().date() == today)
            total += m_rides.at(i).distance;
    return total;
}

double RideStore::seasonDistance() const
{
    const QDate today = QDate::currentDate();
    const QDate from(today.year(), 3, 20);
    const QDate to(today.year(), 9, 30);
    double total = 0;
    for (int i = 0; i < m_rides.size(); ++i) {
        const QDate day = m_rides.at(i).start.toLocalTime().date();
        if (day >= from && day <= to)
            total += m_rides.at(i).distance;
    }
    return total;
}

QString RideStore::saveRecording(const QString &title, const QString &bike,
                                 const QString &note)
{
    if (!m_recorder)
        return QString();
    return addRecorded(m_recorder->track(), title, bike, note);
}

QString RideStore::recordPath(const QString &id) const
{
    return m_directory + "/" + id + ".json";
}

QString RideStore::gpxPath(const QString &id) const
{
    return m_directory + "/" + id + ".gpx";
}

void RideStore::load()
{
    QDir dir(m_directory);
    const QStringList names = dir.entryList(QStringList() << "*.json", QDir::Files, QDir::Name);
    QList<Ride> rides;
    for (int i = 0; i < names.size(); ++i) {
        QFile file(dir.filePath(names.at(i)));
        if (!file.open(QIODevice::ReadOnly))
            continue;
        const QVariant value = Json::parse(file.readAll());
        if (value.type() != QVariant::Map)
            continue;
        const Ride ride = Ride::fromMap(value.toMap());
        if (!ride.id.isEmpty())
            rides.append(ride);
    }
    // Newest first: that is the order the list shows and the order a rider
    // looks for a ride in.
    // Written out rather than QList::swap(int, int): that overload only
    // arrived in Qt 4.8, and Harmattan has 4.7.4.
    for (int i = 0; i < rides.size(); ++i) {
        for (int j = i + 1; j < rides.size(); ++j) {
            if (rides.at(j).start > rides.at(i).start) {
                const Ride keep = rides.at(i);
                rides[i] = rides.at(j);
                rides[j] = keep;
            }
        }
    }

    beginResetModel();
    m_rides = rides;
    endResetModel();
    emit countChanged();
}

bool RideStore::write(const Ride &ride)
{
    QFile file(recordPath(ride.id));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    const QByteArray text = Json::serialise(ride.toMap());
    return file.write(text) == text.size();
}

int RideStore::indexOf(const QString &id) const
{
    for (int i = 0; i < m_rides.size(); ++i)
        if (m_rides.at(i).id == id)
            return i;
    return -1;
}

QString RideStore::addRecorded(const Track &track, const QString &title,
                               const QString &bike, const QString &note)
{
    if (track.isEmpty())
        return QString();

    Ride ride;
    ride.start = track.start().isValid() ? track.start() : QDateTime::currentDateTimeUtc();
    ride.id = isoId(ride.start);
    ride.distance = track.distance();
    ride.ascent = track.ascent();
    ride.movingSeconds = track.movingSeconds();
    ride.totalSeconds = track.totalSeconds();
    ride.title = title;
    ride.bike = bike;
    ride.note = note;

    QFile gpx(gpxPath(ride.id));
    if (gpx.open(QIODevice::WriteOnly | QIODevice::Truncate))
        gpx.write(track.toGpx(title.isEmpty() ? ride.id : title));

    if (!write(ride))
        return QString();

    beginInsertRows(QModelIndex(), 0, 0);
    m_rides.prepend(ride);
    endInsertRows();
    emit countChanged();
    return ride.id;
}

QString RideStore::addManual(const QDateTime &when, double kilometres,
                             const QString &title, const QString &bike,
                             const QString &note)
{
    if (kilometres <= 0)
        return QString();

    Ride ride;
    ride.start = when.isValid() ? when.toUTC() : QDateTime::currentDateTimeUtc();
    ride.id = isoId(ride.start);
    // Two rides typed in for the same minute would share a file name.
    while (indexOf(ride.id) >= 0) {
        ride.start = ride.start.addSecs(1);
        ride.id = isoId(ride.start);
    }
    ride.distance = kilometres * 1000.0;
    ride.manual = true;
    ride.title = title;
    ride.bike = bike;
    ride.note = note;

    if (!write(ride))
        return QString();

    const int position = 0;
    beginInsertRows(QModelIndex(), position, position);
    m_rides.prepend(ride);
    endInsertRows();
    emit countChanged();
    return ride.id;
}

QVariantMap RideStore::ride(const QString &id) const
{
    const int row = indexOf(id);
    return row < 0 ? QVariantMap() : m_rides.at(row).toMap();
}

bool RideStore::remove(const QString &id)
{
    const int row = indexOf(id);
    if (row < 0)
        return false;
    QFile::remove(recordPath(id));
    QFile::remove(gpxPath(id));
    beginRemoveRows(QModelIndex(), row, row);
    m_rides.removeAt(row);
    endRemoveRows();
    emit countChanged();
    return true;
}

bool RideStore::loadTrack(const QString &id, Track *track) const
{
    if (!track)
        return false;
    QFile file(gpxPath(id));
    if (!file.open(QIODevice::ReadOnly))
        return false;
    return track->fromGpx(file.readAll());
}

void RideStore::markUploaded(const QString &id, qlonglong remoteId)
{
    const int row = indexOf(id);
    if (row < 0)
        return;
    m_rides[row].uploaded = true;
    m_rides[row].remoteId = remoteId;
    write(m_rides.at(row));
    const QModelIndex changed = index(row, 0);
    emit dataChanged(changed, changed);
    emit countChanged();
}

QList<Ride> RideStore::pending() const
{
    QList<Ride> list;
    for (int i = 0; i < m_rides.size(); ++i)
        if (!m_rides.at(i).uploaded)
            list.append(m_rides.at(i));
    return list;
}
