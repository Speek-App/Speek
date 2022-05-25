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

#include <QApplication>

#include "ui/MainWindow.h"
#include "ui/Clipboard.h"
#include "ui/ContactsModel.h"
#include "ui/LanguagesModel.h"
#include "ui/Base64CircleImageProvider.h"
#include "ui/Base64ImageProvider.h"
#include "ui/Base64RoundedImageProvider.h"
#include "ui/JazzIdenticonImageProvider.h"

#include "utils/Settings.h"
#include "utils/Useful.h"


// shim replacements
#include "shims/TorControl.h"
#include "shims/TorManager.h"
#include "shims/UserIdentity.h"
#include "shims/ContactsManager.h"
#include "shims/ContactUser.h"
#include "shims/ConversationModel.h"
#include "shims/OutgoingContactRequest.h"
#include "shims/ContactIDValidator.h"
#include "shims/IncomingContactRequest.h"
#include "shims/utility.h"
#include "SBarcodeGenerator.h"

#ifdef ANDROID
#include "SBarcodeFilter.h"
#include "utils/NotificationClient.h"
#include <QInputDialog>
#endif

#include <QQuickStyle>

MainWindow *uiMain = 0;

/* Through the QQmlNetworkAccessManagerFactory below, all network requests
 * created via QML will be passed to this object; including, for example,
 * <img> tags parsed in rich Text items.
 *
 * Ricochet's UI does not directly cause network requests for any reason. These
 * are always a potentially deanonymizing bug. This object will block them,
 * and assert if appropriate.
 */
class BlockedNetworkAccessManager : public QNetworkAccessManager
{
public:
    BlockedNetworkAccessManager(QObject *parent)
        : QNetworkAccessManager(parent)
    {
        /* This will cause any network request to fail.
         * This should be redundant, because createRequest below also
         * blackholes every request (and crashes for assert builds). */
        setProxy(QNetworkProxy(QNetworkProxy::Socks5Proxy, QLatin1String("0.0.0.0"), 0));
    }

protected:
    virtual QNetworkReply *createRequest(Operation op, const QNetworkRequest &req, QIODevice *outgoingData = 0)
    {
        TEGO_BUG() << "QML attempted to load a network resource from" << req.url() << " - this is potentially an input sanitization flaw.";
        return QNetworkAccessManager::createRequest(op, QNetworkRequest(), outgoingData);
    }
};

class NetworkAccessBlockingFactory : public QQmlNetworkAccessManagerFactory
{
public:
    virtual QNetworkAccessManager *create(QObject *parent)
    {
        return new BlockedNetworkAccessManager(parent);
    }
};

MainWindow::MainWindow(QObject *parent)
    : QObject(parent)
{
    Q_ASSERT(!uiMain);
    uiMain = this;

    qml = new QQmlApplicationEngine(this);
    qml->addImageProvider(QLatin1String("base64"), new Base64CircleImageProvider);
    qml->addImageProvider(QLatin1String("base64n"), new Base64ImageProvider);
    qml->addImageProvider(QLatin1String("base64r"), new Base64RoundedImageProvider);
    qml->addImageProvider(QLatin1String("jazzicon"), new JazzIdenticonImageProvider);
    qml->setNetworkAccessManagerFactory(new NetworkAccessBlockingFactory);

    qmlRegisterType<SBarcodeGenerator>("com.scythestudio.scodes", 1, 0, "SBarcodeGenerator");

    #ifdef ANDROID
        qmlRegisterType<SBarcodeFilter>("com.scythestudio.scodes", 1, 0, "SBarcodeFilter");
    #endif

    qmlRegisterUncreatableType<shims::ContactUser>("im.ricochet", 1, 0, "ContactUser", QString());
    qmlRegisterUncreatableType<shims::UserIdentity>("im.ricochet", 1, 0, "UserIdentity", QString());
    qmlRegisterUncreatableType<shims::ContactsManager>("im.ricochet", 1, 0, "ContactsManager", QString());
    qmlRegisterUncreatableType<shims::IncomingContactRequest>("im.ricochet", 1, 0, "IncomingContactRequest", QString());
    qmlRegisterUncreatableType<shims::OutgoingContactRequest>("im.ricochet", 1, 0, "OutgoingContactRequest", QString());
    qmlRegisterUncreatableType<shims::TorControl>("im.ricochet", 1, 0, "TorControl", QString());
    qmlRegisterType<shims::ConversationModel>("im.ricochet", 1, 0, "ConversationModel");
    qmlRegisterType<::ContactsModel>("im.ricochet", 1, 0, "ContactsModel");
    qmlRegisterType<shims::ContactIDValidator>("im.ricochet", 1, 0, "ContactIDValidator");
    qmlRegisterType<::SettingsObject>("im.ricochet", 1, 0, "Settings");
    qmlRegisterSingletonType<::Clipboard>("im.ricochet", 1, 0, "Clipboard", &Clipboard::singleton_provider);
    qmlRegisterType<::LanguagesModel>("im.ricochet", 1, 0, "LanguagesModel");
    qmlRegisterType<Utility>("im.utility", 1, 0, "Utility");
}

