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

#include "TorManager.h"
#include "TorProcess.h"
#include "TorControl.h"
#include "GetConfCommand.h"

#include "error.hpp"
#include "signals.hpp"
#include "globals.hpp"

#include "torrc.hpp"
using tego::g_globals;

using namespace Tor;

namespace Tor
{

class TorManagerPrivate : public QObject
{
    Q_OBJECT

public:
    TorManager *q;
    TorProcess *process;
    TorControl *control;
    QString dataDir;
    QStringList logMessages;
    QString errorMessage;

    explicit TorManagerPrivate(TorManager *parent = 0);

    QString torExecutablePath() const;
    bool createDataDir(const QString &path);
    bool createDefaultTorrc(const QString &path);

    void setError(const QString &errorMessage);

public slots:
    void processStateChanged(int state);
    void processErrorChanged(const QString &errorMessage);
    void processLogMessage(const QString &message);
    void controlStatusChanged(int status);
};

}

TorManager::TorManager(QObject *parent)
    : QObject(parent), d(new TorManagerPrivate(this))
{
}

TorManagerPrivate::TorManagerPrivate(TorManager *parent)
    : QObject(parent)
    , q(parent)
    , process(0)
    , control(new TorControl(this))
{
    connect(control, SIGNAL(statusChanged(int,int)), SLOT(controlStatusChanged(int)));
}

TorManager *TorManager::instance()
{
    static TorManager *p = 0;
    if (!p)
        p = new TorManager(qApp);
    return p;
}

TorControl *TorManager::control()
{
    return d->control;
}

TorProcess *TorManager::process()
{
    return d->process;
}

QString TorManager::dataDirectory() const
{
    return d->dataDir;
}

void TorManager::setDataDirectory(const QString &path)
{
    d->dataDir = QDir::fromNativeSeparators(path);
    if (!d->dataDir.isEmpty() && !d->dataDir.endsWith(QLatin1Char('/')))
        d->dataDir.append(QLatin1Char('/'));
}

QStringList TorManager::logMessages() const
{
    return d->logMessages;
}

QString TorManager::running() const
{
    if (d->process)
    {
        if (d->process->state() == TorProcess::Ready)
        {
            return "Yes";
        }
        return "No";
    }
    return "External";
}

bool TorManager::hasError() const
{
    return !d->errorMessage.isEmpty();
}

QString TorManager::errorMessage() const
{
    return d->errorMessage;
}

void TorManager::start()
{
    if (!d->errorMessage.isEmpty()) {
        d->errorMessage.clear();
        emit errorChanged();

        auto tegoError = std::make_unique<tego_error>();
        g_globals.context->callback_registry_.emit_tor_error_occurred(
            tego_tor_error_origin_manager,
            tegoError.release());
    }

    // Launch a bundled Tor instance
    QString executable = d->torExecutablePath();
    if (executable.isEmpty()) {
        d->setError(QStringLiteral("Cannot find tor executable"));
        return;
    }

    if (!d->process) {
        d->process = new TorProcess(this);
        connect(d->process, SIGNAL(stateChanged(int)), d, SLOT(processStateChanged(int)));
        connect(d->process, SIGNAL(errorMessageChanged(QString)), d,
                SLOT(processErrorChanged(QString)));
        connect(d->process, SIGNAL(logMessage(QString)), d, SLOT(processLogMessage(QString)));
    }

    if (!QFile::exists(d->dataDir) && !d->createDataDir(d->dataDir)) {
        d->setError(QStringLiteral("Cannot write data location: %1").arg(d->dataDir));
        return;
    }

    // always write out a new default torrc
    QString defaultTorrc = d->dataDir + QStringLiteral("default_torrc");
    if (QFile::exists(defaultTorrc) && !QFile::remove(defaultTorrc)) {
        d->setError(QStringLiteral("Could not remove: %1").arg(defaultTorrc));
        return;
    }

    if (!d->createDefaultTorrc(defaultTorrc)) {
        d->setError(QStringLiteral("Cannot write data files: %1").arg(defaultTorrc));
        return;
    }

    QString torrc = d->dataDir + QStringLiteral("torrc");
    if (QFile::exists(torrc)) {
        QFile::remove(torrc);
    }

    d->process->setExecutable(executable);
    d->process->setDataDir(d->dataDir);
    d->process->setDefaultTorrc(defaultTorrc);
    d->process->start();
}

