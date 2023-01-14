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

#include "utils/PendingOperation.h"
#include "TorControl.h"
#include "TorControlSocket.h"
#include "HiddenService.h"
#include "AuthenticateCommand.h"
#include "SetConfCommand.h"
#include "GetConfCommand.h"
#include "AddOnionCommand.h"
#include "utils/StringUtil.h"

#include "error.hpp"
#include "globals.hpp"
#include "signals.hpp"
using tego::g_globals;

Tor::TorControl *torControl = 0;

using namespace Tor;

namespace Tor {

class TorControlPrivate : public QObject
{
    Q_OBJECT

public:
    TorControl *q;

    TorControlSocket *socket;
    QHostAddress torAddress;
    QString errorMessage;
    QString torVersion;
    QByteArray authPassword;
    QHostAddress socksAddress;
    HiddenService* service = nullptr;
    quint16 controlPort, socksPort;
    TorControl::Status status;
    TorControl::TorStatus torStatus;
    QVariantMap bootstrapStatus;
    bool hasOwnership;

    TorControlPrivate(TorControl *parent);

    void setStatus(TorControl::Status status);
    void setTorStatus(TorControl::TorStatus status);

    void getTorInfo();
    void publishService();

public slots:
    void socketConnected();
    void socketDisconnected();
    void socketError();

    void authenticateReply();
    void getTorInfoReply();
    void setError(const QString &message);

    void statusEvent(int code, const QByteArray &data);
    void updateBootstrap(const QList<QByteArray> &data);
};

}

TorControl::TorControl(QObject *parent)
    : QObject(parent), d(new TorControlPrivate(this))
{
}

TorControlPrivate::TorControlPrivate(TorControl *parent)
    : QObject(parent), q(parent), controlPort(0), socksPort(0),
      status(TorControl::NotConnected), torStatus(TorControl::TorUnknown),
      hasOwnership(false)
{
    socket = new TorControlSocket(this);
    QObject::connect(socket, SIGNAL(connected()), this, SLOT(socketConnected()));
    QObject::connect(socket, SIGNAL(disconnected()), this, SLOT(socketDisconnected()));
    QObject::connect(socket, SIGNAL(error(QAbstractSocket::SocketError)), this, SLOT(socketError()));
    QObject::connect(socket, SIGNAL(error(QString)), this, SLOT(setError(QString)));
}

QNetworkProxy TorControl::connectionProxy()
{
    return QNetworkProxy(QNetworkProxy::Socks5Proxy, d->socksAddress.toString(), d->socksPort);
}

void TorControlPrivate::setStatus(TorControl::Status n)
{
    if (n == status)
        return;

    TorControl::Status old = status;
    status = n;

    if (old == TorControl::Error)
        errorMessage.clear();

    emit q->statusChanged(status, old);

    g_globals.context->callback_registry_.emit_tor_control_status_changed(
        static_cast<tego_tor_control_status_t>(status));

    if (status == TorControl::Connected && old < TorControl::Connected)
        emit q->connected();
    else if (status < TorControl::Connected && old >= TorControl::Connected)
        emit q->disconnected();
}

void TorControlPrivate::setTorStatus(TorControl::TorStatus n)
{
    if (n == torStatus)
    {
        return;
    }

    TorControl::TorStatus old = torStatus;
    torStatus = n;
    emit q->torStatusChanged(torStatus, old);
    emit q->connectivityChanged();

    switch(torStatus)
    {
        case TorControl::TorUnknown:
            g_globals.context->callback_registry_.emit_tor_network_status_changed(tego_tor_network_status_unknown);
            break;
        case TorControl::TorOffline:
            g_globals.context->callback_registry_.emit_tor_network_status_changed(tego_tor_network_status_offline);
            break;
        case TorControl::TorReady:
            g_globals.context->callback_registry_.emit_tor_network_status_changed(tego_tor_network_status_ready);
            break;
    }


    if (torStatus == TorControl::TorReady)
{
        if (socksAddress.isNull())
        {
            // Request info again to read the SOCKS port
            getTorInfo();
        }
        else
        {
            g_globals.context->set_host_user_state(tego_host_user_state_online);
        }
    }
}

