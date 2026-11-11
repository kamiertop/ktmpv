/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QQuickWindow>

#include <KLocalizedQmlContext>
#include <KLocalizedString>

#include <KDSingleApplication>

#include "application.h"
#include "config-haruna.h"
#include "generalsettings.h"
#include "thumbnailimageprovider.h"

#ifdef QT_DEBUG
#include <QElapsedTimer>
#endif

using namespace Qt::StringLiterals;

static const auto INITIAL_STYLE = QQuickStyle::name();

int main(int argc, char *argv[])
{
#ifdef QT_DEBUG
    QElapsedTimer timer;
    timer.start();
#endif
    qSetMessagePattern(u"%{function}() : %{message}\n"_s);

    QApplication::setOrganizationName(u"ktmpv"_s);
    QApplication::setApplicationName(u"ktmpv"_s);
    QApplication::setOrganizationDomain(u"kamiertop.github.io"_s);
    QApplication::setApplicationDisplayName(u"ktmpv"_s);
    QApplication::setApplicationVersion(Application::version());
    // Set the portal identity before the platform plugin starts using D-Bus.
    QGuiApplication::setDesktopFileName(u"io.github.kamiertop.ktmpv"_s);

    // required by mpv
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
    QQuickWindow::setDefaultAlphaBuffer(true);

    QIcon::setFallbackThemeName(u"breeze"_s);

    QApplication qApplication(argc, argv);
    // Use the freshly compiled catalogs when running directly from build/bin.
    const QDir executableDir(QCoreApplication::applicationDirPath());
    const auto localCatalogs = executableDir.absoluteFilePath(u"../locale"_s);
    const auto installedCatalogs = executableDir.absoluteFilePath(QStringLiteral(KTMPV_LOCALE_DIR));
    KLocalizedString::addDomainLocaleDir("haruna", QDir(localCatalogs).exists() ? localCatalogs : installedCatalogs);
    QApplication::setWindowIcon(QIcon::fromTheme(u"ktmpv"_s));

    bool handledByQPT = INITIAL_STYLE != QQuickStyle::name();
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE") && !handledByQPT) {
        QQuickStyle::setStyle(u"org.kde.desktop"_s);
        QQuickStyle::setFallbackStyle(u"Fusion"_s);
    }

    auto *application = Application::instance();

    KDSingleApplication kdsApp;
    if (kdsApp.isPrimaryInstance()) {
        QObject::connect(&kdsApp, &KDSingleApplication::messageReceived, &qApplication, [=](const QByteArray &message) {
            QString file;
            QString token;

            QByteArray byteArray{message};
            QDataStream dataStream(&byteArray, QIODevice::ReadOnly);
            dataStream >> file >> token;

            application->handleSecondayInstanceMessage(file.toUtf8(), token);
        });
    } else {
        if (GeneralSettings::useSingleInstance()) {
            QCommandLineParser clParser;
            clParser.process(qApplication);
            if (!clParser.positionalArguments().isEmpty()) {
                const QString file = clParser.positionalArguments().constFirst();
                const QString token = qEnvironmentVariable("XDG_ACTIVATION_TOKEN");

                QByteArray byteArray;
                QDataStream dataStream(&byteArray, QIODevice::WriteOnly);
                dataStream << file << token;

                kdsApp.sendMessage(byteArray);
            }
            exit(EXIT_SUCCESS);
        }
    }

    QQmlApplicationEngine engine(&qApplication);

    KLocalization::setupLocalizedContext(&engine);

    engine.addImageProvider(u"thumbnail"_s, new ThumbnailImageProvider());
    engine.loadFromModule("org.kde.haruna", "Main");

    if (engine.rootObjects().isEmpty()) {
        return EXIT_FAILURE;
    }

    application->setQmlEngine(&engine);

#ifdef QT_DEBUG
    qDebug() << timer.elapsed() << "ms elapsed";
#endif
    return QApplication::exec();
}
