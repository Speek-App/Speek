#include "ContactUser.h"
#include "ConversationModel.h"
#include "UserIdentity.h"
#include "ContactsManager.h"
#include "utils/json.h"
#include "utility.h"

#ifdef ANDROID
#include <QAndroidJniObject>
#include <QAndroidJniEnvironment>
#include <QtAndroid>
#endif

namespace shims
{
QMutex ConversationModel::mutex;
    ConversationModel::ConversationModel(QObject *parent, bool group)
    : QAbstractListModel(parent)
    , contactUser(nullptr)
    , messages({})
    , unreadCount(0)
    , isGroupHostMode(group)
    {
        connect(this, &ConversationModel::unreadCountChanged, [self=this](int prevCount, int currentCount) -> void
        {
            static int globalUnreadCount = 0;

            const auto delta = currentCount - prevCount;
            globalUnreadCount += delta;

            qDebug() << "globalUnreadCount:" << globalUnreadCount;
#ifdef Q_OS_MAC
            QtMac::setBadgeLabelText(globalUnreadCount == 0 ? QString() : QString::number(globalUnreadCount));
#endif
        });
    }

    QHash<int,QByteArray> ConversationModel::roleNames() const
    {
        QHash<int, QByteArray> roles;
        roles[Qt::DisplayRole] = "text";
        roles[Qt::CheckStateRole] = "prep_text";
        roles[TimestampRole] = "timestamp";
        roles[IsOutgoingRole] = "isOutgoing";
        roles[StatusRole] = "status";
        roles[SectionRole] = "section";
        roles[TimespanRole] = "timespan";
        roles[TypeRole] = "type";
        roles[TransferRole] = "transfer";
        roles[GroupUserRole] = "group_user_nickname";
        roles[GroupUserIdRole] = "group_user_id_hash";
        return roles;
    }

    int ConversationModel::rowCount(const QModelIndex &parent) const
    {
        if (parent.isValid())
            return 0;
        return messages.size();
    }

    QVariant ConversationModel::data(const QModelIndex &index, int role) const
    {
        if (!index.isValid() || index.row() >= messages.size())
            return QVariant();

        const MessageData &message = messages[index.row()];

        switch (role) {
            case Qt::DisplayRole:
                if (message.type == TextMessage)
                {
                    return message.text;
                }
                else
                {
                    return QStringLiteral("not a text message");
                }
        case Qt::CheckStateRole:
            if (message.type == TextMessage)
            {
                return message.prep_text;
            }
            else
            {
                return QStringLiteral("not a text message");
            }

            case TimestampRole: return message.time;
            case IsOutgoingRole: return message.status != Received;
            case StatusRole: return message.status;
            case GroupUserRole: return message.group_user_nickname;
            case GroupUserIdRole: return message.group_user_id_hash;

            case SectionRole: {
                if (contact()->getStatus() == ContactUser::Online)
                    return QString();
                if (index.row() < messages.size() - 1) {
                    const MessageData &next = messages[index.row()+1];
                    if (next.status != Received && next.status != Delivered)
                        return QString();
                }
                for (int i = 0; i <= index.row(); i++) {
                    if (messages[i].status == Received || messages[i].status == Delivered)
                        return QString();
                }
                return QStringLiteral("offline");
            }
            case TimespanRole: {
                if (index.row() < messages.size() - 1)
                    return messages[index.row() + 1].time.secsTo(messages[index.row()].time);
                else
                    return -1;
            }
            case TypeRole: {
                if (message.type == TextMessage) {
                    return QStringLiteral("text");
                }
                else if (message.type == TransferMessage) {
                    return QStringLiteral("transfer");
                }
                else {
                    return QStringLiteral("invalid");
                }
            case TransferRole:
                if (message.type == TransferMessage)
                {
                    QVariantMap transfer;
                    transfer["file_name"] = message.fileName;
                    transfer["file_size"] = message.fileSize;
                    transfer["file_hash"] = message.fileHash;
                    transfer["id"] = message.identifier;
                    transfer["status"] = message.transferStatus;
                    transfer["statusString"] = [=]()
                    {
                        switch(message.transferStatus)
                        {
                            case Pending: {
                                if(message.transferDirection == TransferDirection::Uploading)
                                    return tr("Contact has to accept transfer");
                                else
                                    return tr("Pending");
                            }
                            case Accepted: return tr("Accepted");
                            case Rejected: return tr("Rejected");
                            case InProgress:
                            {
                                const auto locale = QLocale::system();
                                return QString("%1 / %2 (%3/s)").arg(locale.formattedDataSize(message.bytesTransferred)).arg(locale.formattedDataSize(message.fileSize)).arg(locale.formattedDataSize(message.transferDownloadSpeed));
                            }
                            case Cancelled: return tr("Cancelled");
                            case Finished: return tr("Complete");
                            case UnknownFailure: return tr("Unkown Failure");
                            case BadFileHash: return tr("Bad File Hash");
                            case NetworkError: return tr("Network Error");
                            case FileSystemError: return tr("File System Error");

                            default: return tr("Invalid");
                        }
                    }();
                    transfer["progressPercent"] = double(message.bytesTransferred) / double(message.fileSize);
                    transfer["direction"] = message.transferDirection;

                    return transfer;
                }
            }
        }

        return QVariant();
    }

