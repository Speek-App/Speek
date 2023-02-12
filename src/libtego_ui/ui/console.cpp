#include <iostream>
#include "ui/console.h"
#include "shims/TorControl.h"
#include "shims/TorManager.h"

#include <QtNetwork>
#include <stdlib.h>
#include <QTextDocument>
#include <QRegExp>

Console::Console()
{
    m_notifier = new QSocketNotifier(fileno(stdin), QSocketNotifier::Read, this);

    serverName = "SpeekServerIPC";
    QLocalServer::removeServer(serverName);

    socket = nullptr;

    server = new QLocalServer(this);
    server->setSocketOptions(QLocalServer::WorldAccessOption);

    if (!server->listen(serverName)) {
        qCritical() << "[ERROR]  Unable to start the server:" << server->errorString();
        qApp->quit();
        return;
    }

    connect(server, SIGNAL(newConnection()), this, SLOT(onNewConnection()));
    connect(shims::UserIdentity::userIdentity, &shims::UserIdentity::requestAdded, this, &Console::onNewContactRequest);
    connect(shims::UserIdentity::userIdentity, &shims::UserIdentity::requestRemoved, this, &Console::onContactRequestRemoved);

    connect(shims::TorControl::torControl, &shims::TorControl::statusChanged, this, &Console::onTorStateChanged);
    connect(shims::TorControl::torControl, &shims::TorControl::torStatusChanged, this, &Console::onTorStateChanged);
    connect(shims::TorControl::torControl, &shims::TorControl::bootstrapStatusChanged, this, &Console::onTorStateChanged);

    for(auto cu : shims::UserIdentity::userIdentity->getContacts()->contacts())
    {
        connect(cu->conversation(), &shims::ConversationModel::newIncomingMessage, this, &Console::onMessageUpdate);
        connect(cu, &shims::ContactUser::statusChanged, this, &Console::onContactStatusChanged);
    }

    qInfo()<<"[INFO] Started IPC Server";
}

Console::~Console()
{
    QLocalServer::removeServer(serverName);
}

void Console::onNewConnection() {
    qInfo()<<"[INFO] New IPC Connection";
    socket = server->nextPendingConnection();
    connect(socket, &QLocalSocket::readyRead, this, &Console::onReadyRead);
    connect(socket, &QLocalSocket::disconnected, this, &Console::handleDisconnect);
}

void Console::handleDisconnect()
{
    socket->deleteLater();
    socket = nullptr;
}

void Console::onContactStatusChanged(){
    if(socket == nullptr)
        return;

    shims::ContactUser* cu = dynamic_cast<shims::ContactUser*>(sender());

    nlohmann::json data;
    data["what"] = "update_contact_status";
    data["id"] = cu->getContactID().toStdString();
    data["name"] = cu->getNickname().toStdString();
    data["is_group"] = cu->getIsAGroup();
    data["status"] = cu->getStatus();

    writeData(QString::fromStdString(data.dump()));
}

void Console::onTorStateChanged(){
    if(socket == nullptr || shims::TorControl::torControl == nullptr)
        return;

    nlohmann::json data;
    data["what"] = "tor_status_changed";
    data["tor_control_status"] = shims::TorControl::torControl->status();
    data["tor_network_status"] = shims::TorControl::torControl->torStatus();

    QVariantMap b_status = shims::TorControl::torControl->bootstrapStatus();
    data["progress"] = b_status["progress"].toUInt();
    data["tag"] = b_status["tag"].toString().toStdString();
    data["summary"] = b_status["summary"].toString().toStdString();
    data["tor_version"] = shims::TorControl::torControl->torVersion().toStdString();
    data["error_message"] = shims::TorControl::torControl->errorMessage().toStdString();

    writeData(QString::fromStdString(data.dump()));
}

void Console::onContactRequestRemoved(QString id){
    if(socket == nullptr)
        return;

    nlohmann::json data;
    data["what"] = "contact_request_removed";
    data["id"] = id.toStdString();

    writeData(QString::fromStdString(data.dump()));
}

