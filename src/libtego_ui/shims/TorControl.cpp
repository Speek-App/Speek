#include "TorControl.h"
#include "utils/Settings.h"
#include "pluggables.hpp"

namespace shims
{
    TorControl* TorControl::torControl = nullptr;

    TorControl::TorControl(tego_context_t* context_)
    : context(context_)
    { }

    // callable from QML
    // see TorConfigurationPage.qml
    QObject* TorControl::setConfiguration(const QVariantMap &options)
    {
        QJsonObject json = QJsonObject::fromVariantMap(options);
        return this->setConfiguration(json);
    }

    QObject* TorControl::setConfiguration(const QJsonObject &config) try
    {
        Q_ASSERT(this->m_setConfigurationCommand == nullptr);

        std::unique_ptr<tego_tor_daemon_config_t> daemonConfig;
        tego_tor_daemon_config_initialize(
            tego::out(daemonConfig),
            tego::throw_on_error());

        // generate own json to save to settings
        QJsonObject network;

        // proxy
        if (auto proxyIt = config.find("proxy"); proxyIt != config.end())
        {
            auto proxyObj = proxyIt->toObject();
            auto typeIt = proxyObj.find("type");
            TEGO_THROW_IF_EQUAL(typeIt, proxyObj.end());

            auto typeString = typeIt->toString().toStdString();
            if (typeString != "none")
            {
                TEGO_THROW_IF_FALSE(
                    typeString == "socks4" ||
                    typeString == "socks5" ||
                    typeString == "https");

                auto addressIt = proxyObj.find("address");
                TEGO_THROW_IF_EQUAL(addressIt, proxyObj.end());
                auto addressQString = addressIt->toString();
                auto address = addressQString.toStdString();
                TEGO_THROW_IF(address.size() == 0);

                auto portIt = proxyObj.find("port");
                TEGO_THROW_IF_EQUAL(portIt, proxyObj.end());
                auto port = portIt->toInt();
                TEGO_THROW_IF_FALSE(port > 0 && port < 65536);

                QJsonObject proxy;
                proxy["address"] = addressQString;
                proxy["port"] = port;

                if (typeString == "socks4")
                {
                    tego_tor_daemon_config_set_proxy_socks4(
                        daemonConfig.get(),
                        address.data(),
                        address.size(),
                        static_cast<uint16_t>(port),
                        tego::throw_on_error());

                    proxy["type"] = "socks4";
                }
                else
                {
                    auto usernameIt = proxyObj.find("username");
                    auto passwordIt = proxyObj.find("password");

                    auto usernameQString = (usernameIt == proxyObj.end()) ? QString() : usernameIt->toString();
                    auto passwordQString = (passwordIt == proxyObj.end()) ? QString() : passwordIt->toString();
                    auto username = usernameQString.toStdString();
                    auto password = passwordQString.toStdString();

                    proxy["username"] = usernameQString;
                    proxy["password"] = passwordQString;

                    if (typeString == "socks5")
                    {
                        tego_tor_daemon_config_set_proxy_socks5(
                            daemonConfig.get(),
                            address.data(),
                            address.size(),
                            static_cast<uint16_t>(port),
                            username.data(),
                            username.size(),
                            password.data(),
                            password.size(),
                            tego::throw_on_error());

                        proxy["type"] = "socks5";

                    }
                    else
                    {
                        TEGO_THROW_IF_FALSE(typeString == "https");
                        tego_tor_daemon_config_set_proxy_https(
                            daemonConfig.get(),
                            address.data(),
                            address.size(),
                            static_cast<uint16_t>(port),
                            username.data(),
                            username.size(),
                            password.data(),
                            password.size(),
                            tego::throw_on_error());

                        proxy["type"] = "https";
                    }
                }
                network["proxy"] = proxy;
            }
        }
        // firewall
        if (auto allowedPortsIt = config.find("allowedPorts"); allowedPortsIt != config.end())
        {
            auto allowedPortsArray = allowedPortsIt->toArray();

            std::vector<uint16_t> allowedPorts;
            for(auto value : allowedPortsArray) {
                auto port = value.toInt();
                TEGO_THROW_IF_FALSE(port > 0 && port < 65536);

                // don't add duplicates
                if (std::find(allowedPorts.begin(), allowedPorts.end(), port) == allowedPorts.end())
                {
                    allowedPorts.push_back(static_cast<uint16_t>(port));
                }
            }
            std::sort(allowedPorts.begin(), allowedPorts.end());

            if (allowedPorts.size() > 0)
            {
                tego_tor_daemon_config_set_allowed_ports(
                    daemonConfig.get(),
                    allowedPorts.data(),
                    allowedPorts.size(),
                    tego::throw_on_error());

                network["allowedPorts"] = ([&]() -> QJsonArray {
                    QJsonArray retval;
                    for(auto port : allowedPorts) {
                        retval.push_back(port);
                    }
                    return retval;
                })();
            }
        }
        // bridges
        if (auto bridgeTypeIt = config.find("bridgeType"); bridgeTypeIt != config.end() && *bridgeTypeIt != "none")
        {
            auto bridgeType = bridgeTypeIt->toString();

            // sets list of bridge strings
            const auto tegoTorDaemonConfigSetBridges = [&](const std::vector<std::string>& bridgeStrings) -> void {

                // convert strings to std::string
                const auto bridgeCount = static_cast<size_t>(bridgeStrings.size());

                // allocate buffers to pass to tego
                auto rawBridges = std::make_unique<const char* []>(bridgeCount);
                auto rawBridgeLengths = std::make_unique<size_t[]>(bridgeCount);

                for(size_t i = 0; i < bridgeCount; ++i) {
                    const auto& bridgeString = bridgeStrings[i];
                    rawBridges[i] = bridgeString.c_str();
                    rawBridgeLengths[i] = bridgeString.size();
                }

                tego_tor_daemon_config_set_bridges(
                    daemonConfig.get(),
                    const_cast<const char**>(rawBridges.get()),
                    rawBridgeLengths.get(),
                    bridgeCount,
                    tego::throw_on_error());
            };

            if (bridgeType == "custom")
            {
                auto bridgeStringsIt = config.find("bridgeStrings");
                TEGO_THROW_IF_EQUAL(bridgeStringsIt, config.end());

                std::vector<std::string> bridgeStrings;
                QJsonArray bridgeStringsArray;
                for(auto entry : bridgeStringsIt->toArray()) {
                    auto bridgeString = entry.toString();
                    logger::println("adding: {}", bridgeString);
                    bridgeStrings.push_back(bridgeString.toStdString());
                    bridgeStringsArray.push_back(bridgeString);
                }
                tegoTorDaemonConfigSetBridges(bridgeStrings);

                network["bridgeType"] = "custom";
                network["bridgeStrings"] = bridgeStringsArray;
            }
            else
            {
                auto bridgeStringsIt = defaultBridges.find(bridgeType);
                TEGO_THROW_IF_EQUAL(bridgeStringsIt, defaultBridges.end());

                tegoTorDaemonConfigSetBridges(*bridgeStringsIt);
                network["bridgeType"] = bridgeType;
            }
        }
        tego_context_update_tor_daemon_config(
            context,
            daemonConfig.get(),
            tego::throw_on_error());

        // after config is confirmed updated then save our settings
        auto setConfigurationCommand = std::make_unique<TorControlCommand>();
        QQmlEngine::setObjectOwnership(setConfigurationCommand.get(), QQmlEngine::CppOwnership);

        this->m_setConfigurationCommand = setConfigurationCommand.release();
        connect(
            this->m_setConfigurationCommand,
            &shims::TorControlCommand::finished,
            [network=std::move(network)](bool successful) -> void {
                SettingsObject settings;
                // only persist settings if config was set successfully
                if (successful) {
                    settings.write("network", network);
                } else {
                    settings.unset("network");
                }
            });

        return this->m_setConfigurationCommand;
    } catch (std::exception& ex) {
        logger::println("Exception: {}", ex.what());
        return nullptr;
    }

