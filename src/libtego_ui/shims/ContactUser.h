#pragma once

#include "utils/Settings.h"

namespace shims
{
    struct ContactInfo {
        QString nickname;
        QString icon;
        bool group = false;
        bool is_a_group = false;
        bool save_messages = false;
        bool send_undelivered_messages_after_resume = false;
        bool auto_download_files = false;
        QString auto_download_dir = "";
        unsigned last_online = 0;
    };

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
        Q_PROPERTY(bool save_messages READ getSaveMessages WRITE setSaveMessages NOTIFY saveMessagesChanged)
        Q_PROPERTY(bool send_undelivered_messages_after_resume READ getSendUndeliveredMessagesAfterResume WRITE setSendUndeliveredMessagesAfterResume NOTIFY sendUndeliveredMessagesAfterResumeChanged)
        Q_PROPERTY(bool auto_download_files READ getAutoDownloadFiles WRITE setAutoDownloadFiles NOTIFY autoDownloadFilesChanged)
        Q_PROPERTY(QString auto_download_dir READ getAutoDownloadDir WRITE setAutoDownloadDir NOTIFY autoDownloadDirChanged)
        Q_PROPERTY(QString contactID READ getContactID CONSTANT)
        Q_PROPERTY(Status status READ getStatus NOTIFY statusChanged)
        Q_PROPERTY(shims::OutgoingContactRequest* contactRequest READ contactRequest NOTIFY statusChanged)
        Q_PROPERTY(shims::ConversationModel* conversation READ conversation CONSTANT)
        Q_PROPERTY(bool is_a_group READ getIsAGroup CONSTANT)
        Q_PROPERTY(QString time_since_last_online READ getTimeSinceLastOnline NOTIFY lastOnlineChanged)
    public:
        enum Status
        {
            Online,
            Offline,
            RequestPending,
            RequestRejected,
            Outdated
        };

        ContactUser(const QString& serviceId, const ContactInfo& info);
        ~ContactUser();
        QString getNickname() const;
        QString getIcon() const;
        QString getContactID() const;
        Status getStatus() const;
        bool getIsAGroup() const {
            return is_a_group;
        }
        bool getSendUndeliveredMessagesAfterResume() const {
            return send_undelivered_messages_after_resume;
        }
        bool getSaveMessages() const {
            return save_messages;
        }
        bool getAutoDownloadFiles() const {
            return auto_download_files;
        }
        QString getAutoDownloadDir() const {
            return auto_download_dir;
        }
        unsigned getLastOnline() const {
            return last_online.toSecsSinceEpoch();
        }
        QString getTimeSinceLastOnline() const;
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
        void setIcon(const QString &icon);
        void setSendUndeliveredMessagesAfterResume(const bool &val);
        void setSaveMessages(const bool &val);
        void setAutoDownloadFiles(const bool &val);
        void setAutoDownloadDir(const QString &val);

    signals:
        void nicknameChanged();
        void iconChanged();
        void sendUndeliveredMessagesAfterResumeChanged();
        void saveMessagesChanged();
        void autoDownloadFilesChanged();
        void autoDownloadDirChanged();
        void statusChanged();
        void lastOnlineChanged();
        void contactDeleted(shims::ContactUser *user);

    protected:
        shims::ConversationModel* conversationModel;
        shims::OutgoingContactRequest* outgoingContactRequest;

        Status status;
        QString serviceId;
        QString nickname;
        QString icon;
        bool is_a_group;
        bool save_messages;
        bool send_undelivered_messages_after_resume;
        bool auto_download_files;
        QString auto_download_dir;
        QDateTime last_online;
        void setIsAGroup(bool is_a_group);

        SettingsObject settings;

        friend class shims::ContactsManager;
        friend class shims::ConversationModel;
    };
}
