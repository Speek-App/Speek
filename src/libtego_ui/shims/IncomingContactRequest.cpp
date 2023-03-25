#include "IncomingContactRequest.h"
#include "UserIdentity.h"
#include "utils/json.h"

namespace shims
{
    IncomingContactRequest::IncomingContactRequest(const QString& hostname, const QString& message)
    : serviceIdString(hostname.chopped(tego::static_strlen(".onion")))
    , nickname()
    , message(message)
    , isGroup(false)
    , userId()
    {
        auto serviceIdRaw = serviceIdString.toUtf8();

        std::unique_ptr<tego_v3_onion_service_id_t> serviceId;
        tego_v3_onion_service_id_from_string(tego::out(serviceId), serviceIdRaw.data(), serviceIdRaw.size(), tego::throw_on_error());
        tego_user_id_from_v3_onion_service_id(tego::out(userId), serviceId.get(), tego::throw_on_error());

        // save our request to disk
        SettingsObject settings(QString("users.%1").arg(serviceIdString));
        settings.write<QString>("type", "requesting");
        if(message.length() > 6 && nlohmann::json::accept(message.toStdString())){
            nlohmann::json j = nlohmann::json::parse(message.toStdString());
            if(j.contains("isGroup") && j["isGroup"].is_string() && j["isGroup"] == "true"){
                this->isGroup = true;
                settings.write<bool>("isGroup", true);
            }
            if(j.contains("message") && j["message"].is_string()){
                this->message = QString::fromStdString(j["message"]);
            }
        }
    }

    QString IncomingContactRequest::getHostname() const
    {
        return serviceIdString + QString(".onion");
    }

    QString IncomingContactRequest::getContactId() const
    {
        return QString("speek:") + serviceIdString;
    }

    void IncomingContactRequest::setNickname(const QString& nickname)
    {
        logger::println("setNickname : '{}'", nickname);
        this->nickname = nickname;
        emit this->nicknameChanged();
    }

    void IncomingContactRequest::accept()
    {
        auto userIdentity = shims::UserIdentity::userIdentity;
        auto context = userIdentity->getContext();
        auto contactManager = userIdentity->getContacts();

        tego_context_acknowledge_chat_request(context, userId.get(), tego_chat_acknowledge_accept, tego::throw_on_error());

        userIdentity->removeIncomingContactRequest(this);

        shims::ContactInfo info;
        info.nickname = nickname;
        info.icon = "";
        info.is_a_group = isGroup;
        contactManager->addContact(serviceIdString, info);

        SettingsObject settings(QString("users.%1").arg(serviceIdString));
        settings.write<QString>("type", "allowed");
    }

    void IncomingContactRequest::reject()
    {
        auto userIdentity = shims::UserIdentity::userIdentity;
        auto context = userIdentity->getContext();

        tego_context_acknowledge_chat_request(context, userId.get(), tego_chat_acknowledge_block, tego::throw_on_error());

        userIdentity->removeIncomingContactRequest(this);

        SettingsObject settings(QString("users.%1").arg(serviceIdString));
        settings.write<QString>("type", "blocked");
    }

    void IncomingContactRequest::deny()
    {
        auto userIdentity = shims::UserIdentity::userIdentity;
        auto context = userIdentity->getContext();

        tego_context_acknowledge_chat_request(context, userId.get(), tego_chat_acknowledge_block, tego::throw_on_error());

        userIdentity->removeIncomingContactRequest(this);
    }
}
