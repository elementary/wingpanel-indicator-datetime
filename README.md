# Wingpanel Date &amp; Time Indicator
[![l10n](https://l10n.elementary.io/widgets/wingpanel/wingpanel-indicator-datetime/svg-badge.svg)](https://l10n.elementary.io/projects/wingpanel/wingpanel-indicator-datetime)

## Building and Installation

You'll need the following dependencies:

* cmake
* gobject-introspection
* libecal1.2-dev
* libedataserver1.2-dev
* libical-dev
* libgranite-dev
* libwingpanel-2.0-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`

    sudo make install
