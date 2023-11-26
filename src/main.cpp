#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickView>
#include <QTranslator>
#include <LayerShellQt6/shell.h>
#include <LayerShellQt6/window.h>

int main(int argc, char *argv[]) {
    LayerShellQt::Shell::useLayerShell();
    QGuiApplication app(argc, argv);

    QString locale = QLocale::system().name();
    QTranslator translator;
    bool translated = translator.load(
        QString(":/i18n/cutie-ongoing-call_") + locale);
    if (translated)
        app.installTranslator(&translator);

    QQuickView view;

    LayerShellQt::Window *layerShell = LayerShellQt::Window::get(&view);
    layerShell->setLayer(LayerShellQt::Window::LayerOverlay);
    layerShell->setAnchors(LayerShellQt::Window::AnchorTop);
    layerShell->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityExclusive);
    layerShell->setExclusiveZone(-1);
    layerShell->setScope("cutie-ongoing-call");

    QObject::connect(view.engine(), &QQmlApplicationEngine::quit, &app, &QGuiApplication::quit);

    view.setSource(QUrl("qrc:/Call.qml"));
    view.setColor(QColor(Qt::transparent));
    view.show();

    return app.exec();
}