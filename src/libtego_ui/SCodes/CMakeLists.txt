cmake_minimum_required(VERSION 3.1)

project(SCodes LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if (NOT DEFINED BUILD_SHARED_LIBS)
    set(BUILD_SHARED_LIBS ON)
endif()

set(BUILD_UNIT_TESTS OFF)
set(BUILD_BLACKBOX_TESTS OFF)
set(BUILD_EXAMPLES OFF)
add_subdirectory(zxing-cpp)

find_package(QT NAMES Qt5 Qt6 COMPONENTS Core Multimedia Concurrent Quick REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Multimedia Concurrent Quick REQUIRED)

file(GLOB SOURCE_CPP
    "*.cpp"
)

add_library(${PROJECT_NAME} STATIC ${SOURCE_CPP})

set_target_properties(${PROJECT_NAME} PROPERTIES
    QT_QML_MODULE_VERSION 1.0
    QT_QML_MODULE_URI com.scythestudio.scodes
)

target_link_libraries(${PROJECT_NAME} PUBLIC ZXing Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Multimedia Qt${QT_VERSION_MAJOR}::Concurrent Qt${QT_VERSION_MAJOR}::Quick)
target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/zxing-cpp/thirdparty/stb)

if (ANDROID)
    find_package(Qt${QT_VERSION_MAJOR} COMPONENTS AndroidExtras REQUIRED)
    target_link_libraries(${PROJECT_NAME} PUBLIC Qt${QT_VERSION_MAJOR}::AndroidExtras)
    target_link_libraries(${PROJECT_NAME} PUBLIC EGL GLESv2)
endif()