MainWindow::~MainWindow()
{
}

void MainWindow::reloadTheme(){
    QVariantMap _theme_color;
    initTheme(&_theme_color);

    theme_color = _theme_color;

    emit themeColorChanged();
}

bool MainWindow::showUI(QVariantMap _theme_color, bool isGroupHostMode)
{
    this->isGroupHostMode = isGroupHostMode;
    theme_color = _theme_color;
    qml->rootContext()->setContextProperty(QLatin1String("userIdentity"), shims::UserIdentity::userIdentity);
    qml->rootContext()->setContextProperty(QLatin1String("torControl"), shims::TorControl::torControl);
    qml->rootContext()->setContextProperty(QLatin1String("torInstance"), shims::TorManager::torManager);
    qml->rootContext()->setContextProperty(QLatin1String("uiMain"), this);

    #ifdef ANDROID
        if(!this->isGroupHostMode){
            NotificationClient *notificationClient = new NotificationClient(qml);
            qml->rootContext()->setContextProperty(QLatin1String("notificationClient"), notificationClient);
        }
    #endif

    qml->load(QUrl(QLatin1String("qrc:/ui/main.qml")));

    if (qml->rootObjects().isEmpty()) {
        // Assume this is only applicable to technical users; not worth translating or simplifying.
        QMessageBox::critical(0, QStringLiteral("Speek.Chat"),
            QStringLiteral("An error occurred while loading the Speek.Chat UI.\n\n"
                           "You might be missing plugins or dependency packages."));
        qCritical() << "Failed to load UI. Exiting.";
        return false;
    }

    return true;
}

QString MainWindow::version() const
{
    const static auto retval = qApp->applicationVersion();
    return retval;
}

QString MainWindow::accessibleVersion() const
{
    const static auto retval = [this]() -> QString
    {
        auto version = this->version();
        return version.replace('.', QString(" %1 ").arg(tr("Version Seperator")));
    }();

    return retval;
}

bool MainWindow::appstore_compliant() const
{
    #ifdef APPSTORE_COMPLIANT
        return true;
    #else
        return false;
    #endif
}

QString MainWindow::aboutText() const
{
    QFile file(QStringLiteral(":/text/LICENSE"));
    file.open(QIODevice::ReadOnly);
    QString text = QString::fromUtf8(file.readAll());
    return text;
}

QString MainWindow::eulaText() const
{
    QFile file(QStringLiteral(":/text/EULA"));
    file.open(QIODevice::ReadOnly);
    QString text = QString::fromUtf8(file.readAll());
    return text;
}

QVariantMap MainWindow::screens() const
{
    QVariantMap mapScreenSizes;
    foreach (QScreen *screen, QGuiApplication::screens()) {
        QVariantMap screenObj;
        screenObj.insert(QString::fromUtf8("width"), screen->availableSize().width());
        screenObj.insert(QString::fromUtf8("height"), screen->availableSize().height());
        screenObj.insert(QString::fromUtf8("left"), screen->geometry().left());
        screenObj.insert(QString::fromUtf8("top"), screen->geometry().top());
        mapScreenSizes.insert(screen->name(), screenObj);
    }
    return mapScreenSizes;
}