void Console::onNewContactRequest(shims::IncomingContactRequest *request){
    if(socket == nullptr)
        return;

    nlohmann::json data;
    data["what"] = "contact_request";
    data["id"] = request->getContactId().toStdString();
    data["name"] = request->getNickname().toStdString();
    data["message"] = request->getMessage().toStdString();
    data["is_group"] = request->getIsGroup();
    data["incoming_request"] = true;

    writeData(QString::fromStdString(data.dump()));
}

void Console::onMessageUpdate(nlohmann::json data){
    if(socket == nullptr)
        return;

    if (Qt::mightBeRichText(QString::fromStdString(data["text"]))){
        QString imageText = QString::fromStdString(data["text"]);
        if (!imageText.isEmpty() && imageText.indexOf("\n") == -1 && imageText.indexOf("\r") == -1) {
            QRegExp pattern("<html><head><meta name=\"qrichtext\"></head><body><img name=\"([A-Za-z0-9-_. ]{0,40})\" width=\"(\\d{1,4})\" height=\"(\\d{1,4})\" src=\"((data:image/jpg;base64,)([A-Za-z0-9+/=]+))\" /></body></html>");
            int pos = pattern.indexIn(imageText);
            if (pos != -1) {
                data["plaintext"] = "";
                data["image"] = pattern.cap(6).toStdString();
                data["image_caption"] = pattern.cap(1).toStdString();
                data["type"] = 2;
                goto END;
            }
        }

        QTextDocument doc;
        doc.setHtml(QString::fromStdString(data["text"]));
        QString plainText = doc.toPlainText();

        data["plaintext"] = plainText.toStdString();
    }
    else{
        data["plaintext"] = data["text"];
    }
    END:
    data["what"] = "message_update";

    writeData(QString::fromStdString(data.dump()));
}

void Console::writeData(QString data){
    QByteArray block;
    QDataStream out(&block, QIODevice::WriteOnly);

    out.setVersion(QDataStream::Qt_5_15);
    out << quint32(data.toUtf8().size());
    out << data.toUtf8();

    if (socket && socket->state() == QLocalSocket::ConnectedState){
        socket->write(block);
        socket->flush();
    }
}

shims::ContactUser* Console::findUserById(const std::string& id) {
    for(auto cu : shims::UserIdentity::userIdentity->getContacts()->contacts())
    {
        if(cu->getContactID().toStdString() == id){
            return cu;
        }
    }
    return nullptr;
}

void Console::handleQuit(nlohmann::json &command, nlohmann::json &res)
{
    Q_UNUSED(command);

    res["status"] = "success";
    writeData(QString::fromStdString(res.dump()));
    emit quit();
}

void Console::handleGetContacts(nlohmann::json &command, nlohmann::json &res)
{
    Q_UNUSED(command);

    for(auto cu : shims::UserIdentity::userIdentity->getContacts()->contacts())
    {
        nlohmann::json t;
        t["id"] = cu->getContactID().toStdString();
        t["name"] = cu->getNickname().toStdString();
        t["is_group"] = cu->getIsAGroup();
        t["status"] = cu->getStatus();
        res["out"].push_back(t);
    }
}

void Console::handleSendMessage(nlohmann::json &command, nlohmann::json &res)
{
    Q_UNUSED(res);

    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't send message");
    if (!command.contains("message") || !command["message"].is_string())
        throw std::invalid_argument("missing message, can't send message");

    shims::ContactUser* sendTo = findUserById(command["id"]);
    if (!sendTo) throw std::invalid_argument("No user found with this id");

    QString message = QString::fromStdString(command["message"]);
    sendTo->conversation()->sendMessage(message);
}

void Console::handleGetTorManagerInfo(nlohmann::json &command, nlohmann::json &res)
{
    Q_UNUSED(command);
    QStringList logMessages = shims::TorManager::torManager->logMessages();
    for (QStringList::iterator i = logMessages.begin(); i != logMessages.end(); ++i) {
        res["messages"].push_back(i->toStdString());
    }

    res["configuration_needed"] = shims::TorManager::torManager->configurationNeeded();
    res["error_message"] = shims::TorManager::torManager->errorMessage().toStdString();
    res["has_error"] = shims::TorManager::torManager->hasError();
}

