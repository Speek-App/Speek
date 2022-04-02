#pragma once

namespace shims
{
    class IncomingContactRequest : public QObject
    {
        Q_OBJECT
        Q_DISABLE_COPY(IncomingContactRequest)

        Q_PROPERTY(QString hostname READ getHostname CONSTANT)
        Q_PROPERTY(QString nickname READ getNickname WRITE setNickname NOTIFY nicknameChanged)
        Q_PROPERTY(QString contactId READ getContactId CONSTANT)
        Q_PROPERTY(QString message READ getMessage CONSTANT)
        Q_PROPERTY(bool isGroup READ getIsGroup CONSTANT)
    public:
        IncomingContactRequest(const QString& hostname, const QString& message);

        QString getHostname() const;
        QString getNickname() const { return nickname; }
        void setNickname(const QString&);
        QString getContactId() const;
        QString getMessage() const { return message; }
        bool getIsGroup() const { return isGroup; }

    public slots:
        void accept();
        void reject();
        void deny();
    signals:
        void nicknameChanged();

    private:
        const QString serviceIdString;
        QString nickname;
        QString message;
        bool isGroup;
        std::unique_ptr<tego_user_id_t> userId;
    };
}
