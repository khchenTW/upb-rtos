#!/bin/bash

thispath=$(realpath .)

mkdir esp
cd esp
git clone -b v5.5.1 --recursive --depth 1 --shallow-submodules https://github.com/espressif/esp-idf.git 

mkdir watchy
cd watchy
git clone -b 1.17.4 --depth 1 --shallow-submodules https://github.com/adafruit/Adafruit_BusIO.git
git clone -b 1.12.3 --depth 1 --shallow-submodules https://github.com/adafruit/Adafruit-GFX-Library.git
git clone -b 3.3.2 --depth 1 --shallow-submodules https://github.com/espressif/arduino-esp32.git arduino && \
    cd arduino && \
    git submodule update --init --recursive && cd ..
git clone -b 0.2.0 --depth 1 --shallow-submodules https://github.com/arduino-libraries/Arduino_JSON.git
git clone -b 3.1.2 --depth 1 --shallow-submodules https://github.com/JChristensen/DS3232RTC.git
git clone -b 1.6.5 --depth 1 --shallow-submodules https://github.com/ZinggJM/GxEPD2.git
git clone -b 3.2.1 --depth 1 --shallow-submodules https://github.com/arduino-libraries/NTPClient.git
git clone -b 1.0.3 --depth 1 --shallow-submodules https://github.com/orbitalair/Rtc_Pcf8563.git
git clone -b v1.6.1 --depth 1 --shallow-submodules https://github.com/PaulStoffregen/Time.git
git clone -b v1.4.15 --depth 1 --shallow-submodules https://github.com/sqfmi/Watchy.git
git clone -b v2.0.17 --depth 1 --shallow-submodules https://github.com/tzapu/WiFiManager.git

cd $thispath
cp patches/Arduino_JSON.cmake esp/watchy/Arduino_JSON/CMakeLists.txt
cp patches/DS3232RTC.cmake esp/watchy/DS3232RTC/CMakeLists.txt
cp patches/GxEPD2.cmake esp/watchy/GxEPD2/CMakeLists.txt
cp patches/NTPClient.cmake esp/watchy/NTPClient/CMakeLists.txt
cp patches/Rtc_Pcf8563.cmake esp/watchy/Rtc_Pcf8563/CMakeLists.txt
cp patches/Time.cmake esp/watchy/Time/CMakeLists.txt
cp patches/Watchy.cmake esp/watchy/Watchy/CMakeLists.txt

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/REQUIRES arduino-esp32/REQUIRES arduino/' esp/watchy/Adafruit_BusIO/CMakeLists.txt
else
    sed -i 's/REQUIRES arduino-esp32/REQUIRES arduino/' esp/watchy/Adafruit_BusIO/CMakeLists.txt
fi

cp patches/espidf.diff esp/esp-idf/
cp patches/watchy.diff esp/watchy/Watchy/
cp patches/wifimanager.diff esp/watchy/WiFiManager/

cd $thispath/esp/esp-idf/
git apply espidf.diff

cd $thispath/esp/watchy/Watchy/
git apply watchy.diff

cd $thispath/esp/watchy/WiFiManager/
git apply wifimanager.diff

rm -rf $thispath/esp/esp-idf/components/freertos && \
ln -s $thispath/freertos $thispath/esp/esp-idf/components/freertos

# Use shared toolchains when available; otherwise keep per-user installation.
SHARED_IDF_TOOLS=/usr/lib/esp-idf-tools

mkdir -p "$HOME/.espressif" || exit 1

if [ -d "$SHARED_IDF_TOOLS" ]; then
    # Preserve existing directories and symlinks, including dangling symlinks.
    if [ ! -e "$HOME/.espressif/tools" ] && [ ! -L "$HOME/.espressif/tools" ]; then
        ln -s "$SHARED_IDF_TOOLS" "$HOME/.espressif/tools" || exit 1
    fi
fi

cd "$thispath/esp/esp-idf/" || exit 1
chmod +x install.sh || exit 1
./install.sh esp32,esp32c6 || exit 1

echo
echo "Setup completed."
echo "To activate ESP-IDF in your current shell, run from the repository root:"
echo "  source esp/esp-idf/export.sh"
