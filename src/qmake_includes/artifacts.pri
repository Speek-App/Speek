# specify the DESTDIR for final binary and intermediate build files

CONFIG += debug_and_release

CONFIG(release, release|debug) {
    !android{
        DESTDIR = $${PWD}/../../build/release/$${TARGET}
    }
    android{
        DESTDIR = $${PWD}/../../build/release/$${ANDROID_TARGET_ARCH}/$${TARGET}
    }
}
CONFIG(debug, release|debug) {
    !android{
        DESTDIR = $${PWD}/../../build/debug/$${TARGET}
    }
    android{
        DESTDIR = $${PWD}/../../build/debug/$${ANDROID_TARGET_ARCH}/$${TARGET}
    }
}

# artifacts go under hidden dirs in DESTDIR
OBJECTS_DIR = $${DESTDIR}/.obj
MOC_DIR     = $${DESTDIR}/.moc
RCC_DIR     = $${DESTDIR}/.rcc
UI_DIR      = $${DESTDIR}/.ui