void TorManagerPrivate::processStateChanged(int state)
{
    qDebug() << Q_FUNC_INFO << state << TorProcess::Ready << process->controlPassword() << process->controlHost() << process->controlPort();
    if (state == TorProcess::Ready) {
        control->setAuthPassword(process->controlPassword());
        control->connect(process->controlHost(), process->controlPort());
    }

    switch(state)
    {
        case TorProcess::NotStarted:
            logger::trace();
            g_globals.context->callback_registry_.emit_tor_process_status_changed(tego_tor_process_status_not_started);
            break;
        case TorProcess::Starting:
            logger::trace();
            g_globals.context->callback_registry_.emit_tor_process_status_changed(tego_tor_process_status_starting);
            break;
        case TorProcess::Ready:
            logger::trace();
            g_globals.context->callback_registry_.emit_tor_process_status_changed(tego_tor_process_status_running);
            break;
    }

    emit q->runningChanged();
}

void TorManagerPrivate::processErrorChanged(const QString &message)
{
    qDebug() << "tor error:" << message;
    setError(message);
}

void TorManagerPrivate::processLogMessage(const QString &message)
{
    qDebug() << "tor:" << message;
    if (logMessages.size() >= 50)
        logMessages.takeFirst();
    logMessages.append(message);

    emit q->logMessage(message);

    // marshall message out of the QString into our own char buffer
    auto utf8 = message.toUtf8();

    const auto msgLength = utf8.size();
    const auto msgSize = msgLength + 1;
    auto msg = std::make_unique<char[]>(static_cast<size_t>(msgSize));

    // copy utf8 string to our own buffer
    std::copy(utf8.begin(), utf8.end(), msg.get());
    Q_ASSERT(msg[static_cast<size_t>(msgLength)] == 0);

    g_globals.context->callback_registry_.emit_tor_log_received(
        msg.release(),
        static_cast<size_t>(msgLength));
}

void TorManagerPrivate::controlStatusChanged(int status)
{
    if (status == TorControl::Connected) {
        if (process) {
            // Take ownership via this control socket
            control->takeOwnership();
        }
    }
}

QString TorManagerPrivate::torExecutablePath() const
{
#ifdef Q_OS_WIN
    QString filename(QStringLiteral("/tor.exe"));
#else
    QString filename(QStringLiteral("/tor"));
#endif

    QString path = qApp->applicationDirPath();
    if (QFile::exists(path + filename))
        return path + filename;

#ifdef BUNDLED_TOR_PATH
    path = QStringLiteral(BUNDLED_TOR_PATH);
    if (QFile::exists(path + filename))
        return path + filename;
#endif

    // Try $PATH
    return filename.mid(1);
}

bool TorManagerPrivate::createDataDir(const QString &path)
{
    QDir dir(path);
    return dir.mkpath(QStringLiteral("."));
}

bool TorManagerPrivate::createDefaultTorrc(const QString &path)
{
    static const std::string_view defaultTorrcContent =
        "# Do not edit this file! Contents are managed by Ricochet-Refresh\n"
        "# and your changes will be overwritten\n"
        "SocksPort auto\n"
        "AvoidDiskWrites 1\n"
        "DisableNetwork 1\n"
        "__ReloadTorrcOnSIGHUP 0\n\n"
        "# Pluggable Transport Plugins\n";

    std::stringstream defaultTorrcBuilder;
    defaultTorrcBuilder << defaultTorrcContent;

    // tor's ClientTransportPlugin setting cannot handle PT paths which contain spaces
    // since we have no control over where PTs have been deployed, and the working
    // directory is a different location from the binary location, we create a
    // symlink in the working directory to the actual deployed location
    const auto ptDir = fmt::format("{}/pluggable_transports", qApp->applicationDirPath());
    // remove previous symlink if it exists in case we are a portable install
    // and so the binary locations may have changed
    QFile::remove("pluggable_transports");
    QFile::link(QString::fromStdString(ptDir), QString("pluggable_transports"));

    for (auto plugin : clientTransportPlugins) {
        defaultTorrcBuilder << plugin << "\n";
    }

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly))
        return false;
    if (file.write(defaultTorrcBuilder.str().c_str()) < 0)
        return false;
    return true;
}

void TorManagerPrivate::setError(const QString &message)
{
    errorMessage = message;
    emit q->errorChanged();

    auto tegoError = std::make_unique<tego_error>();
    tegoError->message = message.toStdString();

    g_globals.context->callback_registry_.emit_tor_error_occurred(
        tego_tor_error_origin_manager,
        tegoError.release());
}

#include "TorManager.moc"