    QJsonObject TorControl::getConfiguration()
    {
        return SettingsObject().read("network").toObject();
    }

    QObject* TorControl::beginBootstrap() try
    {
        tego_context_update_disable_network_flag(
            context,
            TEGO_FALSE,
            tego::throw_on_error());

        auto setConfigurationCommand = std::make_unique<TorControlCommand>();
        QQmlEngine::setObjectOwnership(setConfigurationCommand.get(), QQmlEngine::CppOwnership);
        this->m_setConfigurationCommand = setConfigurationCommand.release();

        return this->m_setConfigurationCommand;
    } catch (std::exception& ex) {
        logger::println("Exception: {}", ex.what());
        return nullptr;
    }

    QList<QString> TorControl::getBridgeTypes()
    {
        auto types = defaultBridges.keys();
        if (auto it = std::find(types.begin(), types.end(), recommendedBridgeType); it != types.end()) {
            std::iter_swap(it, types.begin());
        }
        return types;
    }

    std::vector<std::string> TorControl::getBridgeStringsForType(const QString &bridgeType)
    {
        if (auto it = defaultBridges.find(bridgeType); it != defaultBridges.end()) {
            auto ret = *it;
            // shuffle the bridge list so that users don't all select the first one
            std::random_device rd;
            std::mt19937 g(rd());
            std::shuffle(ret.begin(), ret.end(), g);
            return ret;
        }
        return {};
    }