void TorControlPrivate::setError(const QString &message)
{
    errorMessage = message;
    setStatus(TorControl::Error);

    qWarning() << "torctrl: Error:" << errorMessage;

    auto tegoError = std::make_unique<tego_error>();
    tegoError->message = message.toStdString();
    g_globals.context->callback_registry_.emit_tor_error_occurred(
        tego_tor_error_origin_control,
        tegoError.release());

    socket->abort();

    QTimer::singleShot(15000, q, SLOT(reconnect()));
}

TorControl::Status TorControl::status() const
{
    return d->status;
}

TorControl::TorStatus TorControl::torStatus() const
{
    return d->torStatus;
}

QString TorControl::torVersion() const
{
    return d->torVersion;
}

QString TorControl::errorMessage() const
{
    return d->errorMessage;
}

bool TorControl::hasConnectivity() const
{
    return torStatus() == TorReady && !d->socksAddress.isNull();
}

QHostAddress TorControl::socksAddress() const
{
    return d->socksAddress;
}

quint16 TorControl::socksPort() const
{
    return d->socksPort;
}

HiddenService const* TorControl::getHiddenService() const
{
    return d->service;
}

QVariantMap TorControl::bootstrapStatus() const
{
    return d->bootstrapStatus;
}

void TorControl::setAuthPassword(const QByteArray &password)
{
    d->authPassword = password;
}

void TorControl::connect(const QHostAddress &address, quint16 port)
{
    if (status() > Connecting)
    {
        qDebug() << "Ignoring TorControl::connect due to existing connection";
        return;
    }

    d->torAddress = address;
    d->controlPort = port;
    d->setTorStatus(TorUnknown);

    bool b = d->socket->blockSignals(true);
    d->socket->abort();
    d->socket->blockSignals(b);

    d->setStatus(Connecting);
    d->socket->connectToHost(address, port);
}

void TorControl::reconnect()
{
    Q_ASSERT(!d->torAddress.isNull() && d->controlPort);
    if (d->torAddress.isNull() || !d->controlPort || status() >= Connecting)
        return;

    d->setStatus(Connecting);
    d->socket->connectToHost(d->torAddress, d->controlPort);
}

void TorControlPrivate::authenticateReply()
{
    AuthenticateCommand *command = qobject_cast<AuthenticateCommand*>(sender());
    Q_ASSERT(command);
    Q_ASSERT(status == TorControl::Authenticating);
    if (!command)
        return;

    if (!command->isSuccessful()) {
        setError(command->errorMessage());
        return;
    }

    qDebug() << "torctrl: Authentication successful";
    setStatus(TorControl::Connected);

    setTorStatus(TorControl::TorUnknown);

    TorControlCommand *clientEvents = new TorControlCommand;
    connect(clientEvents, &TorControlCommand::replyLine, this, &TorControlPrivate::statusEvent);
    socket->registerEvent("STATUS_CLIENT", clientEvents);

    getTorInfo();
}

void TorControlPrivate::socketConnected()
{
    Q_ASSERT(status == TorControl::Connecting);

    qDebug() << "torctrl: Connected socket; querying information";
    setStatus(TorControl::Authenticating);

    AuthenticateCommand *authenticate = new AuthenticateCommand;
    connect(authenticate, &TorControlCommand::finished, this, &TorControlPrivate::authenticateReply);
    socket->sendCommand(authenticate, authenticate->build(authPassword));
}

void TorControlPrivate::socketDisconnected()
{
    /* Clear some internal state */
    torVersion.clear();
    socksAddress.clear();
    socksPort = 0;
    setTorStatus(TorControl::TorUnknown);

    /* This emits the disconnected() signal as well */
    setStatus(TorControl::NotConnected);
}

