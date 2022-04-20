include($${PWD}/qmake_includes/artifacts.pri)

TEMPLATE = subdirs
CONFIG += ordered
SUBDIRS = \
    libtego \
    libtego_ui \
    tego_ui \
    tego_group \


# macx can't build tests for somereason, stub out for now
!macx:!android {
    SUBDIRS += tests \
}

