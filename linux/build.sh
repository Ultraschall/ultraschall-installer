#!/bin/bash

################################################################################
#
# Copyright (c) The Ultraschall Project (http://ultraschall.fm)
#
# The MIT License (MIT)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
################################################################################

echo "**********************************************************************"
echo "*                                                                    *"
echo "*            BUILDING ULTRASCHALL INSTALLER PACKAGE                  *"
echo "*                                                                    *"
echo "**********************************************************************"

# Configuration
ULTRASCHALL_CMAKE_TOOL=cmake
ULTRASCHALL_PANDOC_TOOL=pandoc

#ULTRASCHALL_BUILD_PRODUCT="ultraschall"
#ULTRASCHALL_BUILD_VERSION="5.1.0"
#ULTRASCHALL_BUILD_DATE=$(date -u "+%Y%m%dT%H%M%S")Z
ULTRASCHALL_BUILD_ID=$(uuidgen)

ULTRASCHALL_BUILD_RELEASE=0

ULTRASCHALL_ROOT_DIRECTORY=$(pwd)
ULTRASCHALL_BUILD_DIRECTORY="$ULTRASCHALL_ROOT_DIRECTORY/build"
ULTRASCHALL_BUILD_LOG="$ULTRASCHALL_ROOT_DIRECTORY/build.log"

ULTRASCHALL_PLUGIN_URL="https://github.com/Ultraschall/ultraschall-plugin.git"
ULTRASCHALL_PLUGIN_BRANCH="main"

ULTRASCHALL_SOUNDBOARD_URL="https://github.com/Ultraschall/ultraschall-soundboard.git"
ULTRASCHALL_SOUNDBOARD_BRANCH="main"

ULTRASCHALL_PORTABLE_URL="https://github.com/Ultraschall/ultraschall-portable.git"
ULTRASCHALL_PORTABLE_BRANCH="master"

ULTRASCHALL_ASSETS_URL="https://github.com/Ultraschall/ultraschall-assets.git"
ULTRASCHALL_ASSETS_BRANCH="master"

STUDIO_LINK_PLUGIN_RELEASE=v21.12.0-beta-5cf3b28

if [ "$1" = "--help" ]; then
  echo "Usage: build.sh [ --release ]"
  exit 0
elif [ "$1" = "--release" ]; then
  ULTRASCHALL_BUILD_RELEASE=1
fi

# ULTRASCHALL_DEPENDENCIES="cmake pandoc ninja-build freetype-devel libXrandr-devel libXinerama-devel libXcursor-devel alsa-lib-devel libcurl-devel"

# echo "Checking whether required software packages are installed..."
# ULTRASCHALL_DEPENDENCIES="cmake pandoc ninja-build libxrandr-dev libxinerama-dev libxcursor-dev libasound2-dev libcurl4-openssl-dev"
# dpkg -l $ULTRASCHALL_DEPENDENCIES > /dev/null
# if [ $? -ne 0 ]; then
#   echo "Dependency check failed, required packages:"
#   echo "$ULTRASCHALL_DEPENDENCIES"
#   exit
# fi
# echo "Done."

SOURCE_BRANCH='develop'
if [ $ULTRASCHALL_BUILD_RELEASE = 1 ]; then
  SOURCE_BRANCH='main'
fi

echo "Building installer from $SOURCE_BRANCH branch..."

# Specify build id
if [ $ULTRASCHALL_BUILD_RELEASE = 1 ]; then
  ULTRASCHALL_BUILD_ID='5.1.0'
else
  ULTRASCHALL_BUILD_ID='R5.1.0-preview'
fi

ULTRASCHALL_INSTALLER_DIR="$ULTRASCHALL_BUILD_ID"

# Create build log
if [ -f "$ULTRASCHALL_BUILD_LOG" ]; then
  rm -f "$ULTRASCHALL_BUILD_LOG"
fi
touch "$ULTRASCHALL_BUILD_LOG"

# Create intermediate data folder
if [ ! -d "$ULTRASCHALL_BUILD_DIRECTORY" ]; then
  mkdir "$ULTRASCHALL_BUILD_DIRECTORY"
fi

pushd "$ULTRASCHALL_BUILD_DIRECTORY" > /dev/null || exit

