cmake_minimum_required(VERSION 3.16)
project(cutie-ongoing-call VERSION 1.0 LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(QT_DEFAULT_MAJOR_VERSION 6)
set(QAPPLICATION_CLASS QApplication)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Qml LinguistTools)
find_package(LayerShellQt6 REQUIRED)

qt_standard_project_setup()

set(cutie-ongoing-call_SOURCES 
        src/main.cpp
)

qt_add_resources(APP_RESOURCES 
	${CMAKE_SOURCE_DIR}/src/qml/qml.qrc
	${CMAKE_SOURCE_DIR}/sounds/sounds.qrc)

qt_add_executable(cutie-ongoing-call ${cutie-ongoing-call_SOURCES} ${APP_RESOURCES})

qt_add_translations(cutie-ongoing-call
    TS_FILES ${CMAKE_SOURCE_DIR}/translations/cutie-ongoing-call_fi.ts)

target_include_directories(cutie-ongoing-call PUBLIC src)

target_link_libraries(cutie-ongoing-call PUBLIC LayerShellQtInterface6 Qt::Core Qt::Quick Qt::Qml Qt::DBus)

install(TARGETS cutie-ongoing-call RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
