/* Speek - https://speek.network/
 * Copyright (C) 2020, Speek Network (contact@speek.network)
 * Copyright (C) 2014, John Brooks <john.brooks@dereferenced.net>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *    * Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *    * Redistributions in binary form must reproduce the above
 *      copyright notice, this list of conditions and the following disclaimer
 *      in the documentation and/or other materials provided with the
 *      distribution.
 *
 *    * Neither the names of the copyright owners nor the names of its
 *      contributors may be used to endorse or promote products derived from
 *      this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include "utils/Settings.h"

namespace shims
{
    class ContactUser;
    class ContactsManager;
}
class IncomingContactRequest;
class OutgoingContactRequest;
class QQmlApplicationEngine;
class QQuickItem;
class QQuickWindow;

class MainWindow : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(MainWindow)

    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString accessibleVersion READ accessibleVersion CONSTANT)
    Q_PROPERTY(QString aboutText READ aboutText CONSTANT)
    Q_PROPERTY(bool appstore_compliant READ appstore_compliant CONSTANT)
    Q_PROPERTY(QString eulaText READ eulaText CONSTANT)
    Q_PROPERTY(QVariantMap screens READ screens CONSTANT)
    Q_PROPERTY(QVariantMap themeColor READ themeColor NOTIFY themeColorChanged)
    Q_PROPERTY(bool isGroupHostMode READ getIsGroupHostMode CONSTANT)

public:
    explicit MainWindow(QObject *parent = 0);
    ~MainWindow();

    bool showUI(QVariantMap _theme_color, bool isGroupHostMode = false);

    QString aboutText() const;
    QString eulaText() const;
    QString version() const;
    QString accessibleVersion() const;
    QVariantMap screens() const;
    bool appstore_compliant() const;
    QVariantMap themeColor() const{
        return theme_color;
    };
    bool getIsGroupHostMode() const{
        return isGroupHostMode;
    };

    static void initTranslation();
    static QPalette load_palette_from_file(QString file, QVariantMap* theme_color);
    static void initTheme(QVariantMap* theme_color);
    static void loadDefaultSettings(SettingsFile *settings);
    static bool initSettings(SettingsFile *settings, QLockFile **lockFile, QString &errorMessage, QString pathChange = "/");
    static void initFontSettings();
    static void loadSettings(tego_context_t* tegoContext, shims::ContactsManager* contactsManager);

    Q_INVOKABLE void reloadTheme();

    #ifndef CONSOLE_ONLY
    Q_INVOKABLE bool showRemoveContactDialog(shims::ContactUser *user);

    // Find parent window of a QQuickItem; exposed as property after Qt 5.4
    Q_INVOKABLE QQuickWindow *findParentWindow(QQuickItem *item);
    #endif

private:
    QQmlApplicationEngine *qml;
    QVariantMap theme_color;
    bool isGroupHostMode;

signals:
    void themeColorChanged();
};

extern MainWindow *uiMain;

#endif // MAINWINDOW_H