void TorControlPrivate::socketError()
{
    setError(QStringLiteral("Connection failed: %1").arg(socket->errorString()));
}

void TorControlPrivate::getTorInfo()
{
    Q_ASSERT(q->isConnected());

    GetConfCommand *command = new GetConfCommand(GetConfCommand::GetInfo);
    connect(command, &TorControlCommand::finished, this, &TorControlPrivate::getTorInfoReply);

    QList<QByteArray> keys;
    keys << QByteArray("status/circuit-established");
    keys << QByteArray("status/bootstrap-phase");
    keys << QByteArray("net/listeners/socks");
    keys << QByteArray("version");

    socket->sendCommand(command, command->build(keys));
}

void TorControlPrivate::getTorInfoReply()
{
    GetConfCommand *command = qobject_cast<GetConfCommand*>(sender());
    if (!command || !q->isConnected())
        return;

    QList<QByteArray> listenAddresses = splitQuotedStrings(command->get(QByteArray("net/listeners/socks")).toString().toLatin1(), ' ');
    for (QList<QByteArray>::Iterator it = listenAddresses.begin(); it != listenAddresses.end(); ++it) {
        QByteArray value = unquotedString(*it);
        int sepp = value.indexOf(':');
        QHostAddress address(QString::fromLatin1(value.mid(0, sepp)));
        quint16 port = static_cast<quint16>(value.mid(sepp+1).toUInt());

        /* Use the first address that matches the one used for this control connection. If none do,
         * just use the first address and rely on the user to reconfigure if necessary (not a problem;
         * their setup is already very customized) */
        if (socksAddress.isNull() || address == socket->peerAddress()) {
            socksAddress = address;
            socksPort = port;
            if (address == socket->peerAddress())
                break;
        }
    }

    /* It is not immediately an error to have no SOCKS address; when DisableNetwork is set there won't be a
     * listener yet. To handle that situation, we'll try to read the socks address again when TorReady state
     * is reached. */
    if (!socksAddress.isNull()) {
        qDebug().nospace() << "torctrl: SOCKS address is " << socksAddress.toString() << ":" << socksPort;
        emit q->connectivityChanged();
    }

    if (command->get(QByteArray("status/circuit-established")).toInt() == 1) {
        qDebug() << "torctrl: Tor indicates that circuits have been established; state is TorReady";
        g_globals.context->set_host_user_state(tego_host_user_state_online);
        setTorStatus(TorControl::TorReady);
    } else {
        setTorStatus(TorControl::TorOffline);
    }

    QByteArray bootstrap = command->get(QByteArray("status/bootstrap-phase")).toString().toLatin1();
    if (!bootstrap.isEmpty())
        updateBootstrap(splitQuotedStrings(bootstrap, ' '));

    QString version = command->get(QByteArray("version")).toString();
    qDebug() << "version: " << version;
    torVersion = version;
}

void TorControl::setHiddenService(HiddenService *service)
{
    Q_ASSERT(d->service == nullptr);
    d->service = service;
}

void TorControl::publishHiddenService()
{
    d->publishService();
}

void TorControlPrivate::publishService()
{
    Q_ASSERT(q->isConnected());
    Q_ASSERT(this->service != nullptr);

    // v3 works in all supported tor versions:
    // https://trac.torproject.org/projects/tor/wiki/org/teams/NetworkTeam/CoreTorReleases
    Q_ASSERT(q->torVersionAsNewAs(QStringLiteral("0.3.5")));

    if (service->hostname().isEmpty())
        qDebug() << "torctrl: Creating a new hidden service";
    else
        qDebug() << "torctrl: Publishing hidden service" << service->hostname();
    AddOnionCommand *onionCommand = new AddOnionCommand(service);
    QObject::connect(onionCommand, &AddOnionCommand::succeeded, service, &HiddenService::servicePublished);
    socket->sendCommand(onionCommand, onionCommand->build());
}

