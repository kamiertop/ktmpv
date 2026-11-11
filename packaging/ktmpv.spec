# SPDX-License-Identifier: CC0-1.0
Name:           ktmpv
Version:        0.1.2
Release:        1%{?dist}
Summary:        Qt media player based on Haruna and libmpv
License:        GPL-3.0-or-later AND GPL-2.0-or-later AND BSD-3-Clause AND CC-BY-4.0 AND CC0-1.0
URL:            https://github.com/kamiertop/ktmpv
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  desktop-file-utils
BuildRequires:  extra-cmake-modules >= 6.24.0
BuildRequires:  gcc-c++
BuildRequires:  gcc-plugin-annobin
BuildRequires:  gettext
BuildRequires:  ninja-build
BuildRequires:  pkgconf-pkg-config
BuildRequires:  redhat-rpm-config
BuildRequires:  cmake(KDSingleApplication-qt6)
BuildRequires:  cmake(MpvQt)
BuildRequires:  cmake(KF6ColorScheme) >= 6.24.0
BuildRequires:  cmake(KF6Config) >= 6.24.0
BuildRequires:  cmake(KF6CoreAddons) >= 6.24.0
BuildRequires:  cmake(KF6Crash) >= 6.24.0
BuildRequires:  cmake(KF6FileMetaData) >= 6.24.0
BuildRequires:  cmake(KF6I18n) >= 6.24.0
BuildRequires:  cmake(KF6IconThemes) >= 6.24.0
BuildRequires:  cmake(KF6KIO) >= 6.24.0
BuildRequires:  cmake(KF6Kirigami) >= 6.24.0
BuildRequires:  cmake(KF6WindowSystem) >= 6.24.0
BuildRequires:  cmake(Qt6Core) >= 6.9.0
BuildRequires:  cmake(Qt6Core5Compat) >= 6.9.0
BuildRequires:  cmake(Qt6QuickControls2) >= 6.9.0
BuildRequires:  cmake(Qt6ShaderTools) >= 6.9.0
BuildRequires:  pkgconfig(libavcodec)
BuildRequires:  pkgconfig(libavformat)
BuildRequires:  pkgconfig(libavutil)
BuildRequires:  pkgconfig(libswscale)
BuildRequires:  qt6qml(org.kde.kitemmodels)
BuildRequires:  qt6qml(org.kde.kquickcontrols)

Requires:       kf6-kconfig
Requires:       kf6-ki18n
Requires:       kf6-kirigami
Requires:       kf6-qqc2-desktop-style
Requires:       qt6-qt5compat
Requires:       qt6-qtdeclarative
Requires:       qt6-qtwayland
Requires:       qt6qml(org.kde.kitemmodels)
Requires:       qt6qml(org.kde.kquickcontrols)
Recommends:     breeze-icon-theme
Recommends:     yt-dlp

%description
Ktmpv is a Haruna fork with a compact playback interface, a collapsible playlist
sidebar, a redesigned settings window and timeline thumbnails for local video.

%prep
%autosetup

%build
%cmake -DHARUNA_INSTALL_GIT_HOOKS=OFF -DHARUNA_ENABLE_QML_DEBUGGING=OFF
%cmake_build

%install
%cmake_install
%find_lang haruna

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/io.github.kamiertop.ktmpv.desktop

%files -f haruna.lang
%dir %{_datadir}/ktmpv
%dir %{_datadir}/ktmpv/locale
%license LICENSES/*.txt
%doc README.md
%{_bindir}/ktmpv
%{_datadir}/applications/io.github.kamiertop.ktmpv.desktop
%{_datadir}/metainfo/io.github.kamiertop.ktmpv.metainfo.xml
%{_datadir}/icons/hicolor/*/apps/ktmpv.*

%changelog
* Wed Nov 11 2026 Ktmpv contributors - 0.1.2-1
- Add the ktmpv gradient application icon.

* Wed Nov 11 2026 Ktmpv contributors - 0.1.1-1
- Use the ktmpv application identity throughout the package.