if [ ! -d ultraschall-plugin ]; then
  echo "Downloading Ultraschall REAPER Plug-in..."
  git clone --branch $ULTRASCHALL_PLUGIN_BRANCH --depth 1 $ULTRASCHALL_PLUGIN_URL ultraschall-plugin >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
  if [ ! -d ultraschall-plugin ]; then
    echo "Failed to download Ultraschall REAPER Plug-in."
    exit
  fi
else
  echo "Updating Ultraschall REAPER Plug-in..."
  pushd ultraschall-plugin > /dev/null || exit
  git pull >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
  popd > /dev/null || exit
fi
echo "Done."

if [ ! -d ultraschall-soundboard ]; then
  echo "Downloading Ultraschall Soundboard..."
  git clone --branch $ULTRASCHALL_SOUNDBOARD_BRANCH --depth 1 $ULTRASCHALL_SOUNDBOARD_URL ultraschall-soundboard >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
  if [ ! -d ultraschall-soundboard ]; then
    echo "Failed to download Ultraschall Soundboard."
    exit
  fi
else
  echo "Updating Ultraschall Soundboard..."
  pushd ultraschall-soundboard > /dev/null || exit
  git pull >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
  popd > /dev/null || exit
fi
echo "Done."

if [ ! -d ultraschall-portable ]; then
  echo "Downloading Ultraschall REAPER API..."
  git clone --branch $ULTRASCHALL_PORTABLE_BRANCH --depth 1 $ULTRASCHALL_PORTABLE_URL ultraschall-portable >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
  if [ ! -d ultraschall-portable ]; then
    echo "Failed to download Ultraschall REAPER API."
    exit
  fi
else
  echo "Updating Ultraschall REAPER API..."
  pushd ultraschall-portable > /dev/null || exit
  git pull >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
  popd > /dev/null || exit
fi
echo "Done."

if [ ! -d ultraschall-assets ]; then
  echo "Downloading Ultraschall REAPER Resources..."
  git clone --branch $ULTRASCHALL_ASSETS_BRANCH --depth 1 $ULTRASCHALL_ASSETS_URL ultraschall-assets >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
  if [ ! -d ultraschall-assets ]; then
    echo "Failed to download Ultraschall REAPER Resources."
    exit
  fi
else
  echo "Updating Ultraschall REAPER Resources..."
  pushd ultraschall-assets > /dev/null || exit
  git pull >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
  popd > /dev/null || exit
fi
echo "Done."

echo "Creating installer package directories..."
if [ ! -d "$ULTRASCHALL_INSTALLER_DIR" ]; then
  mkdir "$ULTRASCHALL_INSTALLER_DIR"
fi
pushd "$ULTRASCHALL_INSTALLER_DIR" > /dev/null || exit
if [ ! -d plugins ]; then
  mkdir plugins
fi
if [ ! -d scripts ]; then
  mkdir scripts
fi
if [ ! -d themes ]; then
  mkdir themes
fi
if [ ! -d resources ]; then
  mkdir resources
fi
if [ ! -d custom-plugins ]; then
  mkdir custom-plugins
fi
if [ ! -d fonts ]; then
  mkdir fonts
fi
popd > /dev/null || exit
echo "Done."

echo "Building Ultraschall documentation files..."
# Use deprecated option '--self-contained' instead of '--embed-resources --standalone' to support outdated pandoc versions in Github Actions linux runners
$ULTRASCHALL_PANDOC_TOOL --from=markdown --to=html --self-contained --quiet --css=../installer-scripts/ultraschall.css --output="$ULTRASCHALL_INSTALLER_DIR/README.html" ultraschall-plugin/docs/README.md
$ULTRASCHALL_PANDOC_TOOL --from=markdown --to=html --self-contained --quiet --css=../installer-scripts/ultraschall.css --output="$ULTRASCHALL_INSTALLER_DIR/INSTALL.html" ultraschall-plugin/docs/INSTALL.md
$ULTRASCHALL_PANDOC_TOOL --from=markdown --to=html --self-contained --quiet --css=../installer-scripts/ultraschall.css --output="$ULTRASCHALL_INSTALLER_DIR/CHANGELOG.html" ultraschall-plugin/docs/CHANGELOG.md
echo "Done."

pushd ultraschall-plugin > /dev/null || exit
echo "Configuring Ultraschall REAPER Plug-in..."
if ! $ULTRASCHALL_CMAKE_TOOL -Bbuild -GNinja -Wno-dev -DCMAKE_BUILD_TYPE=Release --log-level=ERROR >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
then
  cat build.log
  echo "Failed to configure Ultraschall REAPER Plug-in."
  exit
