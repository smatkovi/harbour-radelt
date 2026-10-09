// The MeeGo Harmattan edition: the same src/ core behind a com.nokia.meego
// surface, started the way every Harmattan Qt Quick application is.
//
// Differences from the Sailfish main, all forced by Qt 4.7:
//   * QApplication and QDeclarativeView instead of QGuiApplication/QQuickView
//   * the QML lives in /opt/harbour-radelt/qml, not in a resource
//   * the view is shown full screen; Harmattan has no window decoration for
//     applications anyway
#include <QApplication>
#include <QDeclarativeContext>
#include <QDeclarativeEngine>
#include <QDeclarativeView>
#include <QDir>
#include <QFileInfo>
#include <QLocale>
#include <QTranslator>

#include "api.h"
#include "farben.h"
#include "format.h"
#include "recorder.h"
#include "ridestore.h"
#include "settings.h"

namespace
{
QString qmlFile()
{
    // Running from the build tree is what the QML check and a quick trial
    // over ssh need; the installed path wins when it exists.
    const QString installed = "/opt/harbour-radelt/qml/main.qml";
    if (QFileInfo(installed).exists())
        return installed;
    return QDir(QCoreApplication::applicationDirPath()).filePath("qml/main.qml");
}
}

int main(int argc, char *argv[])
{
    QApplication application(argc, argv);
    application.setOrganizationName("harbour-radelt");
    application.setApplicationName("harbour-radelt");

    QTranslator translator;
    if (translator.load("harbour-radelt-" + QLocale::system().name(),
                        "/opt/harbour-radelt/translations"))
        application.installTranslator(&translator);

    Settings settings;
    Recorder recorder;
    RideStore rides;
    rides.setRecorder(&recorder);
    Api api(&settings, &rides);
    Format format;
    Farben farben;

    QDeclarativeView view;
    QDeclarativeContext *context = view.rootContext();
    context->setContextProperty("Recorder", &recorder);
    context->setContextProperty("Rides", &rides);
    context->setContextProperty("Api", &api);
    context->setContextProperty("Settings", &settings);
    context->setContextProperty("Format", &format);
    context->setContextProperty("Farben", &farben);

    view.setResizeMode(QDeclarativeView::SizeRootObjectToView);
    view.setSource(QUrl::fromLocalFile(qmlFile()));
    view.showFullScreen();

    return application.exec();
}