/* QMessageBox implementation for Qt <5.2 */
bool MainWindow::showRemoveContactDialog(shims::ContactUser *user)
{
    if (!user)
        return false;
    QMessageBox::StandardButton btn = QMessageBox::question(0,
        tr("Remove %1").arg(user->getNickname()),
        tr("Do you want to permanently remove %1?").arg(user->getNickname()));
    return btn == QMessageBox::Yes;
}

QQuickWindow *MainWindow::findParentWindow(QQuickItem *item)
{
    Q_ASSERT(item);
    return item ? item->window() : 0;
}

void MainWindow::initTranslation()
{
    QTranslator *translator = new QTranslator;

    bool ok = false;
    QString appPath = qApp->applicationDirPath();
    QString resPath = QLatin1String(":/lang/");

    QLocale locale = QLocale::system();
    if (!qgetenv("SPEEK_LOCALE").isEmpty()) {
        locale = QLocale(QString::fromLatin1(qgetenv("SPEEK_LOCALE")));
        qDebug() << "Forcing locale" << locale << "from environment" << locale.uiLanguages();
    }

    SettingsObject settings;
    QString settingsLanguage(settings.read("ui.language").toString());

    if (!settingsLanguage.isEmpty()) {
        locale = settingsLanguage;
    } else {
        //write an empty string to get "System default" language selected automatically in preferences
        settings.write(QStringLiteral("ui.language"), QString());
    }

    ok = translator->load(locale, QStringLiteral("speek"), QStringLiteral("_"), appPath);
    if (!ok)
        ok = translator->load(locale, QStringLiteral("speek"), QStringLiteral("_"), resPath);

    if (ok) {
        qApp->installTranslator(translator);

        QTranslator *qtTranslator = new QTranslator;
        ok = qtTranslator->load(QStringLiteral("qt_") + locale.name(), QLibraryInfo::location(QLibraryInfo::TranslationsPath));
        if (ok)
            qApp->installTranslator(qtTranslator);
        else
            delete qtTranslator;
    } else
        delete translator;
}

QPalette MainWindow::load_palette_from_file(QString file, QVariantMap* theme_color){
    QStringList color_group { "QPalette::Active", "QPalette::Disabled", "QPalette::Inactive" };
    QStringList color_role { "QPalette::WindowText", "QPalette::Button", "QPalette::Light", "QPalette::Midlight", "QPalette::Dark", "QPalette::Mid", "QPalette::Text", "QPalette::BrightText", "QPalette::ButtonText", "QPalette::Base", "QPalette::Window", "QPalette::Shadow", "QPalette::Highlight", "QPalette::HighlightedText", "QPalette::Link", "QPalette::LinkVisited", "QPalette::AlternateBase", "QPalette::NoRole", "QPalette::ToolTipBase", "QPalette::ToolTipText", "QPalette::PlaceholderText" };
    QPalette palette;
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

    #ifdef ANDROID
        if(theme_color->value("darkMode") == "true"){
            qDebug()<<"Darkmode activated";
            QQuickStyle::setStyle("Material");
            //qputenv("QT_QUICK_CONTROLS_STYLE", QByteArray("material"));
            qputenv("QT_QUICK_CONTROLS_MATERIAL_THEME", QByteArray("Dark"));
            qputenv("QT_QUICK_CONTROLS_MATERIAL_ACCENT", QByteArray("Indigo"));
            qputenv("QT_QUICK_CONTROLS_MATERIAL_BACKGROUND", QByteArray("Indigo"));

        }
        else{
            qDebug()<<"Lightmode activated";
            QQuickStyle::setStyle("Material");
            qputenv("QT_QUICK_CONTROLS_STYLE", QByteArray("material"));
            qputenv("QT_QUICK_CONTROLS_MATERIAL_THEME", QByteArray("Light"));
            qputenv("QT_QUICK_CONTROLS_MATERIAL_ACCENT", QByteArray("Indigo"));
        }
    #else
        qputenv("QT_QUICK_CONTROLS_STYLE", "Fusion");
    #endif

    return palette;
}

