#include <QtGlobal>

// C headers

// standard library
#include <limits.h>

// C++ headers
#ifdef __cplusplus

// standard library
#include <sstream>
#include <iomanip>
#include <cassert>
#include <type_traits>
#include <cstdint>
#include <functional>
#include <fstream>
#include <iterator>

// fmt
#include <fmt/format.h>
#include <fmt/ostream.h>

// Qt
#include <QClipboard>
#include <QDateTime>
#include <QDir>
#ifndef CONSOLE_ONLY
    #include <QFileDialog>
    #include <QGuiApplication>
    #include <QMessageBox>
    #include <QQuickItem>
    #include <QtQml>
#else
    #include <QtCore>
    #include <QNetworkAccessManager>
    #include <QNetworkProxy>
    #include <QPalette>
#endif
#include <QRegularExpressionValidator>
#include <QScreen>
#ifdef Q_OS_MAC
#   include <QtMac>
#endif // Q_OS_MAC

// tego
#include <tego/tego.hpp>

#endif // __cplusplus


