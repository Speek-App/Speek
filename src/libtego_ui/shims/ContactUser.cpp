#include "UserIdentity.h"
#include "ContactUser.h"
#include "ConversationModel.h"
#include "OutgoingContactRequest.h"

// TODO: wire up the slots in here, figure out how to properly wire up unread count, status change
// populating the contacts manager on boot, keeping libtego's internal contacts synced with frontend's
// put all of the SettingsObject stuff into one settings manager

namespace shims
{
    ContactUser::ContactUser(const QString& serviceId, const QString& nickname, const QString& icon, bool is_a_group, bool group, bool save_messages, bool send_undelivered_messages_after_resume, bool auto_download_files, QString auto_download_dir, unsigned last_online)
    : conversationModel(new shims::ConversationModel(this, group))
    , outgoingContactRequest(new shims::OutgoingContactRequest())
    , status(ContactUser::Offline)
    , serviceId(serviceId)
    , nickname()
    , icon()
    , settings(QString("users.%1").arg(serviceId))
    {
        Q_ASSERT(serviceId.size() == TEGO_V3_ONION_SERVICE_ID_LENGTH);
        conversationModel->setContact(this);

        this->setNickname(nickname);
        this->setIcon(icon);
        this->setIsAGroup(is_a_group);
        this->setSaveMessages(save_messages);
        this->setSendUndeliveredMessagesAfterResume(send_undelivered_messages_after_resume);
        this->setAutoDownloadFiles(auto_download_files);
        this->setAutoDownloadDir(auto_download_dir);
        this->last_online = QDateTime::fromSecsSinceEpoch(last_online);
        emit this->lastOnlineChanged();
    }

    ContactUser::~ContactUser(){
        conversation()->saveConversationTimer.stop();
        if(this->status == ContactUser::Online){
            settings.write("last_online", QDateTime::currentDateTime().toSecsSinceEpoch());
        }
        conversation()->saveConversationHistory();
    }

    QString ContactUser::getNickname() const
    {
        return nickname;
    }

    QString ContactUser::getIcon() const
    {
        return icon;
    }

    QString ContactUser::getContactID() const
    {
        return QString("speek:") + serviceId;
    }

    ContactUser::Status ContactUser::getStatus() const
    {
        return status;
    }

    QString ContactUser::getTimeSinceLastOnline() const {
        if(last_online.toSecsSinceEpoch() == 0)
            return "";

        qint64 seconds = last_online.secsTo(QDateTime::currentDateTime());

        if(seconds < 0){
            return "";
        }

        const qint64 DAY = 86400;
        qint64 days = seconds / DAY;
        QTime t = QTime(0,0).addSecs(seconds % DAY);
        if(days > 0){
            if(days > 1)
                return QString(tr("%1 days ago")).arg(days);
            else
                return QString(tr("1 day ago"));
        }
        else if(t.hour() > 0){
            if(t.hour() > 1)
                return QString(tr("%1 hours ago")).arg(t.hour());
            else
                return QString(tr("1 hour ago"));
        }
        else if(t.minute() > 0){
            if(t.minute() > 1)
                return QString(tr("%1 minutes ago")).arg(t.minute());
            else
                return QString(tr("1 minute ago"));
        }
        else{
            return QString(tr("just now"));
        }
    }

    QString ContactUser::getSection() const {
        switch (getStatus()) {
            case Status::Online: return is_a_group ? "group-online" : "online";
            case Status::Offline: return is_a_group ? "group-offline" : "offline";
            case Status::RequestPending: return is_a_group ? "group-request" : "request";
            case Status::RequestRejected: return "rejected";
            case Status::Outdated: return "outdated";
        }
    }

    int ContactUser::getSectionNum() const {
        switch (getStatus()) {
            case Status::Online: return is_a_group ? 1 : 0;
            case Status::Offline: return is_a_group ? 3 : 2;
            case Status::RequestPending: return is_a_group ? 5 : 4;
            case Status::RequestRejected: return 6;
            case Status::Outdated: return 7;
        }
    }

