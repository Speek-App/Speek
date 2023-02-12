// C headers

// openssl
#include <openssl/crypto.h>

// C++ headers
#ifdef __cplusplus

// Qt

#ifndef CONSOLE_ONLY
#include <QApplication>
#include <QMessageBox>
#else
#include <QCoreApplication>
#endif
#include <QByteArray>
#include <QDir>
#include <QFile>
#include <QHostAddress>
#include <QIcon>
#include <QJsonArray>
#include <QJsonObject>
#include <QLibraryInfo>
#include <QLockFile>
#include <QObject>
#include <QSettings>
#include <QStandardPaths>
#include <QTranslator>
#include <QRandomGenerator>

// tego
#include <tego/tego.hpp>

#ifdef TEGO_VERSION
#   define TEGO_STR2(X) #X
#   define TEGO_STR(X) TEGO_STR2(X)
#   define TEGO_VERSION_STR TEGO_STR(TEGO_VERSION)
#else
#   define TEGO_VERSION_STR "devbuild"
#endif

#endif // __cplusplus