fi
echo "Done."
echo "Building Ultraschall REAPER Plug-in..."
if ! $ULTRASCHALL_CMAKE_TOOL --build build --target reaper_ultraschall --config Release -j >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
then
  cat build.log
  echo "Failed to build Ultraschall REAPER Plug-in."
  exit
fi
popd > /dev/null || exit
echo "Done."

pushd ultraschall-soundboard > /dev/null || exit
echo "Configuring Ultraschall Soundboard..."
if ! $ULTRASCHALL_CMAKE_TOOL -Bbuild -GNinja -Wno-dev -DCMAKE_BUILD_TYPE=Release --log-level=ERROR >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
then
  cat build.log
  echo "Failed to configure Ultraschall Soundboard."
  exit
fi
echo "Done."
echo "Building Ultraschall Soundboard..."
if ! $ULTRASCHALL_CMAKE_TOOL --build build --target UltraschallSoundboard_VST3 --config Release -j >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
then
  cat build.log
  echo "Failed to build Ultraschall Soundboard."
  exit
fi
mkdir -p build/release
cp -R ./build/UltraschallSoundboard_artefacts/Release/VST3/Soundboard.vst3 ./build/release
popd > /dev/null || exit
echo "Done."

echo "Building ULTRASCHALL REAPER API..."
if [ ! -d ultraschall-api ]; then
  mkdir ultraschall-api
fi
if [ ! -d ultraschall-api/ultraschall_api ]; then
  mkdir ultraschall-api/ultraschall_api
fi
cp -r ultraschall-portable/UserPlugins/ultraschall_api ultraschall-api
cp ultraschall-portable/UserPlugins/ultraschall_api.lua ultraschall-api/
cp ultraschall-portable/UserPlugins/ultraschall_api_readme.txt ultraschall-api/
echo "Done."

echo "Downloading StudioLink plugin..."
#curl -LO https://download.studio.link/releases/$STUDIO_LINK_PLUGIN_RELEASE/linux/vst/studio-link-plugin.zip >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
if ! curl -LO https://download.studio.link/devel/openssl3/$STUDIO_LINK_PLUGIN_RELEASE/linux/vst/studio-link-plugin.zip >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
then
  echo "Failed to download StudioLink plugin."
  exit
fi
rm -rf studio-link-plugin.vst
if ! unzip -d studio-link-plugin.vst studio-link-plugin.zip >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
then
  echo "Failed to extract StudioLink plugin."
  exit
fi
echo "Done."

echo "Downloading StudioLink OnAir plugin..."
#curl -LO https://download.studio.link/releases/$STUDIO_LINK_PLUGIN_RELEASE/linux/studio-link-plugin-onair.zip >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
if ! curl -LO https://download.studio.link/devel/openssl3/$STUDIO_LINK_PLUGIN_RELEASE/linux/studio-link-plugin-onair.zip >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
then
  echo "Failed to download StudioLink OnAir plugin."
  exit
fi
rm -rf studio-link-onair.lv2
if ! unzip studio-link-plugin-onair.zip >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
then
  echo "Failed to extract StudioLink OnAir plugin."
  exit
fi
echo "Done."

echo "Downloading Liberation fonts..."
if ! curl -LO "https://github.com/liberationfonts/liberation-fonts/files/7261482/liberation-fonts-ttf-2.1.5.tar.gz" >> "$ULTRASCHALL_BUILD_LOG" 2>> "$ULTRASCHALL_BUILD_LOG"
then
  echo "Failed to download Liberation fonts."
  exit
fi
rm -rf liberation-fonts-ttf-2.1.5
if ! tar -xf liberation-fonts-ttf-2.1.5.tar.gz
then
  echo "Failed to extract Liberation fonts."
  exit
fi
echo "Done."

