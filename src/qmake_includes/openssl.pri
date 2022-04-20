unix:!android {
    !isEmpty(OPENSSLDIR) {
        LIBS += -L$${OPENSSLDIR}/lib -lcrypto
    INCLUDEPATH += $${OPENSSLDIR}/include
    } else {
        CONFIG += link_pkgconfig
        PKGCONFIG += libcrypto
    }
}
win32 {
    win32-g++ {
        LIBS += -L$${OPENSSLDIR}/lib -lcrypto
    LIBS += -lcrypt32
    INCLUDEPATH += $${OPENSSLDIR}/include
    } else {
        LIBS += -L$${OPENSSLDIR}/lib -llibeay32
    }

    # required by openssl
    LIBS += -luser32 -lgdi32 -ladvapi32 -lws2_32
}

android{
    INCLUDEPATH += $${OPENSSLDIR}/static/include
    ANDROID_EXTRA_LIBS += \
        $${OPENSSLDIR}/latest/arm/libcrypto_1_1.so \
        $${OPENSSLDIR}/latest/arm/libssl_1_1.so \
        $${OPENSSLDIR}/latest/arm64/libcrypto_1_1.so \
        $${OPENSSLDIR}/latest/arm64/libssl_1_1.so \
        $${OPENSSLDIR}/latest/x86/libcrypto_1_1.so \
        $${OPENSSLDIR}/latest/x86/libssl_1_1.so \
        $${OPENSSLDIR}/latest/x86_64/libcrypto_1_1.so \
        $${OPENSSLDIR}/latest/x86_64/libssl_1_1.so


    equals(ANDROID_TARGET_ARCH, armeabi-v7a) {
        LIBS += -L$${OPENSSLDIR}/static/lib/arm -lssl -lcrypto
    }

    equals(ANDROID_TARGET_ARCH, arm64-v8a) {
        LIBS += -L$${OPENSSLDIR}/static/lib/arm64 -lssl -lcrypto
    }

    equals(ANDROID_TARGET_ARCH, x86) {
        LIBS += -L$${OPENSSLDIR}/static/lib/x86 -lssl -lcrypto
    }

    equals(ANDROID_TARGET_ARCH, x86_64) {
        LIBS += -L$${OPENSSLDIR}/static/lib/x86_64 -lssl -lcrypto
    }
}
