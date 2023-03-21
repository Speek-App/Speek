#include "ContactsManager.h"
#include "ContactUser.h"
#include "ConversationModel.h"
#include "utils/json.h"
#include "utility.h"

namespace shims
{
    ContactsManager::ContactsManager(tego_context_t* context, bool group)
    : context(context)
    , contactsList({})
    , isGroupHostMode(group)
    { }

    shims::ContactUser* ContactsManager::createContactRequest(
            const QString &contactID,
            const QString &nickname,
            const QString &myNickname,
            const QString &message,
            const QString &icon)
    {
        logger::println("{{ contactID : {}, nickname : {}, myNickname : {}, message : {} }}",
            contactID, nickname, myNickname, message);

        auto serviceId = contactID.mid(tego::static_strlen("speek:")).toUtf8();

        // check that the service id is valid before anything else
        if (tego_v3_onion_service_id_string_is_valid(serviceId.constData(), serviceId.size(), nullptr) != TEGO_TRUE)
        {
            return nullptr;
        }

        shims::ContactInfo info;
        info.nickname = nickname;
        info.icon = icon;
        auto shimContact = this->addContact(serviceId, info);

        auto userId = shimContact->toTegoUserId();

        QString msg_send = message;

        msg_send.replace("+", "");
        msg_send += "+" + myNickname;

        if(this->isGroupHostMode){
            nlohmann::json j;
            j["isGroup"] = "true";
            j["message"] = msg_send.toStdString();
            msg_send = QString::fromStdString(j.dump());
        }

        auto rawMessage = msg_send.toUtf8();

        tego_context_send_chat_request(this->context, userId.get(), rawMessage.data(), rawMessage.size(), tego::throw_on_error());

        shimContact->setStatus(shims::ContactUser::RequestPending);

        return shimContact;
    }

    shims::ContactUser* ContactsManager::addContact(const QString& serviceId, const shims::ContactInfo& info)
    {
        // creates a new contact from service id and nickname
        auto shimContact = new shims::ContactUser(serviceId, info);
        contactsList.push_back(shimContact);

        // remove our reference and ready for deleting when contactDeleted signal is fireds
        connect(shimContact, &shims::ContactUser::contactDeleted, [self=this](shims::ContactUser* user) -> void
        {
            QTime dieTime= QTime::currentTime().addSecs(1);
            while (QTime::currentTime() < dieTime)
                QCoreApplication::processEvents(QEventLoop::AllEvents, 100);

            // find the given user in our internal list and remove, mark for deletion
            auto& contactsList = self->contactsList;
            if(contactsList.contains(user)){
                auto it = std::find(contactsList.begin(), contactsList.end(), user);
                contactsList.erase(it);
                user->deleteLater();
            }
        });

        emit this->contactAdded(shimContact);
        return shimContact;
    }

    void ContactsManager::send_to_all(const QString& text, shims::ContactUser* exclude){
        if(text.length() < 251900 && text.length() > 6 && nlohmann::json::accept(text.toStdString())){
            nlohmann::json j = nlohmann::json::parse(text.toStdString());
            if(!(j.contains("message") && j["message"].is_string() && j["message"].size() < 251900))
                return;
            if(!(j.contains("name") && j["name"].is_string()))
                return;
            if(!(j.contains("id") && j["id"].is_string() && j["id"] == Utility::toHash(exclude->getContactID()).toStdString()))
                return;
            if(j.contains("users_online"))
                return;
            if(j.contains("total_group_member"))
                return;
        }
        else{
            return;
        }

        for(auto cu : contactsList)
        {
            if(cu != exclude && cu != NULL && cu->getStatus() == ContactUser::Status::Online)
                cu->conversation()->sendMessage(text);
        }
    }

    shims::ContactUser* ContactsManager::getShimContactByContactId(const QString& contactId) const
    {
        logger::trace();
        for(auto cu : contactsList)
        {
            logger::println("cu : {}", (void*)cu);
            if (cu->getContactID() == contactId)
            {
                logger::trace();
                return cu;
            }
        }
        return nullptr;
    }

    const QList<shims::ContactUser*>& ContactsManager::contacts() const
    {
        return contactsList;
    }

    void ContactsManager::setUnreadCount(shims::ContactUser* user, int unreadCount)
    {
        emit this->unreadCountChanged(user, unreadCount);
    }

    void ContactsManager::setContactStatus(shims::ContactUser* user, int status)
    {
        if(isGroupHostMode){
            if(status == shims::ContactUser::Online || status == shims::ContactUser::Offline){
                nlohmann::json j;
                j["users_online"] = count_contacts_online();
                j["total_group_member"] = count_contacts();

                SettingsObject settings;
                j["pinned_message"] = settings.read("ui.groupPinnedMessage").toString().toStdString();

                QString msg_send = QString::fromStdString(j.dump());

                for(auto cu : contactsList)
                {
                    if(cu != NULL && cu->getStatus() == ContactUser::Status::Online)
                        cu->conversation()->sendMessage(msg_send);
                }
            }
        }
        emit this->contactStatusChanged(user, status);
    }

    int ContactsManager::count_contacts_with_unread_message(){
        int c = 0;
        for(auto cu : contactsList)
            if(cu->conversation()->getUnreadCount() > 0)
                c++;
        return c;
    }
}