    shims::ContactUser* ConversationModel::contact() const
    {
        return contactUser;
    }

    void ConversationModel::setContact(shims::ContactUser *contact)
    {
        this->contactUser = contact;
        emit contactChanged();
    }

    int ConversationModel::getUnreadCount() const
    {
        return unreadCount;
    }

    void ConversationModel::resetUnreadCount()
    {
        this->setUnreadCount(0);
    }

    void ConversationModel::setUnreadCount(int count)
    {
        Q_ASSERT(count >= 0);

        const auto oldUnreadCount = this->unreadCount;
        if(oldUnreadCount != count)
        {
            this->unreadCount = count;
            emit unreadCountChanged(oldUnreadCount, unreadCount);

            auto userIdentity = shims::UserIdentity::userIdentity;
            auto contactsManager = userIdentity->getContacts();
            contactsManager->setUnreadCount(this->contactUser, count);
        }
    }

    void ConversationModel::sendMessage(const QString &text)
    {
        logger::println("sendMessage : {}", text);
        auto userIdentity = shims::UserIdentity::userIdentity;
        auto context = userIdentity->getContext();

        auto utf8Str = text.toUtf8();
        if (utf8Str.size() == 0)
        {
            return;
        }

        const auto userId = this->contactUser->toTegoUserId();
        tego_message_id_t messageId = 0;

        // send message and save off the id associated with it
        tego_context_send_message(
            context,
            userId.get(),
            utf8Str.data(),
            utf8Str.size(),
            &messageId,
            tego::throw_on_error());

        if(isGroupHostMode)
            return;

        // store data locally for UI
        MessageData md;
        md.type = TextMessage;
        if(this->contact()->is_a_group){
            if(text.length() > 6 && nlohmann::json::accept(text.toStdString())){
                nlohmann::json j = nlohmann::json::parse(text.toStdString());
                if(j.contains("message") && j["message"].is_string() && j["message"].size() < 252000){
                    md.text = QString::fromStdString(j["message"]);
                }
                else{
                    md.text = "";
                }
                if(j.contains("name") && j["name"].is_string()){
                    md.group_user_nickname = QString::fromStdString(j["name"]);
                }
                else{
                    md.group_user_nickname = "Anonymous";
                }
                if(j.contains("id") && j["id"].is_string()){
                    md.group_user_id_hash = QString::fromStdString(j["id"]);
                }
                else{
                    return;
                }
            }
        }
        else{
            md.text = text;
        }
        md.time = QDateTime::currentDateTime();
        md.identifier = messageId;
        md.status = Queued;

        this->beginInsertRows(QModelIndex(), 0, 0);
        this->messages.prepend(std::move(md));
        this->endInsertRows();
        this->addEventFromMessage(indexOfOutgoingMessage(messageId));
    }

