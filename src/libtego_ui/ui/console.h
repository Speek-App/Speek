#ifndef CONSOLE_H
#define CONSOLE_H

#include <QObject>
#include <QSocketNotifier>
#include <QtNetwork>
#include <iostream>

#include "utils/json.h"
#include "shims/UserIdentity.h"
#include "shims/ConversationModel.h"
#include "shims/IncomingContactRequest.h"

class Console : public QObject
{
    Q_OBJECT;

public:
    Console();
    ~Console();

    void run();

signals:
    void quit();

private:
    QSocketNotifier *m_notifier;
    QLocalSocket *socket;
    QLocalServer *server;
    QString serverName;

    void writeData(QString data);
    shims::ContactUser* findUserById(const std::string& id);

    void handleQuit(nlohmann::json &command, nlohmann::json &res);
    void handleGetContacts(nlohmann::json &command, nlohmann::json &res);
    void handleSendMessage(nlohmann::json &command, nlohmann::json &res);
    void handleGetId(nlohmann::json &command, nlohmann::json &res);
    void handleCreateContactRequest(nlohmann::json &command, nlohmann::json &res);
    void handleAcceptFileTransfer(const nlohmann::json &command, nlohmann::json &res);
    void handleCancelFileTransfer(const nlohmann::json &command, nlohmann::json &res);
    void handleRejectFileTransfer(const nlohmann::json &command, nlohmann::json &res);
    void handleSendFile(const nlohmann::json &command, nlohmann::json &res);
    void handleRemoveContact(const nlohmann::json &command, nlohmann::json &res);
    void handleRenameContact(const nlohmann::json &command, nlohmann::json &res);
    void handleSetIconContact(const nlohmann::json &command, nlohmann::json &res);
    void handleAcceptContactRequest(const nlohmann::json &command, nlohmann::json &res);
    void handleRejectContactRequestAndBlockUser(const nlohmann::json &command, nlohmann::json &res);
    void handleRejectContactRequest(const nlohmann::json &command, nlohmann::json &res);
    void handleSetNickname(const nlohmann::json &command, nlohmann::json &res);
    void handleSetPruneLimit(const nlohmann::json &command, nlohmann::json &res);
    void handleExportIdentity(const nlohmann::json &command, nlohmann::json &res);
    void handleGetConfigLocation(const nlohmann::json &command, nlohmann::json &res);
    void handleSendAllPendingContactRequests(const nlohmann::json &command, nlohmann::json &res);
    void handleGetTorManagerInfo(nlohmann::json &command, nlohmann::json &res);

private slots:
    void readCommand();
    void handleDisconnect();

    void onNewConnection();
    void onReadyRead();
    void onMessageUpdate(nlohmann::json data);
    void onNewContactRequest(shims::IncomingContactRequest *request);
    void onContactRequestRemoved(QString id);
    void onTorStateChanged();
    void onContactStatusChanged();
};

#endif // CONSOLE_H
