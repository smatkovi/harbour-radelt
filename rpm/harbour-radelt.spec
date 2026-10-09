Name:       harbour-radelt
Summary:    Kilometres for Österreich radelt
Version:    0.5.0
Release:    1
Group:      Qt/Qt
License:    GPLv3
URL:        https://github.com/smatkovi/harbour-radelt
Source0:    %{name}-%{version}.tar.bz2
Source100:  harbour-radelt.yaml

Requires:   sailfishsilica-qt5 >= 0.10.9
# The position source lives in the positioning import; without it the
# recording page comes up and never gets a fix.
Requires:   qt5-qtdeclarative-import-positioning
# Nemo.KeepAlive, for holding off the blanking while the numbers are watched.
Requires:   libkeepalive >= 1.8

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Positioning)
BuildRequires:  pkgconfig(Qt5Network)
BuildRequires:  desktop-file-utils

%description
Records bicycle rides with the satellite receiver, keeps them on the phone as
GPX, and sends the kilometres to the Österreich radelt platform. Rides can
also be typed in by hand.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5 VERSION=%{version}
%make_build

%install
rm -rf %{buildroot}
%qmake5_install

desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%{_datadir}/ambience/%{name}
