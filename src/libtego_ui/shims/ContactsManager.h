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
            const QString &message);
        shims::ContactUser* addContact(const QString& serviceId, const QString& nickname, const QString& icon = "", bool is_a_group = false);
        const QList<shims::ContactUser*>& contacts() const;
        shims::ContactUser* getShimContactByContactId(const QString& contactId) const;

        void setUnreadCount(shims::ContactUser* user, int unreadCount);
        void setContactStatus(shims::ContactUser* user, int status);
        void send_to_all(const QString& text, shims::ContactUser* exclude);

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
