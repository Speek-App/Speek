#pragma once

constexpr std::array<std::string_view, 2> clientTransportPlugins = {
    // obfs4proxy configuration
    #ifdef Q_OS_WIN
    R"(ClientTransportPlugin meek_lite,obfs2,obfs3,obfs4,scramblesuit exec pluggable_transports\obfs4proxy.exe)",
    #else
    R"(ClientTransportPlugin meek_lite,obfs2,obfs3,obfs4,scramblesuit exec pluggable_transports/obfs4proxy)",
    #endif
    // snowflake configuration
    #ifdef Q_OS_WIN
    R"(ClientTransportPlugin snowflake exec pluggable_transports\snowflake-client.exe -url https://snowflake-broker.torproject.net.global.prod.fastly.net/ -front cdn.sstatic.net -ice stun:stun.l.google.com:19302,stun:stun.voip.blackberry.com:3478,stun:stun.altar.com.pl:3478,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.sonetel.net:3478,stun:stun.stunprotocol.org:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478)",
    #else
    R"(ClientTransportPlugin snowflake exec pluggable_transports/snowflake-client -url https://snowflake-broker.torproject.net.global.prod.fastly.net/ -front cdn.sstatic.net -ice stun:stun.l.google.com:19302,stun:stun.voip.blackberry.com:3478,stun:stun.altar.com.pl:3478,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.sonetel.net:3478,stun:stun.stunprotocol.org:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478)",
    #endif
};