void Console::handleGetId(nlohmann::json &command, nlohmann::json &res)
{
    Q_UNUSED(command);

    res["id"] = shims::UserIdentity::userIdentity->contactID().toStdString();

    SettingsObject settings;
    res["name"] = settings.read("ui.username").toString().toStdString();
}

void Console::handleCreateContactRequest(nlohmann::json &command, nlohmann::json &res)
{
    Q_UNUSED(res);

    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't add contact");
    if (!command.contains("name") || !command["name"].is_string())
        throw std::invalid_argument("missing name, can't add contact");

    QString icon = "";
    if(command.contains("icon") && command["icon"].is_string()){
        icon = QString::fromStdString(command["icon"]);
    }
    QString myNickname = "Speek-User";
    if(command.contains("myNickname") && command["myNickname"].is_string()){
        myNickname = QString::fromStdString(command["myNickname"]);
    }
    QString message = "";
    if(command.contains("message") && command["message"].is_string()){
        message = QString::fromStdString(command["message"]);
    }

    shims::UserIdentity::userIdentity->getContacts()->createContactRequest(
            QString::fromStdString(command["id"]),
            QString::fromStdString(command["name"]),
            myNickname, message, icon);
}

void Console::handleAcceptFileTransfer(const nlohmann::json &command, nlohmann::json &res){
    Q_UNUSED(res);

    if (!command.contains("file_id") || !command["file_id"].is_number_unsigned())
        throw std::invalid_argument("missing file_id, can't accept file transfer");
    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't accept file transfer");
    if (!command.contains("destination") || !command["destination"].is_string())
        throw std::invalid_argument("missing destination, can't accept file transfer");

    shims::ContactUser* fileFrom = findUserById(command["id"]);
    if (!fileFrom) throw std::invalid_argument("No user found with this id");

    fileFrom->conversation()->tryAcceptFileTransfer(qint32(command["file_id"]), QString::fromStdString(command["destination"]));
}

void Console::handleRejectFileTransfer(const nlohmann::json &command, nlohmann::json &res){
    Q_UNUSED(res);

    if (!command.contains("file_id") || !command["file_id"].is_number_unsigned())
        throw std::invalid_argument("missing file_id, can't reject file transfer");
    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't reject file transfer");

    shims::ContactUser* fileFrom = findUserById(command["id"]);
    if (!fileFrom) throw std::invalid_argument("No user found with this id");

    fileFrom->conversation()->rejectFileTransfer(qint32(command["file_id"]));
}

void Console::handleCancelFileTransfer(const nlohmann::json &command, nlohmann::json &res){
    Q_UNUSED(res);

    if (!command.contains("file_id") || !command["file_id"].is_number_unsigned())
        throw std::invalid_argument("missing file_id, can't cancel file transfer");
    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't cancel file transfer");

    shims::ContactUser* fileFrom = findUserById(command["id"]);
    if (!fileFrom) throw std::invalid_argument("No user found with this id");

    fileFrom->conversation()->cancelFileTransfer(qint32(command["file_id"]));
}

void Console::handleSendFile(const nlohmann::json &command, nlohmann::json &res){
    Q_UNUSED(res);

    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't send file");
    if (!command.contains("source_file") || !command["source_dir"].is_string())
        throw std::invalid_argument("missing destination, can't send file");

    shims::ContactUser* fileTo = findUserById(command["id"]);
    if (!fileTo) throw std::invalid_argument("No user found with this id");

    fileTo->conversation()->sendFile(QString::fromStdString(command["source_file"]));
}

void Console::handleRemoveContact(const nlohmann::json &command, nlohmann::json &res) {
    Q_UNUSED(res);

    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't remove contact");

    shims::ContactUser* deleteContact = findUserById(command["id"]);
    if (!deleteContact) throw std::invalid_argument("No user found with this id");

    deleteContact->deleteContact();
}

void Console::handleRenameContact(const nlohmann::json &command, nlohmann::json &res) {
    Q_UNUSED(res);

    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't rename contact");
    if (!command.contains("nickname") || !command["nickname"].is_string())
        throw std::invalid_argument("missing nickname, can't rename contact");

    shims::ContactUser* renameContact = findUserById(command["id"]);
    if (!renameContact) throw std::invalid_argument("No user found with this id");

    renameContact->setNickname(QString::fromStdString(command["nickname"]));
}

