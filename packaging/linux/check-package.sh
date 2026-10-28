#!/usr/bin/env bash
# Checks what the Linux packages hold, from the packages themselves.
#
#   packaging/linux/check-package.sh <folder with the .deb, .rpm and .tar.gz>
#
# The release workflow runs it after CPack, on the Linux runner, so a package that
# is missing something fails the build job before anything is attested or uploaded.
# It reads the files rather than the CMake that made them, which is the point.
set -euo pipefail

dir="${1:?usage: check-package.sh <folder with the packages>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_id="com.iainchesworthlabs.countdownsolver"
failures=0

require() { # <what> <command...>
    local what="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "ok      $what"
    else
        echo "::error::package check failed: $what"
        failures=$((failures + 1))
    fi
}

one() { # the only file matching a pattern
    local files=("$@")
    if [ "${#files[@]}" -ne 1 ] || [ ! -e "${files[0]}" ]; then
        echo "::error::expected exactly one package matching $1, found ${#files[@]}" >&2
        exit 1
    fi
    printf '%s\n' "${files[0]}"
}

deb="$(one "$dir"/*.deb)"
tgz="$(one "$dir"/*.tar.gz)"
echo "== $deb"
contents="$(mktemp)"
unpacked="$(mktemp -d)"
trap 'rm -rf "$contents" "$unpacked"' EXIT
dpkg-deb -c "$deb" > "$contents"
dpkg-deb -x "$deb" "$unpacked"

require "the program is in the private directory"            grep -q ' \./usr/lib/countdownsolver/bin/countdownsolver$' "$contents"
require "the launcher is a link in /usr/bin"                 grep -q ' \./usr/bin/countdownsolver -> ' "$contents"
require "Qt is bundled"                                      grep -q 'usr/lib/countdownsolver/lib/libQt6Core\.so' "$contents"
require "the QML modules are bundled"                        grep -q 'usr/lib/countdownsolver/qml/QtQuick/' "$contents"
require "the xcb platform plugin is bundled"                 grep -q 'usr/lib/countdownsolver/plugins/platforms/libqxcb\.so' "$contents"
require "the desktop entry is named for the identifier"      grep -q "usr/share/applications/${app_id}\.desktop" "$contents"
require "the metadata is named for the identifier"           grep -q "usr/share/metainfo/${app_id}\.metainfo\.xml" "$contents"
require "the scalable icon is named for the identifier"      grep -q "icons/hicolor/scalable/apps/${app_id}\.svg" "$contents"
require "the 256 px icon is named for the identifier"        grep -q "icons/hicolor/256x256/apps/${app_id}\.png" "$contents"
require "the licence is installed"                           grep -q 'usr/share/doc/countdownsolver/copyright' "$contents"
# Qt's deployment puts its translations in <prefix>/translations unless told
# otherwise, which is /usr/translations.
require "nothing is dropped in /usr itself"                  bash -c "! grep -E ' \./usr/[^/]+/?\$' '$contents' | grep -v -E ' \./usr/(bin|lib|share)/?\$'"
require "Qt's translations are in the private directory"     grep -q 'usr/lib/countdownsolver/translations/qt_de\.qm' "$contents"
require "qt.conf points Qt at them"                          grep -qx 'Translations = lib/countdownsolver/translations' "$unpacked/usr/lib/countdownsolver/bin/qt.conf"
# What the package cannot give honest dependencies for, or does not carry.
require "the GTK 3 theme plugin is not bundled"              bash -c "! grep -q 'libqgtk3\.so' '$contents'"
require "no Wayland client libraries or integrations"        bash -c "! grep -q -E 'libQt6Wayland|libQt6WlShell|plugins/wayland-' '$contents'"
require "no QML debugger or profiler plugins"                bash -c "! grep -q 'plugins/qmltooling' '$contents'"
require "the .deb names its maintainer"                      bash -c "dpkg-deb -f '$deb' Maintainer | grep -q ."
require "the .deb does not depend on a system Qt"            bash -c "! dpkg-deb -f '$deb' Depends | grep -q -i 'qt6'"
require "the .tar.gz holds the program"                      bash -c "tar -tzf '$tgz' | grep -q 'usr/lib/countdownsolver/bin/countdownsolver\$'"

shopt -s nullglob
for rpm in "$dir"/*.rpm; do
    echo "== $rpm"
    require "the .rpm does not require a system Qt"          bash -c "! rpm -qp --requires '$rpm' | grep -q -i 'qt6'"
    require "the .rpm holds the program"                     bash -c "rpm -qlp '$rpm' | grep -qx '/usr/lib/countdownsolver/bin/countdownsolver'"
done

# The metadata a menu and a software centre read.
if command -v desktop-file-validate >/dev/null; then
    require "the desktop entry validates"                    desktop-file-validate "$unpacked/usr/share/applications/${app_id}.desktop"
else
    echo "::warning::desktop-file-validate is not installed: the desktop entry was not validated"
fi
if command -v appstreamcli >/dev/null; then
    require "the AppStream metadata validates"               appstreamcli validate --no-net "$unpacked/usr/share/metainfo/${app_id}.metainfo.xml"
else
    echo "::warning::appstreamcli is not installed: the AppStream metadata was not validated"
fi

# Every system library the files link against is one the .deb's Depends
# provides (check-depends.sh says why a list written by hand needs this). Run
# in the open, not through require(): when it fails, which libraries are
# missing is the whole message.
if bash "$here/check-depends.sh" "$deb"; then
    echo "ok      the .deb's Depends covers every system library it links"
else
    echo "::error::package check failed: the .deb's Depends does not cover every system library it links"
    failures=$((failures + 1))
fi

if [ "$failures" -ne 0 ]; then
    echo "::error::$failures package check(s) failed"
    exit 1
fi
echo "package checks ok"
