QMAKE_INCLUDES = $${PWD}/../qmake_includes

include($${QMAKE_INCLUDES}/artifacts.pri)
include($${QMAKE_INCLUDES}/compiler_flags.pri)

TEMPLATE = lib
TARGET = tego_ui
CONFIG += staticlib

console{
    QT += core network
    DEFINES += "CONSOLE_ONLY=1"
}
else{
    QT += core gui network quick widgets
}

CONFIG(release,debug|release):DEFINES += QT_NO_DEBUG_OUTPUT QT_NO_WARNING_OUTPUT

# INCLUDEPATH += $${PWD}
# INCLUDEPATH += $${PWD}/../extern/fmt/include

!isEmpty(APPSTORE_COMPLIANT) {
    DEFINES += "APPSTORE_COMPLIANT=1"
}

macx {
    QT += macextras
}
android{
    QT += androidextras multimedia svg
}

!console{
    QT += quickcontrols2
    QT += quick
}

CONFIG += precompile_header
PRECOMPILED_HEADER = precomp.hpp

SOURCES += \
    libtego_callbacks.cpp \
    shims/utility.cpp \
    ui/ContactsModel.cpp \
    ui/LanguagesModel.cpp \
    ui/MainWindow.cpp \
    utils/Settings.cpp \
    shims/TorControl.cpp\
    shims/TorCommand.cpp\
    shims/TorManager.cpp\
    shims/UserIdentity.cpp\
    shims/ContactsManager.cpp\
    shims/ContactUser.cpp\
    shims/ConversationModel.cpp\
    shims/IncomingContactRequest.cpp\
    shims/OutgoingContactRequest.cpp\
    shims/ContactIDValidator.cpp

!console{
    SOURCES += ui/Clipboard.cpp
}
else{
    SOURCES += ui/console.cpp
}

HEADERS += \
    libtego_callbacks.hpp \
    shims/utility.h \
    ui/ContactsModel.h \
    ui/LanguagesModel.h \
    ui/MainWindow.h \
    utils/Settings.h \
    utils/Useful.h \
    shims/TorControl.h\
    shims/TorCommand.h\
    shims/TorManager.h\
    shims/UserIdentity.h\
    shims/ContactsManager.h\
    shims/ContactUser.h\
    shims/ConversationModel.h\
    shims/IncomingContactRequest.h\
    shims/OutgoingContactRequest.h\
    shims/ContactIDValidator.h \
    utils/json.h

!console{
    HEADERS += ui/Clipboard.h \
    ui/JazzIdenticonImageProvider.h \
    ui/Base64RoundedImageProvider.h \
    ui/Base64CircleImageProvider.h \
    ui/Base64ImageProvider.h
}
else{
    HEADERS += ui/console.h
}

android{
    HEADERS += utils/NotificationClient.h
    SOURCES += utils/NotificationClient.cpp
}

include($${QMAKE_INCLUDES}/protobuf.pri)
include($${QMAKE_INCLUDES}/openssl.pri)
include($${PWD}/../libtego/libtego.pri)
!win32{
    include($${PWD}/../libtego_ui/quazip/quazip.pri)
}

!console{
    include(SCodes/SCodes.pri)
}
