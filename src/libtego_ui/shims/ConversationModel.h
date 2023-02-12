#pragma once

#include "ContactUser.h"
#include "utils/json.h"

namespace shims
{
    class ContactUser;
    class ConversationModel : public QAbstractListModel
    {
        Q_OBJECT
        Q_ENUMS(MessageStatus)

        Q_PROPERTY(shims::ContactUser* contact READ contact WRITE setContact NOTIFY contactChanged)
        Q_PROPERTY(int unreadCount READ getUnreadCount RESET resetUnreadCount NOTIFY unreadCountChanged)
        Q_PROPERTY(int conversationEventCount READ getConversationEventCount NOTIFY conversationEventCountChanged)
        Q_PROPERTY(unsigned member_in_group READ get_member_in_group NOTIFY group_member_changed)
        Q_PROPERTY(unsigned member_of_group_online READ get_member_of_group_online NOTIFY group_member_changed)
        Q_PROPERTY(QString pinned_message READ get_pinned_message NOTIFY group_member_changed)

    public:
        ConversationModel(QObject *parent = 0, bool group = false);

        enum {
            TimestampRole = Qt::UserRole,
            IsOutgoingRole,
            StatusRole,
            SectionRole,
            TimespanRole,
            TypeRole,
            TransferRole,
            GroupUserRole,
            GroupUserIdRole,
        };

        enum MessageStatus {
            None,
            Received,
            Queued,
            Sending,
            Delivered,
            Error
        };

        enum MessageDataType
        {
            InvalidMessage = -1,
            TextMessage,
            TransferMessage,
        };

        enum TransferStatus
        {
            InvalidTransfer,
            Pending,
            Accepted,
            Rejected,
            InProgress,
            Cancelled,
            Finished,
            UnknownFailure,
            BadFileHash,
            NetworkError,
            FileSystemError,
        };
        Q_ENUM(TransferStatus);

        enum TransferDirection
        {
            InvalidDirection,
            Uploading,
            Downloading,
        };
        Q_ENUM(TransferDirection);

        enum EventType {
            InvalidEvent,
            TextMessageEvent,
            TransferMessageEvent,
            UserStatusUpdateEvent
        };

        enum UserStatusTarget {
            UserTargetNone,
            UserTargetClient,
            UserTargetPeer
        };

        // impl QAbstractListModel
        virtual QHash<int,QByteArray> roleNames() const;
        virtual int rowCount(const QModelIndex &parent = QModelIndex()) const;
        virtual QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

        shims::ContactUser *contact() const;
        void setContact(shims::ContactUser *contact);
        int getUnreadCount() const;
        unsigned get_member_of_group_online() const {
            return member_of_group_online;
        }
        unsigned get_member_in_group() const {
            return member_in_group;
        }
        QString get_pinned_message() const{
            return pinned_message;
        }
        Q_INVOKABLE void resetUnreadCount();

        void sendFile(QString path = "");
        bool hasEventsToExport();
        Q_INVOKABLE int getConversationEventCount() const { return this->events.size(); }
        bool exportConversation();
        // invokable function neeeds to use a Qt type since it is invokable from QML
        static_assert(std::is_same_v<quint32, tego_file_transfer_id_t>);
        #ifndef CONSOLE_ONLY
        Q_INVOKABLE void tryAcceptFileTransfer(quint32 id);
        #else
        Q_INVOKABLE void tryAcceptFileTransfer(quint32 id, QString destination);
        #endif
        Q_INVOKABLE void cancelFileTransfer(quint32 id);
        Q_INVOKABLE void rejectFileTransfer(quint32 id);

        #ifdef CONSOLE_ONLY
        void addEmitConsoleEventFromAllMessages();
        #endif

        void setStatus(ContactUser::Status status);

