/* Speek - https://speek.network/
 * Copyright (C) 2020, Speek Network (contact@speek.network)
 * Copyright (C) 2019, Blueprint For Free Speech <ricochet@blueprintforfreespeech.net>
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

#include "ui/MainWindow.h"
#include "utils/Settings.h"

#include <libtego_callbacks.hpp>
#include <QStyleFactory>
#include <QtCore/QMetaProperty>
#include <QValidator>
#include <QTimer>

// shim replacements
#include "shims/TorControl.h"
#include "shims/TorManager.h"
#include "shims/UserIdentity.h"
#include "shims/ContactIDValidator.h"

int main(int argc, char *argv[]) try
{
   /* Disable rwx memory.
       This will also ensure full PAX/Grsecurity protections. */
    qputenv("QV4_FORCE_INTERPRETER",  "1");
    qputenv("QT_ENABLE_REGEXP_JIT",   "0");
    /* Use QtQuick 2D renderer by default; ignored if not available */
    if (qEnvironmentVariableIsEmpty("QMLSCENE_DEVICE"))
        qputenv("QMLSCENE_DEVICE", "software");

    /* https://doc.qt.io/qt-5/highdpi.html#high-dpi-support-in-qt */
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    if (!qEnvironmentVariableIsSet("QT_DEVICE_PIXEL_RATIO")
            && !qEnvironmentVariableIsSet("QT_AUTO_SCREEN_SCALE_FACTOR")
            && !qEnvironmentVariableIsSet("QT_SCALE_FACTOR")
            && !qEnvironmentVariableIsSet("QT_SCREEN_SCALE_FACTORS")) {
        QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    }

    QApplication a(argc, argv);

    qApp->setStyle(QStyleFactory::create("Fusion"));
    MainWindow::initFontSettings();
    MainWindow::initTranslation();
    QVariantMap theme_color;
    MainWindow::initTheme(&theme_color);

    tego_context_t* tegoContext = nullptr;
    tego_initialize(&tegoContext, tego::throw_on_error());

    auto tego_cleanup = tego::make_scope_exit([=]() -> void {
        tego_uninitialize(tegoContext, tego::throw_on_error());
    });

    init_libtego_callbacks(tegoContext);

    a.setApplicationVersion(QLatin1String(TEGO_VERSION_STR));
    #if !defined(Q_OS_WIN) && !defined(Q_OS_MAC)
        a.setWindowIcon(QIcon(QStringLiteral(":/icons/speek-group.png")));
    #endif

    QScopedPointer<SettingsFile> settings(new SettingsFile);
    SettingsObject::setDefaultFile(settings.data());

    QString error;
    QLockFile *lock = 0;
    #if defined(Q_OS_MAC)
    if (!MainWindow::initSettings(settings.data(), &lock, error, "/speek-groups/")) {
    #else
    if (!MainWindow::initSettings(settings.data(), &lock, error, "/")) {
    #endif
        if (error.isEmpty())
            return 0;
        QMessageBox::critical(0, qApp->translate("Main", "Speek Error"), error);
        return 1;
    }
    QScopedPointer<QLockFile> lockFile(lock);

    // init our tor shims
    shims::TorControl::torControl = new shims::TorControl(tegoContext);
    shims::TorManager::torManager = new shims::TorManager(tegoContext);

    // start Tor
    std::unique_ptr<tego_tor_launch_config_t> launchConfig;
    tego_tor_launch_config_initialize(tego::out(launchConfig), tego::throw_on_error());
    auto rawFilePath = (QFileInfo(settings->filePath()).path() + QStringLiteral("/tor/")).toUtf8();
    tego_tor_launch_config_set_data_directory(launchConfig.get(), rawFilePath.data(), rawFilePath.size(), tego::throw_on_error());
    tego_context_start_tor(tegoContext, launchConfig.get(), tego::throw_on_error());

    /* Identities */
    shims::UserIdentity::userIdentity = new shims::UserIdentity(tegoContext, true);
    auto contactsManager = shims::UserIdentity::userIdentity->getContacts();

    MainWindow::loadSettings(tegoContext, contactsManager);

    QStringList args = qApp->arguments();
    if(args.size() > 2){
        settings->root()->write("ui.username", args[2]);
    }
    if(args.size() > 3){
        settings->root()->write("ui.contactRequestMessage", args[3]);
    }

    /* Window */
    QScopedPointer<MainWindow> w(new MainWindow);
    if (!w->showUI(theme_color, true))
        return 1;

    if(args.size() > 4){
        QMetaObject::Connection * const connection = new QMetaObject::Connection;
        *connection = QObject::connect(shims::UserIdentity::userIdentity, &shims::UserIdentity::statusChanged, contactsManager,[contactsManager, connection]() {
            QStringList args = qApp->arguments();
            QString requestMessage;
            QString groupName;
            if(args.size() >= 2){
                groupName = args[2];
            }
            if(args.size() >= 3){
                requestMessage = args[3];
            }

            shims::ContactIDValidator v;
            for(int i = 4; i<args.size(); i+=1){
                QString speekID = args[i].section(';', 0, 0);
                QString username = args[i].section(';', 1, 1);
                int pos = 0;
                if(!speekID.isEmpty() && !username.isEmpty() && v.validate(speekID, pos) != QValidator::Invalid)
                    contactsManager->createContactRequest(speekID,username,groupName,requestMessage);
            }
            QObject::disconnect(*connection);
            delete connection;
        });
    }

    return a.exec();
}
catch(std::exception& re)
{
    qDebug() << "Caught Exception: " << re.what();
    return -1;
}
