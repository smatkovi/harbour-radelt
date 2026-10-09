#include <QGuiApplication>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>

#include <sailfishapp.h>

#include "api.h"
#include "farben.h"
#include "format.h"
#include "recorder.h"
#include "ridestore.h"
#include "settings.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(SailfishApp::application(argc, argv));
    application->setOrganizationName("harbour-radelt");
    application->setApplicationName("harbour-radelt");

    Settings settings;
    Recorder recorder;
    RideStore rides;
    rides.setRecorder(&recorder);
    Api api(&settings, &rides);
    Format format;
    Farben farben;

    recorder.setPaused(false);

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    QQmlContext *context = view->rootContext();
    // The objects are context properties rather than registered types: a
    // recording must survive the page it was started from, and a second
    // instance of the recorder would mean a second receiver.
    context->setContextProperty("Recorder", &recorder);
    context->setContextProperty("Rides", &rides);
    context->setContextProperty("Api", &api);
    context->setContextProperty("Settings", &settings);
    context->setContextProperty("Format", &format);
    context->setContextProperty("Farben", &farben);

    view->setSource(SailfishApp::pathTo("qml/harbour-radelt.qml"));
    view->show();

    return application->exec();
}