        void fileTransferRequestReceived(tego_file_transfer_id_t id, QString fileName, QString fileHash, quint64 fileSize);
        void fileTransferRequestAcknowledged(tego_file_transfer_id_t id, bool accepted);
        void fileTransferRequestResponded(tego_file_transfer_id_t id, tego_file_transfer_response_t response);
        void fileTransferRequestProgressUpdated(tego_file_transfer_id_t id, quint64 bytesTransferred);
        void fileTransferRequestCompleted(tego_file_transfer_id_t id, tego_file_transfer_result_t result);

        void messageReceived(tego_message_id_t messageId, QDateTime timestamp, const QString& text);
        void messageAcknowledged(tego_message_id_t messageId, bool accepted);
        void messagePartReceived(tego_message_id_t messageId, QDateTime timestamp, const QString& text, int chunks_max, int chunks_rec);

    public slots:
        void sendMessage(const QString &text);
        void clear();

    signals:
        void contactChanged();
        void group_member_changed();
        void unreadCountChanged(int prevCount, int currentCount);
        void conversationEventCountChanged();
        void newIncomingMessage(nlohmann::json data);
    protected:
        static QMutex mutex;

        void setUnreadCount(int count);

        shims::ContactUser* contactUser = nullptr;

        struct MessageData
        {
            MessageDataType type = InvalidMessage;
            QString text = {};
            QString prep_text = {};
            bool is_fully_received = true;
            QString group_user_nickname = {};
            QString group_user_id_hash = {};
            QDateTime time = {};
            static_assert(std::is_same_v<quint32, tego_file_transfer_id_t>);
            static_assert(std::is_same_v<quint32, tego_message_id_t>);
            quint32 identifier = 0;
            MessageStatus status = None;
            quint8 attemptCount = 0;
            // file transfer data
            QString fileName = {};
            qint64 fileSize = 0;
            QString fileHash = {};
            quint64 bytesTransferred = 0;
            TransferDirection transferDirection = InvalidDirection;;
            TransferStatus transferStatus = InvalidTransfer;
            #ifdef ANDROID
            QString filePath = {};
            QString fileTransferPath = {};
            #endif
        };

        struct EventData
        {
            EventType type = InvalidEvent;
            union {
                struct {
                    size_t reverseIndex = 0;
                } messageData;
                struct {
                    size_t reverseIndex = 0;
                    TransferStatus status = InvalidTransfer;
                    qint64 bytesTransferred = 0; // we care about this for when a transfer is cancelled midway 
                } transferData;
                struct {
                    ContactUser::Status status = ContactUser::Status::Offline;
                    UserStatusTarget target = UserTargetNone; // when the protocol is eventually fixed and users
                                                              // are notified of being blocked, this will be needed
                } userStatusData;
            };
            QDateTime time = {};

            EventData() {}
        };

        QList<MessageData> messages;
        QList<EventData> events;

        bool handleMessage(MessageData &md, const QString& text);

        void addEventFromMessage(int row);
        #ifdef CONSOLE_ONLY
        void addEmitConsoleEventFromMessage(int row);
        #endif

        void deserializeTextMessageEventToFile(const EventData &event, std::ofstream &ofile) const;
        void deserializeTransferMessageEventToFile(const EventData &event, std::ofstream &ofile) const;
        void deserializeUserStatusUpdateEventToFile(const EventData &event, std::ofstream &ofile) const;
        void deserializeEventToFile(const EventData &event, std::ofstream &ofile) const;

        int unreadCount = 0;

        void emitDataChanged(int row);

        int indexOfMessage(quint32 identifier) const;
        int indexOfOutgoingMessage(quint32 identifier) const;
        int indexOfIncomingMessage(quint32 identifier) const;

        bool isGroupHostMode;
        unsigned member_in_group = 0;
        unsigned member_of_group_online = 0;
        QString pinned_message = {};

        static const char* getMessageStatusString(const MessageStatus status);
        static const char* getTransferStatusString(const TransferStatus status);
    };
}