void TorControl::shutdown()
{
    if (!hasOwnership()) {
        qWarning() << "torctrl: Ignoring shutdown command for a tor instance I don't own";
        return;
    }

    d->socket->sendCommand("SIGNAL SHUTDOWN\r\n");
}

void TorControl::shutdownSync()
{
    if (!hasOwnership()) {
        qWarning() << "torctrl: Ignoring shutdown command for a tor instance I don't own";
        return;
    }

    shutdown();
    while (d->socket->bytesToWrite())
    {
        if (!d->socket->waitForBytesWritten(5000))
            return;
    }
}

void TorControlPrivate::statusEvent(int code, const QByteArray &data)
{
    Q_UNUSED(code);

    QList<QByteArray> tokens = splitQuotedStrings(data.trimmed(), ' ');
    if (tokens.size() < 3)
        return;

    qDebug() << "torctrl: status event:" << data.trimmed();

    if (tokens[2] == "CIRCUIT_ESTABLISHED") {
        setTorStatus(TorControl::TorReady);
    } else if (tokens[2] == "CIRCUIT_NOT_ESTABLISHED") {
        setTorStatus(TorControl::TorOffline);
    } else if (tokens[2] == "BOOTSTRAP") {
        tokens.takeFirst();
        updateBootstrap(tokens);
    }
}

void TorControlPrivate::updateBootstrap(const QList<QByteArray> &data)
{
    bootstrapStatus.clear();
    // WARN or NOTICE
    bootstrapStatus[QStringLiteral("severity")] = data.value(0);
    for (int i = 1; i < data.size(); i++) {
        int equals = data[i].indexOf('=');
        QString key = QString::fromLatin1(data[i].mid(0, equals));
        QString value;
        if (equals >= 0)
            value = QString::fromLatin1(unquotedString(data[i].mid(equals + 1)));
        bootstrapStatus[key.toLower()] = value;
    }

    // these functions just access 'bootstrapStatus' and parse out the relevant keys
    // a bit roundabout but better than duplicating the tag parsing logic
    auto progress = g_globals.context->get_tor_bootstrap_progress();
    auto tag = g_globals.context->get_tor_bootstrap_tag();

    g_globals.context->callback_registry_.emit_tor_bootstrap_status_changed(
        progress,
        tag);

    emit q->bootstrapStatusChanged();
}

QObject *TorControl::getConfiguration(const QString &options)
{
    GetConfCommand *command = new GetConfCommand(GetConfCommand::GetConf);
    d->socket->sendCommand(command, command->build(options.toLatin1()));

    QQmlEngine::setObjectOwnership(command, QQmlEngine::CppOwnership);
    return command;
}

QObject *TorControl::setConfiguration(const QVariantMap &options)
{
    SetConfCommand *command = new SetConfCommand;
    command->setResetMode(true);
    d->socket->sendCommand(command, command->build(options));

    QQmlEngine::setObjectOwnership(command, QQmlEngine::CppOwnership);
    return command;
}

bool TorControl::hasOwnership() const
{
    return d->hasOwnership;
}

void TorControl::takeOwnership()
{
    d->hasOwnership = true;
    d->socket->sendCommand("TAKEOWNERSHIP\r\n");

    // Reset PID-based polling
    QVariantMap options;
    options[QStringLiteral("__OwningControllerProcess")] = QVariant();
    setConfiguration(options);
}

bool TorControl::torVersionAsNewAs(const QString &match) const
{
    QRegularExpression r(QStringLiteral("[.-]"));
    QStringList split = torVersion().split(r);
    QStringList matchSplit = match.split(r);

    for (int i = 0; i < matchSplit.size(); i++) {
        if (i >= split.size())
            return false;
        bool ok1 = false, ok2 = false;
        int currentVal = split[i].toInt(&ok1);
        int matchVal = matchSplit[i].toInt(&ok2);
        if (!ok1 || !ok2)
            return false;
        if (currentVal > matchVal)
            return true;
        if (currentVal < matchVal)
            return false;
    }

    // Versions are equal, up to the length of match
    return true;
}

#include "TorControl.moc"