    // for now we just assume we always have ownership,
    // as we have no way in config to setup usage of
    // an existing tor process
    bool TorControl::hasOwnership() const
    {
        logger::trace();
        return true;
    }

    bool TorControl::hasBootstrappedSuccessfully() const
    {
        auto value= SettingsObject().read("network.bootstrappedSuccessfully");
        return value.isBool() ? value.toBool() : false;
    }

    QString TorControl::torVersion() const
    {
        logger::trace();
        return tego_context_get_tor_version_string(
            context,
            tego::throw_on_error());
    }

    TorControl::Status TorControl::status() const
    {
        tego_tor_control_status_t status;
        tego_context_get_tor_control_status(
            context,
            &status,
            tego::throw_on_error());

        logger::trace();
        return static_cast<TorControl::Status>(status);
    }

    TorControl::TorStatus TorControl::torStatus() const
    {
        tego_tor_network_status_t status;
        tego_context_get_tor_network_status(
            context,
            &status,
            tego::throw_on_error());

        switch(status)
        {
            case tego_tor_network_status_unknown:
                return TorControl::TorUnknown;
            case tego_tor_network_status_ready:
                return TorControl::TorReady;
            case tego_tor_network_status_offline:
                return TorControl::TorOffline;
            default:
                return TorControl::TorError;
        }
    }

    QVariantMap TorControl::bootstrapStatus() const
    {
        QVariantMap retval;
        retval["progress"] = this->m_bootstrapProgress;
        retval["done"] = (this->m_bootstrapTag == tego_tor_bootstrap_tag_done);
        retval["summary"] = this->m_bootstrapSummary;
        return retval;
    }

    QString TorControl::errorMessage() const
    {
        return m_errorMessage;
    }

    void TorControl::setStatus(Status status)
    {
        auto oldStatus = m_status;
        if (oldStatus == status) return;

        m_status = status;
        emit this->statusChanged(
            static_cast<int>(status),
            static_cast<int>(oldStatus));
    }

    void TorControl::setTorStatus(TorStatus status)
    {
        auto oldStatus = m_torStatus;
        if (oldStatus == status) return;

        m_torStatus = status;
        emit this->torStatusChanged(
            static_cast<int>(status),
            static_cast<int>(oldStatus));
    }

    void TorControl::setErrorMessage(const QString& msg)
    {
        m_errorMessage = msg;
        this->setStatus(TorControl::Error);
    }

    void TorControl::setBootstrapStatus(int32_t progress, tego_tor_bootstrap_tag_t tag, QString&& summary)
    {
        TEGO_THROW_IF_FALSE(progress >= 0 && progress <= 100);
        this->m_bootstrapProgress = static_cast<int>(progress);
        this->m_bootstrapTag = tag;
        this->m_bootstrapSummary = std::move(summary);

        emit torControl->bootstrapStatusChanged();

        if (tag == tego_tor_bootstrap_tag_done) {
            SettingsObject().write("network.bootstrappedSuccessfully", true);
        }
    }
}