echo "Copying Liberation fonts..."
cp liberation-fonts-ttf-2.1.5/*.ttf "$ULTRASCHALL_INSTALLER_DIR/fonts"
echo "Done."

echo "Copying Ultraschall resources..."
cp ultraschall-assets/keyboard-layout/Keymap.pdf "$ULTRASCHALL_INSTALLER_DIR/resources/Ultraschall Keyboard Layout.pdf"
cp ultraschall-assets/source/us-banner_400.png "$ULTRASCHALL_INSTALLER_DIR/resources/Ultraschall Badge 400px.png"
cp ultraschall-assets/source/us-banner_800.png "$ULTRASCHALL_INSTALLER_DIR/resources/Ultraschall Badge 800px.png"
cp ultraschall-assets/source/us-banner_2000.png "$ULTRASCHALL_INSTALLER_DIR/resources/Ultraschall Badge 2000px.png"
echo "Done."

echo "Copying Ultraschall theme..."
rm -rf ultraschall-theme
cp -r ultraschall-portable ultraschall-theme

rm -rf ultraschall-theme/Plugins
rm -rf ultraschall-theme/UserPlugins
rm -f ultraschall-theme/Default_6.0.ReaperThemeZip
rm -f ultraschall-theme/reamote.exe
rm -f ultraschall-theme/ColorThemes/Default_6.0.ReaperThemeZip
rm -f ultraschall-theme/ColorThemes/Default_5.0.ReaperThemeZip
rm -f ultraschall-theme/ColorThemes/Ultraschall_3.1.ReaperThemeZip

rm -rf ultraschall-theme/TrackTemplates
cp -r ultraschall-theme/osFiles/Linux/TrackTemplates ultraschall-theme
rm -rf ultraschall-theme/ProjectTemplates
cp -r ultraschall-theme/osFiles/Linux/ProjectTemplates ultraschall-theme
rm -rf ultraschall-theme/osFiles

# patch color to fix the storyboard view
sed -i 's/col_main_text=.*/col_main_text=15790320/g' ultraschall-theme/ColorThemes/Ultraschall_5.ReaperTheme

# create libSwell config file (Linux only) and adjust menubar settings
echo "menubar_height 28" > ultraschall-theme/libSwell.colortheme
echo "menubar_font_size 15" >> ultraschall-theme/libSwell.colortheme
cp ultraschall-theme/libSwell.colortheme ultraschall-theme/libSwell-user.colortheme

# create a tar file
pushd ultraschall-theme > /dev/null || exit
tar cvf "../$ULTRASCHALL_INSTALLER_DIR/themes/ultraschall-theme.tar" ./* > /dev/null
popd > /dev/null || exit
echo "Done."

echo "Copying Ultraschall plugins..."
cp ../js-extension/reaper_js_ReaScriptAPI64.so "$ULTRASCHALL_INSTALLER_DIR/plugins/reaper_js_ReaScriptAPI64.so"
cp ../sws-extension/reaper_sws-x86_64.so "$ULTRASCHALL_INSTALLER_DIR/plugins/reaper_sws-x86_64.so"
cp ../sws-extension/sws_python64.py "$ULTRASCHALL_INSTALLER_DIR/scripts/sws_python64.py"
cp ../sws-extension/sws_python.py "$ULTRASCHALL_INSTALLER_DIR/scripts/sws_python.py"
cp -r studio-link-plugin.vst "$ULTRASCHALL_INSTALLER_DIR/custom-plugins"
cp -r studio-link-onair.lv2 "$ULTRASCHALL_INSTALLER_DIR/custom-plugins"
cp -r ultraschall-soundboard/build/release/Soundboard.vst3 "$ULTRASCHALL_INSTALLER_DIR/custom-plugins"
cp ultraschall-plugin/build/artifacts/reaper_ultraschall.so "$ULTRASCHALL_INSTALLER_DIR/plugins/reaper_ultraschall.so"
cp -R ultraschall-api/ultraschall_api/ "$ULTRASCHALL_INSTALLER_DIR/plugins/ultraschall_api/"
cp ultraschall-api/ultraschall_api.lua "$ULTRASCHALL_INSTALLER_DIR/plugins/ultraschall_api.lua"
cp ultraschall-api/ultraschall_api_readme.txt "$ULTRASCHALL_INSTALLER_DIR/plugins/ultraschall_api_readme.txt"
echo "Done."

echo "Copying install script..."
cp ../installer-scripts/install.sh "$ULTRASCHALL_INSTALLER_DIR"
chmod +x "$ULTRASCHALL_INSTALLER_DIR/install.sh"
echo "Done."

echo "Creating installer package..."
if [ -d "artifacts" ]; then
  rm -rf "artifacts"
fi
mkdir "artifacts"
if ! tar -czf "artifacts/ULTRASCHALL_$ULTRASCHALL_BUILD_ID.tar.gz" "$ULTRASCHALL_INSTALLER_DIR"
then
  echo "Failed to build final installer package."
  exit
fi
echo "Done."

popd > /dev/null || exit

exit 0
