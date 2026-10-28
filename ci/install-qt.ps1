# SPDX-FileCopyrightText: 2026 Iain Chesworth
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs the pinned prebuilt Qt via aqtinstall for local Windows development.
# Mirrors what jurplel/install-qt-action does in CI.
#
#   pwsh ci/install-qt.ps1 [-OutDir C:\Qt]
#
# Then configure with -DCMAKE_PREFIX_PATH=<OutDir>/<QtVersion>/msvc2022_64.

param([string]$OutDir = "C:\Qt")

$ErrorActionPreference = "Stop"
$QtVersion = "6.12.0"
$Arch = "win64_msvc2022_64"
# Qt 6.11 and later split the Windows repository per architecture, which the last
# aqtinstall release on PyPI (3.3.0) cannot read; this is the commit CI installs from.
$AqtSource = "git+https://github.com/miurahr/aqtinstall.git@076e1659807d0b362a3ed684d54c2e9c775eb9c7"

python -m pip install --quiet $AqtSource
python -m aqt install-qt windows desktop $QtVersion $Arch --outputdir $OutDir

$prefix = Join-Path $OutDir "$QtVersion/msvc2022_64"
Write-Host ""
Write-Host "Qt $QtVersion installed to $prefix"
Write-Host "Configure with:  -DCMAKE_PREFIX_PATH=$prefix"
