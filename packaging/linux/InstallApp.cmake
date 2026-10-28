# SPDX-FileCopyrightText: 2026 Iain Chesworth
# SPDX-License-Identifier: GPL-3.0-or-later
# Linux: the install rules that the .deb, .rpm and .tar.gz package. The app and
# the Qt it carries live in one private directory, a launcher goes in
# /usr/bin, and the desktop entry, AppStream metadata and icons go to the
# standard share places.
#
# Included by src/app/CMakeLists.txt after the countdownsolver target is
# defined, so `countdownsolver` is the app.
include(GNUInstallDirs)

set_target_properties(countdownsolver PROPERTIES
    INSTALL_RPATH "$ORIGIN/../lib"
    INSTALL_RPATH_USE_LINK_PATH FALSE)

# When packaged under /usr this is /usr/lib/countdownsolver, so the Qt libraries
# never sit beside, or collide with, the distribution's own.
set(_app_dir "lib/countdownsolver")

# Where Qt's deployment puts things, read by its script at install time.
install(CODE "
    set(QT_DEPLOY_BIN_DIR \"${_app_dir}/bin\")
    set(QT_DEPLOY_LIB_DIR \"${_app_dir}/lib\")
    set(QT_DEPLOY_PLUGINS_DIR \"${_app_dir}/plugins\")
    set(QT_DEPLOY_QML_DIR \"${_app_dir}/qml\")
    set(QT_DEPLOY_TRANSLATIONS_DIR \"${_app_dir}/translations\")
")

install(TARGETS countdownsolver RUNTIME DESTINATION "${_app_dir}/bin")

# Qt's runtime, the plugins and the QML modules the app imports.
qt_generate_deploy_qml_app_script(
    TARGET countdownsolver
    OUTPUT_SCRIPT COUNTDOWN_SOLVER_DEPLOY_SCRIPT
    NO_UNSUPPORTED_PLATFORM_ERROR)
install(SCRIPT "${COUNTDOWN_SOLVER_DEPLOY_SCRIPT}")

# Things Qt's deployment script does not do the way a package needs.
#
# 1. qt.conf. The script writes one with the prefix and the four directories it
#    was given, but never a Translations entry, so Qt would look for its own
#    catalogues (LanguageManager loads qt_<language>.qm from
#    QLibraryInfo::TranslationsPath) in <prefix>/translations, which is
#    /usr/translations: a directory that no other package would expect. They
#    are deployed into the private directory above, and qt.conf says so.
# 2. Plugins that cannot be given honest dependencies. The deployment copies
#    every platform theme and the Wayland integrations Qt knows. The GTK 3
#    theme links GTK, Cairo, Pango and ATK, which a KDE or a minimal desktop
#    does not have and the package should not require; Qt falls back to the
#    desktop-portal theme, which is bundled. The Wayland client libraries and
#    shell integrations belong to a Wayland platform plugin the package does
#    not carry (xcb only: a Wayland session runs the app through XWayland), so
#    they would be unused weight with dependencies of their own. The QML
#    debugger and profiler servers (plugins/qmltooling) are not for a release.
install(CODE "
    set(_root \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${_app_dir}\")
    file(APPEND \"\${_root}/bin/qt.conf\" \"Translations = ${_app_dir}/translations\\n\")
    file(REMOVE \"\${_root}/plugins/platformthemes/libqgtk3.so\")
    file(REMOVE_RECURSE \"\${_root}/plugins/qmltooling\")
    file(GLOB _wayland_dirs LIST_DIRECTORIES true \"\${_root}/plugins/wayland-*\")
    file(GLOB _wayland_libs \"\${_root}/lib/libQt6Wayland*\"
                            \"\${_root}/lib/libQt6WlShellIntegration*\")
    if(_wayland_dirs)
        file(REMOVE_RECURSE \${_wayland_dirs})
    endif()
    if(_wayland_libs)
        file(REMOVE \${_wayland_libs})
    endif()
")

# The launcher: a link in /usr/bin to the program in the private directory.
install(CODE "
    file(MAKE_DIRECTORY \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}\")
    file(CREATE_LINK \"../${_app_dir}/bin/countdownsolver\"
         \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/countdownsolver\" SYMBOLIC)
")

# --- desktop entry, AppStream metadata, icons ----------------------------------
# Honours SOURCE_DATE_EPOCH, so a reproducible build stays reproducible.
string(TIMESTAMP COUNTDOWN_RELEASE_DATE "%Y-%m-%d" UTC)
# A pre-release is a development release to a software centre, and AppStream
# orders versions the way Debian does: "~" sorts before the release.
if(COUNTDOWN_VERSION_PRERELEASE STREQUAL "")
    set(COUNTDOWN_APPSTREAM_RELEASE_TYPE "stable")
    set(COUNTDOWN_APPSTREAM_VERSION "${PROJECT_VERSION}")
else()
    set(COUNTDOWN_APPSTREAM_RELEASE_TYPE "development")
    set(COUNTDOWN_APPSTREAM_VERSION "${PROJECT_VERSION}~${COUNTDOWN_VERSION_PRERELEASE}")
endif()

set(_packaging_dir "${CMAKE_CURRENT_BINARY_DIR}/packaging")
configure_file("${PROJECT_SOURCE_DIR}/packaging/linux/countdownsolver.desktop.in"
    "${_packaging_dir}/${COUNTDOWN_APPLICATION_ID}.desktop" @ONLY)
configure_file("${PROJECT_SOURCE_DIR}/packaging/linux/countdownsolver.metainfo.xml.in"
    "${_packaging_dir}/${COUNTDOWN_APPLICATION_ID}.metainfo.xml" @ONLY)

install(FILES "${_packaging_dir}/${COUNTDOWN_APPLICATION_ID}.desktop"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
install(FILES "${_packaging_dir}/${COUNTDOWN_APPLICATION_ID}.metainfo.xml"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/metainfo")

# The icon is installed under the application id, which is the name the desktop
# entry and the metadata give it.
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/resources/icon/app.svg"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps"
    RENAME "${COUNTDOWN_APPLICATION_ID}.svg")
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/resources/icon/app_256.png"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/icons/hicolor/256x256/apps"
    RENAME "${COUNTDOWN_APPLICATION_ID}.png")

# The licence, for the package.
install(FILES "${PROJECT_SOURCE_DIR}/LICENSE"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/countdownsolver"
    RENAME "copyright")
