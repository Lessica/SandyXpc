#!/bin/bash

set -e

make clean stage FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=
make clean stage FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless

if [ -d "$THEOS/lib/iphone/roothide" ]; then
    make clean stage FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide
fi
