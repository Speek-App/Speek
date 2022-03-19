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

public:
    explicit MainWindow(QObject *parent = 0);
    ~MainWindow();

    bool showUI(QVariantMap _theme_color);

    QString aboutText() const;
    QString eulaText() const;
    QString version() const;
    QString accessibleVersion() const;
    QVariantMap screens() const;
    bool appstore_compliant() const;
    QVariantMap themeColor() const{
        return theme_color;
    };

    Q_INVOKABLE void reloadTheme();

    Q_INVOKABLE bool showRemoveContactDialog(shims::ContactUser *user);

    // Find parent window of a QQuickItem; exposed as property after Qt 5.4
    Q_INVOKABLE QQuickWindow *findParentWindow(QQuickItem *item);

private:
    QQmlApplicationEngine *qml;
    QVariantMap theme_color;

signals:
    void themeColorChanged();
};

extern MainWindow *uiMain;

static QPalette load_palette_from_file(QString file, QVariantMap* theme_color){
    QStringList color_group { "QPalette::Active", "QPalette::Disabled", "QPalette::Inactive" };
    QStringList color_role { "QPalette::WindowText", "QPalette::Button", "QPalette::Light", "QPalette::Midlight", "QPalette::Dark", "QPalette::Mid", "QPalette::Text", "QPalette::BrightText", "QPalette::ButtonText", "QPalette::Base", "QPalette::Window", "QPalette::Shadow", "QPalette::Highlight", "QPalette::HighlightedText", "QPalette::Link", "QPalette::LinkVisited", "QPalette::AlternateBase", "QPalette::NoRole", "QPalette::ToolTipBase", "QPalette::ToolTipText", "QPalette::PlaceholderText" };
    QPalette palette;

    QString data;
    QString fileName(file);

    QFile theme_file(fileName);
    if(!theme_file.open(QIODevice::ReadOnly)) {
        qDebug() << "theme file not opened" << Qt::endl;
    }
    else
    {
        QTextStream in(&theme_file);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            QStringList p = line.split(" ");

            if(p.length() == 2){
                if(color_role.indexOf(p[0]) != -1){
                    QStringList col = p[1].split(",");
                    palette.setColor(static_cast<QPalette::ColorRole>(color_role.indexOf(p[0])),QColor(col[0].toInt(),col[1].toInt(),col[2].toInt()));
                }
                else{
                    theme_color->insert(p[0], p[1]);
                }
            }
            else if(p.length() == 3){
                if(color_role.indexOf(p[1]) != -1 && color_group.indexOf(p[0]) != -1){
                    QStringList col = p[2].split(",");
                    palette.setColor(static_cast<QPalette::ColorGroup>(color_group.indexOf(p[0])) ,static_cast<QPalette::ColorRole>(color_role.indexOf(p[1])),QColor(col[0].toInt(),col[1].toInt(),col[2].toInt()));
                }
                else{
                    qDebug() << "theme file parsing error - key not found" << Qt::endl;
                }
            }
            else{
                qDebug() << "theme file parsing error" << Qt::endl;
            }
        }
    }

    theme_file.close();

    return palette;
}
static void initTheme(QVariantMap* theme_color)
{
    SettingsObject settings;
    if(settings.read("ui.useCustomTheme").toBool() == false || settings.read("ui.customTheme").toString().isEmpty()){
        if(settings.read("ui.lightMode").toBool() == false/* || QPalette().color(QPalette::WindowText).value() > QPalette().color(QPalette::Window).value()*/){
            qApp->setPalette(load_palette_from_file(":/themes/dark", theme_color));
        }
        else{
            qApp->setPalette(load_palette_from_file(":/themes/light", theme_color));
        }
    }
    else{
        qApp->setPalette(load_palette_from_file(settings.read("ui.customTheme").toString(), theme_color));
    }
}

#endif // MAINWINDOW_H
