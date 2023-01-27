#pragma once

#include "ContactUser.h"

namespace shims
{
    class ContactsManager : public QObject
    {
        Q_OBJECT
        Q_DISABLE_COPY(ContactsManager)
    public:
        ContactsManager(tego_context_t* context, bool group = false);

        Q_INVOKABLE shims::ContactUser* createContactRequest(
            const QString &contactID,
            const QString &nickname,
            const QString &myNickname,
            const QString &message,
            const QString &icon = "");
        shims::ContactUser* addContact(const QString& serviceId, const QString& nickname, const QString& icon = "", bool is_a_group = false, bool save_messages = false, bool send_undelivered_messages_after_resume = false, bool auto_download_files = false, QString auto_download_dir = "", unsigned last_online = 0);
        const QList<shims::ContactUser*>& contacts() const;
        shims::ContactUser* getShimContactByContactId(const QString& contactId) const;

        void setUnreadCount(shims::ContactUser* user, int unreadCount);
        void setContactStatus(shims::ContactUser* user, int status);
        void send_to_all(const QString& text, shims::ContactUser* exclude);
        int count_contacts_online(){
            int c = 0;
            for(auto cu : contactsList)
                if(cu->getStatus() == ContactUser::Online)
                    c++;
            return c;
        }
        int count_contacts(){
            int c = 0;
            for(auto cu : contactsList)
                if(cu->getStatus() == ContactUser::Online || cu->getStatus() == ContactUser::Offline)
                    c++;
            return c;
        }
        Q_INVOKABLE int count_contacts_with_unread_message();

    signals:
        void contactAdded(shims::ContactUser *user);
        void unreadCountChanged(shims::ContactUser *user, int unreadCount);
        void contactStatusChanged(shims::ContactUser* user, int status);
    protected:
        tego_context_t* context;
        mutable QList<shims::ContactUser*> contactsList;
        bool isGroupHostMode;
    };
}