    void ConversationModel::sendFile(QString path)
    {
        QString filePath;
        if(path == "")
            filePath =
                QFileDialog::getOpenFileName(
                    nullptr,
                    tr("Open File"),
                    QDir::homePath(),
                    nullptr);
        else
            filePath = path;

#ifdef ANDROID
        QFile a(filePath);
        QMimeDatabase db;
        QMimeType mime = db.mimeTypeForFile(filePath, QMimeDatabase::MatchContent);
        QString suf = mime.preferredSuffix();
        if(!suf.isEmpty())
            suf = "." + suf;
        const auto proposedDest = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/file_" + Utility::GetRandomString(5) + suf;
        if(a.copy(proposedDest)){
            filePath = proposedDest;
        }
        else{
            return;
        }
#endif
        if (!filePath.isEmpty())
        {
            auto userIdentity = shims::UserIdentity::userIdentity;
            auto context = userIdentity->getContext();
            const auto path = filePath.toUtf8();
            const auto userId = this->contactUser->toTegoUserId();
            tego_file_transfer_id_t id;
            std::unique_ptr<tego_file_hash_t> fileHash;
            tego_file_size_t fileSize = 0;

            try
            {
                tego_context_send_file_transfer_request(
                    context,
                    userId.get(),
                    path.data(),
                    path.size(),
                    &id,
                    tego::out(fileHash),
                    &fileSize,
                    tego::throw_on_error());

                logger::println("send file request id : {}, hash : {}", id, tego::to_string(fileHash.get()));

                MessageData md;
                md.type = TransferMessage;
                md.identifier = id;
                md.time = QDateTime::currentDateTime();
                md.status = Queued;

                md.fileName = QFileInfo(filePath).fileName();
                md.fileSize = fileSize;
                md.fileHash = QString::fromStdString(tego::to_string(fileHash.get()));
                md.transferStatus = Pending;
                md.transferDirection = Uploading;

                this->beginInsertRows(QModelIndex(), 0, 0);
                this->messages.prepend(std::move(md));
                this->endInsertRows();

                this->addEventFromMessage(indexOfOutgoingMessage(id));
            }
            catch(const std::runtime_error& err)
            {
                qWarning() << err.what();
            }
        }
    }

    void ConversationModel::deserializeTextMessageEventToFile(const EventData &event, std::ofstream &ofile) const
    {
        auto &md = this->messages[this->messages.size() - event.messageData.reverseIndex];
        QString text = md.text;
        text.remove(QRegExp("[\\n\\t\\r]"));
        switch (md.status)
        {
            case Received:
                fmt::print(ofile, "[{}] <{}>: {}\n",
                                    md.time.toString().toStdString(),
                                    this->contact()->getNickname().toStdString(),
                                    text.toStdString()); break;
            case Delivered:
                fmt::print(ofile, "[{}] <{}>: {}\n",
                                    md.time.toString().toStdString(),
                                    tr("me").toStdString(),
                                    text.toStdString()); break;
            default:
                // messages we sent that weren't delivered
                fmt::print(ofile, "[{}] <{}> ({}): {}\n",
                                    md.time.toString().toStdString(),
                                    tr("me").toStdString(),
                                    getMessageStatusString(md.status),
                                    text.toStdString()); break;
        }
    }