void Console::handleSetIconContact(const nlohmann::json &command, nlohmann::json &res) {
    Q_UNUSED(res);

    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't set icon");
    if (!command.contains("icon") || !command["icon"].is_string())
        throw std::invalid_argument("missing icon, can't set icon");

    shims::ContactUser* setIconContact = findUserById(command["id"]);
    if (!setIconContact) throw std::invalid_argument("No user found with this id");

    setIconContact->setIcon(QString::fromStdString(command["icon"]));
}

void Console::handleSendAllPendingContactRequests(const nlohmann::json &command, nlohmann::json &res) {
    Q_UNUSED(command);Q_UNUSED(res);

    for(auto cu : shims::UserIdentity::userIdentity->getRequests())
        onNewContactRequest(dynamic_cast<shims::IncomingContactRequest*>(cu));
}

void Console::handleAcceptContactRequest(const nlohmann::json &command, nlohmann::json &res) {
    Q_UNUSED(res);

    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't accept contact request");
    if (!command.contains("nickname") || !command["nickname"].is_string())
        throw std::invalid_argument("missing nickname, can't accept contact request");

    shims::IncomingContactRequest* contact = nullptr;
    for(auto cu : shims::UserIdentity::userIdentity->getRequests()){
        if(dynamic_cast<shims::IncomingContactRequest*>(cu)->getContactId() == QString::fromStdString(command["id"])){
            contact = dynamic_cast<shims::IncomingContactRequest*>(cu);
            break;
        }
    }
    if (!contact) throw std::invalid_argument("No user found with this id");

    contact->setNickname(QString::fromStdString(command["nickname"]));
    contact->accept();
}

void Console::handleRejectContactRequest(const nlohmann::json &command, nlohmann::json &res) {
    Q_UNUSED(res);

    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't reject contact request");

    shims::IncomingContactRequest* contact = nullptr;
    for(auto cu : shims::UserIdentity::userIdentity->getRequests()){
        if(dynamic_cast<shims::IncomingContactRequest*>(cu)->getContactId() == QString::fromStdString(command["id"])){
            contact = dynamic_cast<shims::IncomingContactRequest*>(cu);
            break;
        }
    }
    if (!contact) throw std::invalid_argument("No user found with this id");

    contact->deny();
}

void Console::handleRejectContactRequestAndBlockUser(const nlohmann::json &command, nlohmann::json &res) {
    Q_UNUSED(res);

    if (!command.contains("id") || !command["id"].is_string())
        throw std::invalid_argument("missing id, can't reject and block contact request");

    shims::IncomingContactRequest* contact = nullptr;
    for(auto cu : shims::UserIdentity::userIdentity->getRequests()){
        if(dynamic_cast<shims::IncomingContactRequest*>(cu)->getContactId() == QString::fromStdString(command["id"])){
            contact = dynamic_cast<shims::IncomingContactRequest*>(cu);
            break;
        }
    }
    if (!contact) throw std::invalid_argument("No user found with this id");

    contact->reject();
}

void Console::handleSetNickname(const nlohmann::json &command, nlohmann::json &res) {
    Q_UNUSED(res);

    if (!command.contains("nickname") || !command["nickname"].is_string())
        throw std::invalid_argument("missing nickname, can't set nickname");

    SettingsObject settings;
    settings.write(QStringLiteral("ui.username"), QString::fromStdString(command["nickname"]));
}

void Console::handleSetPruneLimit(const nlohmann::json &command, nlohmann::json &res) {
    Q_UNUSED(res);Q_UNUSED(command);
// Implementation of setting the global chat prune limit
}

void Console::handleExportIdentity(const nlohmann::json &command, nlohmann::json &res) {
    Q_UNUSED(res);Q_UNUSED(command);
// Implementation of exporting an identity
}

void Console::handleGetConfigLocation(const nlohmann::json &command, nlohmann::json &res) {
    Q_UNUSED(command);

    QDir dir(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation));
    res["config_location"] = dir.absolutePath().toStdString();
}

