#include <QGuiApplication>

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickView>
#include <qqml.h>
#include <QDebug>
#include <QSurfaceFormat>

#include "AppEngine.h"
#include "AppConstant.h"

int main(int argc, char **argv)
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    CONSOLE << "LOL";

    QApplication app(argc, argv);

    QSurfaceFormat fmt;
    fmt.setVersion( 1, 4 );
    fmt.setProfile( QSurfaceFormat::CoreProfile );
    QSurfaceFormat::setDefaultFormat( fmt );

    app.setOrganizationName("kms_team");
    app.setOrganizationDomain("kms_team");

    AppEngine appEngine;
    appEngine.initEngine();
    appEngine.startEngine();

    return app.exec();
}