void MainWindow::initTheme(QVariantMap* theme_color)
{
    SettingsObject settings;
    if(settings.read("ui.useCustomTheme").toBool() == false || settings.read("ui.customTheme").toString().isEmpty()){
        if(settings.read("ui.theme").toString().isEmpty()){
            if(settings.read("ui.lightMode").toBool())
                qApp->setPalette(load_palette_from_file(":/themes/light", theme_color));
            else
                qApp->setPalette(load_palette_from_file(":/themes/dark-blue", theme_color));
        }
        else{
            qApp->setPalette(load_palette_from_file(":/themes/"+settings.read("ui.theme").toString().toLower(), theme_color));
        }
    }
    else{
        qApp->setPalette(load_palette_from_file(settings.read("ui.customTheme").toString(), theme_color));
    }
}

// Writes default settings to settings object. Does not care about any
// preexisting values, therefore this is best used on a fresh object.
void MainWindow::loadDefaultSettings(SettingsFile *settings)
{
    settings->root()->write("ui.combinedChatWindow", true);
    settings->root()->write("ui.minimizeToSystemtray", false);
    #ifdef ANDROID
        settings->root()->write("ui.showNotificationAndroid", true);
    #endif
}

bool MainWindow::initSettings(SettingsFile *settings, QLockFile **lockFile, QString &errorMessage, QString pathChange)
{
    /* speek by default loads and saves configuration files from QStandardPaths::AppConfigLocation
     *
     * Linux: ~/.config/speek
     * Windows: C:/Users/<USER>/AppData/Local/speek
     * macOS: ~/Library/Preferences/<APPNAME>
     *
     * speek can also load configuration files from a custom directory passed in as the first argument
     */

    QString configPath;
    QStringList args = qApp->arguments();

    if (args.size() > 1) {
        if(args[1].contains("/") || args[1].contains("\\"))
            configPath = args[1];
        else
            configPath = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + pathChange + args[1];
    } else {
        if(pathChange == "/")
            configPath = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
        else
            configPath = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + pathChange;
    }

    QDir dir(configPath);
    if (!dir.exists() && !dir.mkpath(QStringLiteral("."))) {
        errorMessage = QStringLiteral("Cannot create directory: %1").arg(dir.path());
        return false;
    }

    // Reset to config directory for consistency; avoid depending on this behavior for paths
    if (QDir::setCurrent(dir.absolutePath()) && dir.isRelative())
        dir.setPath(QStringLiteral("."));

    QLockFile *lock = new QLockFile(dir.filePath(QStringLiteral("speek.json.lock")));
    *lockFile = lock;
    lock->setStaleLockTime(0);
    if (!lock->tryLock()) {
        if (lock->error() == QLockFile::LockFailedError) {
            // This happens if a stale lock file exists and another process uses that PID.
            // Try removing the stale file, which will fail if a real process is holding a
            // file-level lock. A false error is more problematic than not locking properly
            // on corner-case systems.
            if (!lock->removeStaleLockFile() || !lock->tryLock()) {
                errorMessage = QStringLiteral("Configuration file is already in use");
                return false;
            } else
                qDebug() << "Removed stale lock file";
        } else {
            errorMessage = QStringLiteral("Cannot write configuration file (failed to acquire lock)");
            return false;
        }
    }

    settings->setFilePath(dir.filePath(QStringLiteral("speek.json")));
    if (settings->hasError()) {
        errorMessage = settings->errorMessage();
        return false;
    }

    // if still empty, load defaults here
    if (settings->root()->data().isEmpty()) {
        loadDefaultSettings(settings);
    }

    #ifdef ANDROID
        settings->root()->write("ui.combinedChatWindow", true);

        if(pathChange == "/" && settings->root()->read("ui.identityPromptOnStartup").toBool(false)){
            initTranslation();
            QVariantMap theme_color;
            initTheme(&theme_color);
            bool ok;
            QString identityName = QInputDialog::getText(nullptr, QInputDialog::tr("Enter the Identity Name to start (blank for default)"), QInputDialog::tr("Identity Name to start (blank for default):"), QLineEdit::Normal, "", &ok);
            if (ok && !identityName.isEmpty()){
                return initSettings(settings, lockFile, errorMessage, "/"+ identityName +"/");
            }
        }
    #endif

    return true;
}

