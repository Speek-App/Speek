#pragma once

#include "utils/Settings.h"

namespace shims
{
    class ContactsManager;
    class ConversationModel;
    class OutgoingContactRequest;
    class ContactUser : public QObject
    {
        Q_OBJECT
        Q_DISABLE_COPY(ContactUser)
        Q_ENUMS(Status)

        Q_PROPERTY(QString nickname READ getNickname WRITE setNickname NOTIFY nicknameChanged)
        Q_PROPERTY(QString icon READ getIcon WRITE setIcon NOTIFY iconChanged)
        Q_PROPERTY(QString contactID READ getContactID CONSTANT)
        Q_PROPERTY(Status status READ getStatus NOTIFY statusChanged)
        Q_PROPERTY(shims::OutgoingContactRequest* contactRequest READ contactRequest NOTIFY statusChanged)
        Q_PROPERTY(shims::ConversationModel* conversation READ conversation CONSTANT)
        Q_PROPERTY(bool is_a_group READ getIsAGroup CONSTANT)
    public:
        enum Status
        {
            Online,
            Offline,
            RequestPending,
            RequestRejected,
            Outdated
        };

        ContactUser(const QString& serviceId, const QString& nickname, const QString& icon = "", bool is_a_group = false, bool group = false);

        QString getNickname() const;
        QString getIcon() const;
        QString getContactID() const;
        Status getStatus() const;
        bool getIsAGroup() const {
            return is_a_group;
        }
        void setStatus(Status status);
        QString getSection() const;
        int getSectionNum() const;
        shims::OutgoingContactRequest *contactRequest();
        shims::ConversationModel *conversation();

        Q_INVOKABLE void deleteContact();
        Q_INVOKABLE void sendFile(QString path = "");
        Q_INVOKABLE bool exportConversation();

        std::unique_ptr<tego_user_id_t> toTegoUserId() const;

    public slots:
        void setNickname(const QString &nickname);
        void setIcon(const QString &nickname);

    signals:
        void nicknameChanged();
        void iconChanged();
        void statusChanged();
        void contactDeleted(shims::ContactUser *user);

    protected:
        shims::ConversationModel* conversationModel;
        shims::OutgoingContactRequest* outgoingContactRequest;

        Status status;
        QString serviceId;
        QString nickname;
        QString icon;
        bool is_a_group;
        void setIsAGroup(bool is_a_group);

        SettingsObject settings;

        friend class shims::ContactsManager;
        friend class shims::ConversationModel;
    };
}
