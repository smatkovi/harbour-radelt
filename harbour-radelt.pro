# The Sailfish edition. The MeeGo edition is built by meego/build.sh from
# the same src/ with its own main and its own QML.

TARGET = harbour-radelt

CONFIG += sailfishapp

QT += positioning network

SOURCES += \
    src/harbour-radelt.cpp \
    src/api.cpp \
    src/format.cpp \
    src/http.cpp \
    src/json.cpp \
    src/recorder.cpp \
    src/ridestore.cpp \
    src/settings.cpp \
    src/track.cpp

HEADERS += \
    src/api.h \
    src/farben.h \
    src/format.h \
    src/http.h \
    src/json.h \
    src/recorder.h \
    src/ridestore.h \
    src/settings.h \
    src/track.h

DISTFILES += \
    harbour-radelt.desktop \
    rpm/harbour-radelt.spec \
    rpm/harbour-radelt.yaml \
    qml/harbour-radelt.qml \
    qml/cover/CoverPage.qml \
    qml/components/BigNumber.qml \
    qml/components/ThemedPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/RecordPage.qml \
    qml/pages/SaveDialog.qml \
    qml/pages/RidePage.qml \
    qml/pages/ManualRidePage.qml \
    qml/pages/LoginPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/OverviewPage.qml \
    qml/pages/TimelinePage.qml \
    qml/pages/CommunityPage.qml \
    qml/pages/BikesPage.qml \
    qml/pages/BikeDialog.qml \
    qml/pages/FindFriendsPage.qml \
    qml/pages/ChallengesPage.qml \
    qml/pages/ProfilePage.qml \
    qml/pages/NewsPage.qml \
    qml/pages/GoalsPage.qml \
    qml/pages/GoalDialog.qml \
    qml/components/BigNumber.qml \
    qml/components/ThemedPage.qml \

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# Das eigene Ambiente: taucht nach der Installation in den Einstellungen
# unter "Ambiente" auf und faerbt das ganze System in die Hausfarben.
# Aufbau wie bei den System-Ambienten: die Beschreibung oben, das Bild in
# images/. Farben als #AARRGGBB (Alpha zuerst), version 3 -- so liest
# ambienced sie, mit einem anderen Aufbau taucht das Ambiente gar nicht auf.
ambience.files = ambience/harbour-radelt.ambience
ambience.path = /usr/share/ambience/harbour-radelt
ambienceimages.files = ambience/images/ambience_radelt.jpg
ambienceimages.path = /usr/share/ambience/harbour-radelt/images
INSTALLS += ambience ambienceimages

CONFIG += sailfishapp_i18n