    void ContactUser::setStatus(ContactUser::Status status)
    {
        if (this->status != status)
        {
            this->status = status;
            switch(this->status)
            {
                case ContactUser::Online:
                case ContactUser::Offline:
                    settings.write("type", "allowed");
                    last_online = QDateTime::currentDateTime();
                    settings.write("last_online", last_online.toSecsSinceEpoch());
                    emit lastOnlineChanged();
                    break;
                case ContactUser::RequestPending:
                    settings.write("type", "pending");
                    break;
                case ContactUser::RequestRejected:
                    settings.write("type", "rejected");
                    break;
                default:
                    break;
            }
            emit this->statusChanged();
        }
    }

    shims::OutgoingContactRequest* ContactUser::contactRequest()
    {
        return outgoingContactRequest;
    }

    shims::ConversationModel* ContactUser::conversation()
    {
        return conversationModel;
    }

    void ContactUser::setNickname(const QString& nickname)
    {
        if (this->nickname != nickname)
        {
            this->nickname = nickname;
            settings.write("nickname", nickname);
            emit this->nicknameChanged();
        }
    }

    void ContactUser::setIcon(const QString& icon)
    {
        if (this->icon != icon)
        {
            this->icon = icon;
            settings.write("icon", icon);
            emit this->iconChanged();
        }
    }

    void ContactUser::setSendUndeliveredMessagesAfterResume(const bool &val){
        if (this->send_undelivered_messages_after_resume != val)
        {
            this->send_undelivered_messages_after_resume = val;
            settings.write("send_undelivered_messages_after_resume", val);
            emit this->sendUndeliveredMessagesAfterResumeChanged();
        }
    }

    void ContactUser::setSaveMessages(const bool &val){
        if (this->save_messages != val)
        {
            this->save_messages = val;
            settings.write("save_messages", val);
            if(!val){
                conversation()->deleteConversationHistory();
            }
            emit this->saveMessagesChanged();
        }
    }

    void ContactUser::setAutoDownloadFiles(const bool &val){
        if (this->auto_download_files != val)
        {
            this->auto_download_files = val;
            settings.write("auto_download_files", val);
            emit this->autoDownloadFilesChanged();
        }
    }

    void ContactUser::setAutoDownloadDir(const QString &val){
        if (this->auto_download_dir != val)
        {
            this->auto_download_dir = val;
            settings.write("auto_download_dir", val);
            emit this->autoDownloadDirChanged();
        }
    }

    void ContactUser::setIsAGroup(bool is_a_group)
    {
        this->is_a_group = is_a_group;
        settings.write("isGroup", is_a_group);
    }

    void ContactUser::deleteContact()
    {
        this->setStatus(Offline);
        auto userIdentity = shims::UserIdentity::userIdentity;

        auto context = userIdentity->getContext();
        auto userId = this->toTegoUserId();

        tego_context_forget_user(context, userId.get(), tego::throw_on_error());

        settings.undefine();
        emit this->contactDeleted(this);
    }

    void ContactUser::sendFile(QString path)
    {
        this->conversationModel->sendFile(path);
    }

    bool ContactUser::exportConversation()
    {
        return this->conversationModel->exportConversation();
    }

    std::unique_ptr<tego_user_id_t> ContactUser::toTegoUserId() const
    {
        logger::println("serviceId : {}", this->serviceId);

        auto serviceIdRaw = this->serviceId.toUtf8();

        // ensure valid service id
        std::unique_ptr<tego_v3_onion_service_id_t> serviceId;
        tego_v3_onion_service_id_from_string(tego::out(serviceId), serviceIdRaw.data(), serviceIdRaw.size(), tego::throw_on_error());

        logger::trace();

        // create user id object from service id
        std::unique_ptr<tego_user_id_t> userId;
        tego_user_id_from_v3_onion_service_id(tego::out(userId), serviceId.get(), tego::throw_on_error());

        return userId;
    }
}
