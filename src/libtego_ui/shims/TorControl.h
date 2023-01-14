#pragma once

#include "TorCommand.h"

namespace shims
{
    // shim version of Tor::ToControl with just the functionality requried by the UI
    class TorControl : public QObject
    {
        Q_OBJECT
        Q_ENUMS(Status TorStatus)

        Q_PROPERTY(bool hasOwnership READ hasOwnership CONSTANT)
        Q_PROPERTY(QString torVersion READ torVersion CONSTANT)
        // Status of the control connection
        Q_PROPERTY(Status status READ status NOTIFY statusChanged)
        // Status of Tor (and whether it believes it can connect)
        Q_PROPERTY(TorStatus torStatus READ torStatus NOTIFY torStatusChanged)
        Q_PROPERTY(QVariantMap bootstrapStatus READ bootstrapStatus NOTIFY bootstrapStatusChanged)
        // uses statusChanged like actual backend implementation
        Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY statusChanged)
        Q_PROPERTY(bool hasBootstrappedSuccessfully READ hasBootstrappedSuccessfully CONSTANT)
    public:
        enum Status
        {
            Error = -1,
            NotConnected,
            Connecting,
            Authenticating,
            Connected
        };

        enum TorStatus
        {
            TorError = -1,
            TorUnknown,
            TorOffline,
            TorReady
        };

        Q_INVOKABLE QObject *setConfiguration(const QVariantMap &options);
        QObject* setConfiguration(const QJsonObject& options);
        Q_INVOKABLE QJsonObject getConfiguration();
        Q_INVOKABLE QObject *beginBootstrap();

        // QVariant(Map) is not needed here, since QT handles the conversion to
        // a JS array for us: see https://doc.qt.io/qt-5/qtqml-cppintegration-data.html#sequence-type-to-javascript-array
        Q_INVOKABLE QList<QString> getBridgeTypes();
        std::vector<std::string> getBridgeStringsForType(const QString &bridgeType);

        TorControl(tego_context_t* context);

        /* Ownership means that tor is managed by this socket, and we
         * can shut it down, own its configuration, etc. */
        bool hasOwnership() const;
        bool hasBootstrappedSuccessfully() const;

        QString torVersion() const;
        Status status() const;
        TorStatus torStatus() const;
        QVariantMap bootstrapStatus() const;
        QString errorMessage() const;

        void setStatus(Status);
        void setTorStatus(TorStatus);
        void setErrorMessage(const QString&);
        void setBootstrapStatus(int32_t progress, tego_tor_bootstrap_tag_t tag, QString&& summary);

        static TorControl* torControl;
        TorControlCommand* m_setConfigurationCommand = nullptr;
        Status m_status = NotConnected;
        TorStatus m_torStatus = TorUnknown;
        QString m_errorMessage;
        int m_bootstrapProgress = 0;
        tego_tor_bootstrap_tag_t m_bootstrapTag = tego_tor_bootstrap_tag_invalid;
        QString m_bootstrapSummary;

    signals:
        void statusChanged(int newStatus, int oldStatus);
        void torStatusChanged(int newStatus, int oldStatus);
        void bootstrapStatusChanged();

    private:
        tego_context_t* context;
    };
}
