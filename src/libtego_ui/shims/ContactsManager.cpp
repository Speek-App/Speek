#include "ContactsManager.h"
#include "ContactUser.h"
#include "ConversationModel.h"
#include "utils/json.h"

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
            const QString &message)
    {
        logger::println("{{ contactID : {}, nickname : {}, myNickname : {}, message : {} }}",
            contactID, nickname, myNickname, message);

        auto serviceId = contactID.mid(tego::static_strlen("speek:")).toUtf8();

        // check that the service id is valid before anything else
        if (tego_v3_onion_service_id_string_is_valid(serviceId.constData(), serviceId.size(), nullptr) != TEGO_TRUE)
        {
            return nullptr;
        }

        auto shimContact = this->addContact(serviceId, nickname);

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

    shims::ContactUser* ContactsManager::addContact(const QString& serviceId, const QString& nickname, const QString& icon, bool is_a_group)
    {
        // creates a new contact from service id and nickname
        auto shimContact = new shims::ContactUser(serviceId, nickname, icon, is_a_group, isGroupHostMode);
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
        for(auto cu : contactsList)
        {
            if(cu != exclude && cu != NULL)
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
        emit this->contactStatusChanged(user, status);
    }
}