    void ConversationModel::deserializeTransferMessageEventToFile(const EventData &event, std::ofstream &ofile) const
    {
        auto &md = this->messages[this->messages.size() - event.transferData.reverseIndex];

        if (md.transferDirection == InvalidDirection)
            return;

        std::string sender = md.transferDirection == Uploading
                                    ? tr("me").toStdString()
                                    : this->contact()->getNickname().toStdString();

        switch (event.transferData.status)
        {
            case Pending:           //FALLTHROUGH
            case Accepted:          //FALLTHROUGH
            case Rejected:          //FALLTHROUGH
            case Cancelled:         //FALLTHROUGH
            case Finished:
                fmt::print(ofile, "[{}] file '{}' from <{}> (hash: {}, size: {:L} bytes): {}\n",
                                    event.time.toString().toStdString(),
                                    md.fileName.toStdString(),
                                    sender,
                                    md.fileHash.toStdString(),
                                    md.fileSize,
                                    getTransferStatusString(event.transferData.status)); break;
            case UnknownFailure:    //FALLTHROUGH
            case BadFileHash:       //FALLTHROUGH
            case NetworkError:      //FALLTHROUGH
            case FileSystemError:
                fmt::print(ofile, "[{}] file '{}' from <{}> (hash: {}, size: {:L} bytes): Error: {}, bytes transferred: {:L} bytes\n",
                                    event.time.toString().toStdString(),
                                    md.fileName.toStdString(),
                                    sender,
                                    md.fileHash.toStdString(),
                                    md.fileSize,
                                    getTransferStatusString(event.transferData.status),
                                    event.transferData.bytesTransferred); break;
            default:
                qWarning() << "Invalid transfer status in events";
                break;
        }
    }

    void ConversationModel::deserializeUserStatusUpdateEventToFile(const EventData &event, std::ofstream &ofile) const
    {
        if (event.userStatusData.target == UserTargetNone)
            return;

        std::string sender = event.userStatusData.target == UserTargetClient
                                    ? tr("me").toStdString()
                                    : this->contact()->getNickname().toStdString();

        switch (event.userStatusData.status)
        {
            case ContactUser::Status::Online:
                fmt::print(ofile, "[{}] <{}> is now online\n",
                                    event.time.toString().toStdString(),
                                    this->contact()->getNickname().toStdString()); break;
            case ContactUser::Status::Offline:
                fmt::print(ofile, "[{}] <{}> is now offline\n",
                                    event.time.toString().toStdString(),
                                    this->contact()->getNickname().toStdString()); break;
            case ContactUser::Status::RequestPending:
                fmt::print(ofile, "[{}] New contact request to <{}>\n",
                                    event.time.toString().toStdString(),
                                    this->contact()->getNickname().toStdString()); break;
            case ContactUser::Status::RequestRejected:
                fmt::print(ofile, "[{}] Outgoing request to <{}> was rejected\n",
                                    event.time.toString().toStdString(),
                                    this->contact()->getNickname().toStdString()); break;
            default:
                break;
        }
    }

    void ConversationModel::deserializeEventToFile(const EventData &event, std::ofstream &ofile) const
    {
        switch (event.type)
        {
            case TextMessageEvent:
                deserializeTextMessageEventToFile(event, ofile); break;
            case TransferMessageEvent:
                deserializeTransferMessageEventToFile(event, ofile); break;
            case UserStatusUpdateEvent:
                deserializeUserStatusUpdateEventToFile(event, ofile); break;
            default:
                qWarning() << "Unknown event type in events list";
                break;
        }
    }

    bool ConversationModel::hasEventsToExport() {
        return events.size() > 0;
    }

    bool ConversationModel::exportConversation()
    {
        const auto proposedDest = QString("%1/%2-%3.log").arg(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)).arg(this->contact()->getNickname()).arg(this->events.constFirst().time.toString(Qt::ISODate));

        auto filePath = QFileDialog::getSaveFileName(nullptr,
                                                        tr("Save File"),
                                                        proposedDest,
                                                        "Log files (*.log);;All files (*)");

        if (filePath.isEmpty())
            return true;

        std::ofstream ofile(filePath.toStdString(), std::ios::out);
        if (!ofile.is_open())
        {
            qWarning() << "Could not open file " << filePath;
            return false;
        }

        fmt::print(ofile, "Conversation with {} ({})\n",
                            this->contact()->getNickname().toStdString(),
                            this->contact()->getContactID().toStdString());