void MainWindow::initFontSettings(){
    // increase font size for better reading
    QFont defaultFont = QApplication::font();
    defaultFont.setFamily("Noto Sans");

    SettingsObject settings;
    #ifdef Q_OS_OSX
        defaultFont.setPointSize(12 * settings.read("ui.fontSizeMultiplier").toDouble(1));
    #elif ANDROID
        defaultFont.setPointSize(12 * settings.read("ui.fontSizeMultiplier").toDouble(1));
    #else
        defaultFont.setPointSize(9 * settings.read("ui.fontSizeMultiplier").toDouble(1));
    #endif

    qApp->setFont(defaultFont);
}

void MainWindow::loadSettings(tego_context_t* tegoContext, shims::ContactsManager* contactsManager){
    auto privateKeyString = SettingsObject("identity").read<QString>("privateKey");
    if (privateKeyString.isEmpty())
    {
        tego_context_start_service(
            tegoContext,
            nullptr,
            nullptr,
            nullptr,
            0,
            tego::throw_on_error());
    }
    else
    {
        // construct privatekey from privateKey keyblob
        std::unique_ptr<tego_ed25519_private_key_t> privateKey;
        auto keyBlob = privateKeyString.toUtf8();

        tego_ed25519_private_key_from_ed25519_keyblob(
            tego::out(privateKey),
            keyBlob.data(),
            keyBlob.size(),
            tego::throw_on_error());

        // load all of our user objects
        std::vector<tego_user_id_t*> userIds;
        std::vector<tego_user_type_t> userTypes;
        auto userIdCleanup = tego::make_scope_exit([&]() -> void
        {
            std::for_each(userIds.begin(), userIds.end(), &tego_user_id_delete);
        });

        // map strings saved in json with tego types
        const static QMap<QString, tego_user_type_t> stringToUserType =
        {
            {QString("allowed"), tego_user_type_allowed},
            {QString("requesting"), tego_user_type_requesting},
            {QString("blocked"), tego_user_type_blocked},
            {QString("pending"), tego_user_type_pending},
            {QString("rejected"), tego_user_type_rejected},
        };

        auto usersJson = SettingsObject("users").data();
        for(auto it = usersJson.begin(); it != usersJson.end(); ++it)
        {
            // get the user's service id
            const auto serviceIdString = it.key();
            const auto serviceIdRaw = serviceIdString.toUtf8();

            std::unique_ptr<tego_v3_onion_service_id_t> serviceId;
            tego_v3_onion_service_id_from_string(
                tego::out(serviceId),
                serviceIdRaw.data(),
                serviceIdRaw.size(),
                tego::throw_on_error());

            std::unique_ptr<tego_user_id_t> userId;
            tego_user_id_from_v3_onion_service_id(
                tego::out(userId),
                serviceId.get(),
                tego::throw_on_error());
            userIds.push_back(userId.release());

            // load relevant data
            const auto& userData = it.value().toObject();
            auto typeString = userData.value("type").toString();

            Q_ASSERT(stringToUserType.contains(typeString));
            auto type = stringToUserType.value(typeString);
            userTypes.push_back(type);

            if (type == tego_user_type_allowed ||
                type == tego_user_type_pending ||
                type == tego_user_type_rejected)
            {
                const auto nickname = userData.value("nickname").toString();
                const auto icon = userData.contains("icon") ? userData.value("icon").toString() : "";
                const auto is_a_group = userData.contains("isGroup") ? userData.value("isGroup").toBool() : false;
                auto contact = contactsManager->addContact(serviceIdString, nickname, icon, is_a_group);
                switch(type)
                {
                case tego_user_type_allowed:
                    contact->setStatus(shims::ContactUser::Offline);
                    break;
                case tego_user_type_pending:
                    contact->setStatus(shims::ContactUser::RequestPending);
                    break;
                case tego_user_type_rejected:
                    contact->setStatus(shims::ContactUser::RequestRejected);
                    break;
                default:
                    break;
                }
            }
        }
        Q_ASSERT(userIds.size() == userTypes.size());
        const size_t userCount = userIds.size();

        tego_context_start_service(
            tegoContext,
            privateKey.get(),
            userIds.data(),
            userTypes.data(),
            userCount,
            tego::throw_on_error());
    }
}
