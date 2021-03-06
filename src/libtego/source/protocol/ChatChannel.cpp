/* Speek - https://speek.network/
 * Copyright (C) 2020, Speek Network (contact@speek.network)
 * Copyright (C) 2014, John Brooks <john.brooks@dereferenced.net>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *    * Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *    * Redistributions in binary form must reproduce the above
 *      copyright notice, this list of conditions and the following disclaimer
 *      in the documentation and/or other materials provided with the
 *      distribution.
 *
 *    * Neither the names of the copyright owners nor the names of its
 *      contributors may be used to endorse or promote products derived from
 *      this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "ChatChannel.h"
#include "Channel_p.h"
#include "Connection.h"
#include "utils/Useful.h"

using namespace Protocol;

ChatChannel::ChatChannel(Direction direction, Connection *connection)
    : Channel(QStringLiteral("im.ricochet.chat"), direction, connection)
{
}

bool ChatChannel::allowInboundChannelRequest(const Data::Control::OpenChannel *request, Data::Control::ChannelResult *result)
{
    Q_UNUSED(request);

    if (connection()->purpose() != Connection::Purpose::KnownContact) {
        qDebug() << "Rejecting request for" << type() << "channel from connection with purpose" << int(connection()->purpose());
        result->set_common_error(Data::Control::ChannelResult::UnauthorizedError);
        return false;
    }

    if (connection()->findChannel<ChatChannel>(Channel::Inbound)) {
        qDebug() << "Rejecting request for" << type() << "channel because one is already open";
        return false;
    }

    return true;
}

bool ChatChannel::allowOutboundChannelRequest(Data::Control::OpenChannel *request)
{
    Q_UNUSED(request);

    if (connection()->findChannel<ChatChannel>(Channel::Outbound)) {
        TEGO_BUG() << "Rejecting outbound request for" << type() << "channel because one is already open on this connection";
        return false;
    }

    if (connection()->purpose() != Connection::Purpose::KnownContact) {
        TEGO_BUG() << "Rejecting outbound request for" << type() << "channel for connection with unexpected purpose" << int(connection()->purpose());
        return false;
    }

    return true;
}

void ChatChannel::receivePacket(const QByteArray &packet)
{
    Data::Chat::Packet message;
    if (!message.ParseFromArray(packet.constData(), packet.size())) {
        closeChannel();
        return;
    }

    if (message.has_chat_message()) {
        handleChatMessage(message.chat_message(), message.chunk_id(), message.chunk_parts());
    } else if (message.has_chat_acknowledge()) {
        handleChatAcknowledge(message.chat_acknowledge());
    } else {
        qWarning() << "Unrecognized message on" << type();
        closeChannel();
    }
}


bool ChatChannel::sendChatMessageWithId(QString text, QDateTime time, MessageId id)
{
    if (direction() != Outbound) {
        TEGO_BUG() << "Chat channels are unidirectional, and this is not an outbound channel";
        return false;
    }

    for (int i = 0; i < text.length(); i += MessageMaxCharacters) {
        if((text.length()+MessageMaxCharacters-1)/MessageMaxCharacters > MessageChunksMax)
            return false;

        QString tt = text.mid(i,MessageMaxCharacters);
        QScopedPointer<Data::Chat::ChatMessage> message(new Data::Chat::ChatMessage);
        message->set_message_id(id);

        // Also converts to UTF-8
        message->set_message_text(tt.toStdString());

        if (!time.isNull())
            message->set_time_delta(qMin(QDateTime::currentDateTime().secsTo(time), qint64(0)));

        Data::Chat::Packet packet;
        packet.set_allocated_chat_message(message.take());
        packet.set_chunk_id(i/MessageMaxCharacters);
        packet.set_chunk_parts((text.length()+MessageMaxCharacters-1)/MessageMaxCharacters);
        if (!Channel::sendMessage(packet))
            return false;
    }

    pendingMessages.insert(id);
    return true;
}

void ChatChannel::handleChatMessage(const Data::Chat::ChatMessage &message, int chunk_id, int chunk_max)
{
    QScopedPointer<Data::Chat::ChatAcknowledge> response(new Data::Chat::ChatAcknowledge);

    // QString::fromStdString decodes the string as UTF-8, replacing all invalid sequences and
    // codepoints with the unicode replacement character.
    QString text = QString::fromStdString(message.message_text());

    if (direction() != Inbound) {
        qWarning() << "Rejected inbound message on an outbound chat channel";
        response->set_accepted(false);
    } else if (text.isEmpty()) {
        qWarning() << "Rejected empty chat message";
        response->set_accepted(false);
    } else if (text.size() > MessageMaxCharacters) {
        qWarning() << "Rejected oversize chat message of" << text.size() << "characters";
        response->set_accepted(false);
    } else if (chunk_max > MessageChunksMax) {
        qWarning() << "Rejected oversize chat message of" << chunk_max << "chunks";
        response->set_accepted(false);
    } else if (chunk_id >= chunk_max) {
        qWarning() << "Chunk ID higher than Chunk Size" << chunk_max << "chunks" << chunk_id << "id";
        response->set_accepted(false);
    } else {
        QDateTime time = QDateTime::currentDateTime();
        if (message.has_time_delta() && message.time_delta() <= 0)
            time = time.addSecs(message.time_delta());

        emit messageReceived(text, time, message.message_id(), chunk_id, chunk_max);
        response->set_accepted(true);
    }

    if (message.has_message_id()) {
        response->set_message_id(message.message_id());
        Data::Chat::Packet packet;
        packet.set_allocated_chat_acknowledge(response.take());
        Channel::sendMessage(packet);
    }
}

void ChatChannel::handleChatAcknowledge(const Data::Chat::ChatAcknowledge &message)
{
    if (direction() != Outbound) {
        qWarning() << "Rejected inbound acknowledgement on an inbound chat channel";
        closeChannel();
        return;
    }

    if (!message.has_message_id()) {
        qDebug() << "Chat acknowledgement doesn't have a message ID we understand";
        closeChannel();
        return;
    }

    MessageId id = message.message_id();
    if (pendingMessages.remove(id)) {
        emit messageAcknowledged(id, message.accepted());
    } else {
        qDebug() << "Received chat acknowledgement for unknown message" << id;
    }
}