        foreach(auto &event, this->events)
        {
            deserializeEventToFile(event, ofile);
        }

        return true;
    }

    void ConversationModel::tryAcceptFileTransfer(quint32 id)
    {
        auto row = this->indexOfIncomingMessage(id);
        if (row < 0)
        {
            return;
        }

        auto& data = messages[row];

        auto proposedDest = QString("%1/%2").arg(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)).arg(data.fileName);

#ifdef ANDROID
        data.filePath = QFileDialog::getSaveFileName(
            nullptr,
            data.fileName,
            proposedDest);
        auto dest = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/" + Utility::GetRandomString(18);
        data.fileTransferPath = dest;
        if (!dest.isEmpty() && !data.filePath.isEmpty())
        {
#else
        auto dest = QFileDialog::getSaveFileName(
            nullptr,
            tr("Save File"),
            proposedDest);
        if (!dest.isEmpty())
        {
#endif
            auto userIdentity = shims::UserIdentity::userIdentity;
            auto context = userIdentity->getContext();
            const auto sender = this->contactUser->toTegoUserId();
            const auto destination = dest.toUtf8();

            try
            {
                tego_context_respond_file_transfer_request(
                    context,
                    sender.get(),
                    id,
                    tego_file_transfer_response_accept,
                    destination.data(),
                    destination.size(),
                    tego::throw_on_error());
            }
            catch(const std::runtime_error& err)
            {
                qWarning() << err.what();
            }

            data.transferStatus = Accepted;
            emitDataChanged(row);
            this->addEventFromMessage(row);
        }
    }

    void ConversationModel::cancelFileTransfer(tego_file_transfer_id_t id)
    {
        // we get the cancelled callback if we cancel or if the other user cancelled,
        // so ensure we only do work if it was the other preson cancelling
        auto row = this->indexOfMessage(id);
        if (row < 0)
        {
            return;
        }

        MessageData &data = messages[row];
        if (data.transferStatus != Cancelled)
        {
            data.transferStatus = Cancelled;
            emitDataChanged(row);
            this->addEventFromMessage(row);

            auto userIdentity = shims::UserIdentity::userIdentity;
            auto context = userIdentity->getContext();
            const auto userId = this->contactUser->toTegoUserId();

            try
            {
                tego_context_cancel_file_transfer(
                    context,
                    userId.get(),
                    id,
                    tego::throw_on_error());
            }
            catch(const std::runtime_error& err)
            {
                qWarning() << err.what();
            }
        }
    }

    void ConversationModel::rejectFileTransfer(quint32 id)
    {
        auto row = this->indexOfIncomingMessage(id);
        if (row < 0)
        {
            return;
        }

        auto& data = messages[row];

        auto userIdentity = shims::UserIdentity::userIdentity;
        auto context = userIdentity->getContext();
        const auto sender = this->contactUser->toTegoUserId();

        try
        {
            tego_context_respond_file_transfer_request(
                context,
                sender.get(),
                id,
                tego_file_transfer_response_reject,
                nullptr,
                0,
                tego::throw_on_error());
        }
        catch(const std::runtime_error& err)
        {
            qWarning() << err.what();
        }

        data.transferStatus = Rejected;
        emitDataChanged(row);
        this->addEventFromMessage(row);
    }

    void ConversationModel::fileTransferRequestReceived(tego_file_transfer_id_t id, QString fileName, QString fileHash, quint64 fileSize)
    {
        if(isGroupHostMode)
            return;

        MessageData md;
        md.type = TransferMessage;
        md.identifier = id;
        md.time = QDateTime::currentDateTime();
        md.status = Received;

        md.fileName = std::move(fileName);
        md.fileHash = std::move(fileHash);
        md.fileSize = fileSize;
        md.transferDirection = Downloading;
        md.transferStatus = Pending;

        this->beginInsertRows(QModelIndex(), 0, 0);
        this->messages.prepend(std::move(md));
        this->endInsertRows();

        this->setUnreadCount(this->unreadCount + 1);
        this->addEventFromMessage(indexOfIncomingMessage(id));
    }

    void ConversationModel::fileTransferRequestAcknowledged(tego_file_transfer_id_t id, bool accepted)
    {
        if(isGroupHostMode)
            return;

        auto row = this->indexOfOutgoingMessage(id);
        Q_ASSERT(row >= 0);

        MessageData &data = messages[row];
        data.status = accepted ? Delivered : Error;
        emitDataChanged(row);
    }

    void ConversationModel::fileTransferRequestResponded(tego_file_transfer_id_t id, tego_file_transfer_response_t response)
    {
        if(isGroupHostMode)
            return;

        auto row = this->indexOfOutgoingMessage(id);
        Q_ASSERT(row >= 0);

        MessageData &data = messages[row];
        switch(response)
        {
            case tego_file_transfer_response_accept:
                data.transferStatus = Accepted;
                break;
            case tego_file_transfer_response_reject:
                data.transferStatus = Rejected;
                break;
            default:
                return;
        }

        emitDataChanged(row);
        this->addEventFromMessage(row);
    }

    void ConversationModel::fileTransferRequestProgressUpdated(tego_file_transfer_id_t id, quint64 bytesTransferred)
    {
        if(isGroupHostMode)
            return;

        auto row = this->indexOfMessage(id);
        if (row >= 0)
        {
            MessageData &data = messages[row];
            data.bytesTransferred = bytesTransferred;
            data.transferStatus = InProgress;

            if(data.bytesTransferredFewSecAgo == 0 || QDateTime::currentMSecsSinceEpoch() - data.timeBytesTransferredFewSecAgo.toMSecsSinceEpoch() > 3000){
                if(data.bytesTransferredFewSecAgo > 0){
                    const auto newData = data.bytesTransferred - data.bytesTransferredFewSecAgo;
                    data.transferDownloadSpeed = newData / (QDateTime::currentMSecsSinceEpoch() - data.timeBytesTransferredFewSecAgo.toMSecsSinceEpoch()) * 1000;
                }
                data.bytesTransferredFewSecAgo = data.bytesTransferred;
                data.timeBytesTransferredFewSecAgo = QDateTime::currentDateTime();
            }

            emitDataChanged(row);
        }
    }

    void ConversationModel::fileTransferRequestCompleted(
        tego_file_transfer_id_t id,  tego_file_transfer_result_t result)
    {
        if(isGroupHostMode)
            return;

        auto row = this->indexOfMessage(id);
        if (row >= 0)
        {
            auto &data = messages[row];
            switch(result)
            {
                case tego_file_transfer_result_success:
                    data.transferStatus = Finished;
                    #ifdef ANDROID
                    if(!data.fileTransferPath.isEmpty() && !data.filePath.isEmpty()){
                        QFile source(data.fileTransferPath);
                        source.open(QIODevice::ReadOnly);
                        QFile destination(data.filePath);
                        destination.open(QIODevice::ReadWrite);
                        destination.resize(source.size());
                        uchar *data = destination.map(0,destination.size());
                        if(!data){
                            qWarning() << "Error Android: Cannot map destination";
                        }
                        else{
                            QByteArray buffer;
                            int chunksize = 200;
                            int var = 0;
                            do{
                                var = source.read((char *)(data), chunksize);
                                data += var;
                            }while(var > 0);
                        }
                        destination.unmap(data);
                        destination.close();

                        if(!source.remove()){
                            qWarning() << "Error Android: Can't delete temporary file";
                        }
                    }
                    #endif
                    break;
                case tego_file_transfer_result_failure:
                    data.transferStatus = UnknownFailure;
                    break;
                case tego_file_transfer_result_cancelled:
                    data.transferStatus = Cancelled;
                    break;
                case tego_file_transfer_result_rejected:
                    data.transferStatus = Rejected;
                    break;
                case tego_file_transfer_result_bad_hash:
                    data.transferStatus = BadFileHash;
                    break;
                case tego_file_transfer_result_network_error:
                    data.transferStatus = NetworkError;
                    break;
                case tego_file_transfer_result_filesystem_error:
                    data.transferStatus = FileSystemError;
                    break;
                default:
                    data.transferStatus = InvalidTransfer;
                    break;
            }
            emitDataChanged(row);
            this->addEventFromMessage(row);
        }
    }

    void ConversationModel::clear()
    {
        if (messages.isEmpty())
        {
            return;
        }

        beginRemoveRows(QModelIndex(), 0, messages.size()-1);
        messages.clear();
        endRemoveRows();

        resetUnreadCount();
    }

    void ConversationModel::messageReceived(tego_message_id_t messageId, QDateTime timestamp, const QString& text)
    {
        if(isGroupHostMode){
            shims::UserIdentity::userIdentity->contacts.send_to_all(text, contactUser);
            return;
        }
        else{
            MessageData md;
            md.type = TextMessage;
            md.text = text;
            md.time = timestamp;
            md.identifier = messageId;
            md.status = Received;

            this->beginInsertRows(QModelIndex(), 0, 0);
            this->messages.prepend(std::move(md));
            this->endInsertRows();

            this->setUnreadCount(this->unreadCount + 1);
            this->addEventFromMessage(indexOfIncomingMessage(messageId));
        }
    }


    bool ConversationModel::handleMessage(MessageData &md, const QString& text){
        if(isGroupHostMode)
            return false;
        else if(this->contact()->is_a_group){
            if(text.length() > 6 && nlohmann::json::accept(text.toStdString())){
                nlohmann::json j = nlohmann::json::parse(text.toStdString());
                if(j.contains("message") && j["message"].is_string() && j["message"].size() < 200000){
                    md.text = QString::fromStdString(j["message"]);
                }
                else{
                    md.text = "";
                    if(j.contains("users_online") && j.contains("total_group_member") && j.contains("pinned_message") && j["users_online"].is_number_unsigned()
                    && j["total_group_member"].is_number_unsigned() && j["pinned_message"].is_string()){
                        member_in_group = j["total_group_member"];
                        member_of_group_online = j["users_online"];
                        pinned_message = QString::fromStdString(j["pinned_message"]);
                        emit group_member_changed();
                    }
                    return false;
                }
                if(j.contains("name") && j["name"].is_string() && j["name"].size() < 50){
                    md.group_user_nickname = QString::fromStdString(j["name"]);
                }
                else{
                    md.group_user_nickname = "Anonymous";
                    return false;
                }
                if(j.contains("id") && j["id"].is_string() && j["id"].size() < 50){
                    md.group_user_id_hash = QString::fromStdString(j["id"]);
                }
                else{
                    md.group_user_id_hash = "0";
                    return false;
                }
            }
        }
        else{
            md.text = text;
        }
        return true;
    }

    void ConversationModel::messagePartReceived(tego_message_id_t messageId, QDateTime timestamp, const QString& text, int chunks_max, int chunks_rec)
    {
        if(isGroupHostMode){
            if(chunks_max == chunks_rec)
                shims::UserIdentity::userIdentity->contacts.send_to_all(text, contactUser);
            return;
        }

        QMutexLocker locker(&mutex);
        QList<MessageData>::iterator i = nullptr;
        for (i = messages.begin(); i != messages.end(); i++)
            if(i->identifier == messageId){
                auto row = this->indexOfMessage(messageId);
                if (row >= 0)
                {
                    MessageData &data = messages[row];
                    data.prep_text = QString::number(chunks_rec*100/chunks_max) + "% (" + QString::number(float(chunks_max)*63000/1000/1000*chunks_rec/chunks_max) + "/" + QString::number(float(chunks_max)*63000/1000/1000)+"MB)";

                    if(chunks_max == chunks_rec){
                        if(!handleMessage(data, text)){

                        }
                    }
                    emitDataChanged(row);
                    return;
                }
            }

        MessageData md;
        md.type = TextMessage;
        if(chunks_max == chunks_rec){
            if(!handleMessage(md, text)){
                return;
            }
            if(isGroupHostMode)
                return;
        }
        md.prep_text = QString::number(chunks_rec/chunks_max*100);
        md.time = timestamp;
        md.identifier = messageId;
        md.status = Received;

        this->beginInsertRows(QModelIndex(), 0, 0);
        this->messages.prepend(std::move(md));
        this->endInsertRows();

        this->setUnreadCount(this->unreadCount + 1);
        this->addEventFromMessage(indexOfIncomingMessage(messageId));
    }

    void ConversationModel::messageAcknowledged(tego_message_id_t messageId, bool accepted)
    {
        if (messages.size() == 0)
            return;

        auto row = this->indexOfOutgoingMessage(messageId);
        if(row < 0)
            return;

        MessageData &data = messages[row];
        data.status = accepted ? Delivered : Error;
        emitDataChanged(row);
    }

    void ConversationModel::addEventFromMessage(int row)
    {
        EventData ed;

        if (row < 0)
            return;

        auto &md = this->messages[row];
        switch (md.type)
        {
            case TextMessage:
                ed.type = TextMessageEvent;
                ed.messageData.reverseIndex = this->messages.size() - row;
                break;
            case TransferMessage:
                ed.type = TransferMessageEvent;
                ed.transferData.reverseIndex = this->messages.size() - row;
                ed.transferData.status = md.transferStatus;
                ed.transferData.bytesTransferred = md.bytesTransferred;
                break;
            default:
                return;
        }
        ed.time = QDateTime::currentDateTime();

        this->events.append(std::move(ed));
        emit this->conversationEventCountChanged();
    }

    void ConversationModel::setStatus(ContactUser::Status status)
    {
        EventData ed;

        ed.type = UserStatusUpdateEvent;
        ed.userStatusData.status = status;
        ed.userStatusData.target = UserTargetPeer;
        ed.time = QDateTime::currentDateTime();

        this->events.append(std::move(ed));
        emit this->conversationEventCountChanged();
    }

    void ConversationModel::emitDataChanged(int row)
    {
        Q_ASSERT(row >= 0);
        emit dataChanged(index(row, 0), index(row, 0));
    }

    int ConversationModel::indexOfMessage(quint32 identifier) const
    {
        for (int i = 0; i < messages.size(); i++) {
            const auto& currentMessage = messages[i];

            if (currentMessage.identifier == identifier)
                return i;
        }
        return -1;
    }

    int ConversationModel::indexOfOutgoingMessage(quint32 identifier) const
    {
        for (int i = 0; i < messages.size(); i++) {
            const auto& currentMessage = messages[i];

            if (currentMessage.identifier == identifier && (currentMessage.status != Received))
                return i;
        }
        return -1;
    }

    int ConversationModel::indexOfIncomingMessage(quint32 identifier) const
    {
        for (int i = 0; i < messages.size(); i++) {
            const auto& currentMessage = messages[i];

            if (currentMessage.identifier == identifier && (currentMessage.status == Received))
                return i;
        }
        return -1;
    }

    const char* ConversationModel::getMessageStatusString(const MessageStatus status)
    {
        constexpr static const char* statusList[] =
        {
            "None",
            "Received",
            "Queued",
            "Sending",
            "Delivered",
            "Error"
        };

        return statusList[static_cast<size_t>(status)];
    }

    const char* ConversationModel::getTransferStatusString(const TransferStatus status)
    {
        constexpr static const char* statusList[] =
        {
            "Invalid Transfer",
            "Pending",
            "Accepted",
            "Rejected",
            "In Progress",
            "Cancelled",
            "Finished",
            "Unknown Failure",
            "Bad File Hash",
            "Network Error",
            "Filesystem Error"
        };

        return statusList[static_cast<size_t>(status)];
    }
}
