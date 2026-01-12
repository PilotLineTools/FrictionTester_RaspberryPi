#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "SerialController.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    auto serialController = new SerialController(&engine);
    // optional: auto-connect on launch
    // serialController->connectPort();

    engine.rootContext()->setContextProperty("serialController", serialController);

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