void Console::onReadyRead() {
    auto socket = dynamic_cast<QLocalSocket*>(sender());
    if (!socket)
        return;

    QDataStream in(socket);
    in.setVersion(QDataStream::Qt_5_15);

    while (socket->bytesAvailable() > 0) {
        in.startTransaction();

        qint32 version;
        in >> version;

        quint32 size;
        in >> size;

        QByteArray data(size, 0);
        qint64 readBytes = in.readRawData(data.data(), size);

        if (readBytes != size) {
            // not all requested bytes were read from the stream, return and wait for remaining
            return;
        }

        if (!in.commitTransaction()) {
            return;
        }

        nlohmann::json command, res;
        try {
            command = nlohmann::json::parse(data);
            res["com"] = command["com"];
            if(command.contains("token") && command["token"].is_number_unsigned()){
                res["token"] = command["token"];
            }

            if (command["com"] == "quit")
                handleQuit(command, res);
            else if(command["com"] == "getContacts")
                handleGetContacts(command, res);
            else if(command["com"] == "sendMessage")
                handleSendMessage(command, res);
            else if(command["com"] == "getId")
                handleGetId(command, res);
            else if(command["com"] == "createContactRequest")
                handleCreateContactRequest(command, res);
            else if(command["com"] == "acceptFileTransfer")
                handleAcceptFileTransfer(command, res);
            else if(command["com"] == "cancelFileTransfer")
                handleCancelFileTransfer(command, res);
            else if(command["com"] == "rejectFileTransfer")
                handleRejectFileTransfer(command, res);
            else if(command["com"] == "sendFile")
                handleSendFile(command, res);
            else if(command["com"] == "removeContact")
                handleRemoveContact(command, res);
            else if(command["com"] == "renameContact")
                handleRenameContact(command, res);
            else if(command["com"] == "setIconContact")
                handleSetIconContact(command, res);
            else if(command["com"] == "acceptContactRequest")
                handleAcceptContactRequest(command, res);
            else if(command["com"] == "refuseContactRequestAndBlockUser")
                handleRejectContactRequestAndBlockUser(command, res);
            else if(command["com"] == "refuseContactRequest")
                handleRejectContactRequest(command, res);
            else if(command["com"] == "setNickname")
                handleSetNickname(command, res);
            else if(command["com"] == "setPruneLimit")
                handleSetPruneLimit(command, res);
            else if(command["com"] == "exportIdentity")
                handleExportIdentity(command, res);
            else if(command["com"] == "getConfigLocation")
                handleGetConfigLocation(command, res);
            else if(command["com"] == "getAllContactRequests")
                handleSendAllPendingContactRequests(command, res);
            else if(command["com"] == "getTorManagerInfo")
                handleGetTorManagerInfo(command, res);
            else if(command["com"] == "getAllMessages")
                for(auto cu : shims::UserIdentity::userIdentity->getContacts()->contacts())
                    cu->conversation()->addEmitConsoleEventFromAllMessages();
            else
                throw std::invalid_argument("unknown command");

            res["status"] = "success";
        }
        catch (const std::invalid_argument &ex) {
            qWarning() << "[WARN] Invalid argument: " << ex.what();
            res["status"] = "fail";
            res["reason"] = ex.what();
        }
        catch (nlohmann::json::exception &ex) {
            qWarning() << "[WARN] Error parsing JSON data: " << ex.what();
            res["status"] = "fail";
            res["reason"] = "error parsing JSON data: " + std::string(ex.what());
        }
        catch(...){
            qWarning()<<"[WARN] Unknown error";
            res["status"] = "fail";
            res["reason"] = "unknown error";
        }

        writeData(QString::fromStdString(res.dump()));
    }
}

void Console::run()
{
    connect(m_notifier, SIGNAL(activated(int)), this, SLOT(readCommand()));
}

void Console::readCommand()
{
    std::string line;
    std::getline(std::cin, line);
    if (std::cin.eof() || line == "quit") {
        std::cout << "Closing Application!" << std::endl;
        emit quit();
    } else {
        std::cout << "Unknown Command: " << line << std::endl;
        std::cout << "> " << std::flush;
    }
}
