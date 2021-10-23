#!/bin/bash

echo "**********************************************************************"
echo "*                                                                    *"
echo "*            BUILDING ULTRASCHALL INSTALLER PACKAGE                  *"
echo "*                                                                    *"
echo "**********************************************************************"

# Configuration
ULTRASCHALL_THREAD_COUNT=$(nproc)
ULTRASCHALL_CMAKE_TOOL=cmake
ULTRASCHALL_PANDOC_TOOL=pandoc

ULTRASCHALL_BUILD_PRODUCT="ultraschall"
ULTRASCHALL_BUILD_VERSION="5.1"
ULTRASCHALL_BUILD_DATE=$(date -u "+%Y%m%dT%H%M%S")Z
ULTRASCHALL_BUILD_ID=$(uuidgen)

ULTRASCHALL_BUILD_RELEASE=0

ULTRASCHALL_ROOT_DIRECTORY=$(pwd)
ULTRASCHALL_BUILD_DIRECTORY="$ULTRASCHALL_ROOT_DIRECTORY/build"

ULTRASCHALL_PLUGIN_URL="https://github.com/Ultraschall/ultraschall-plugin.git"
ULTRASCHALL_SOUNDBOARD_URL="https://github.com/Ultraschall/ultraschall-soundboard.git"
# ULTRASCHALL_PORTABLE_URL="https://github.com/Ultraschall/ultraschall-portable.git"
ULTRASCHALL_PORTABLE_URL="https://github.com/nethad/ultraschall-portable.git"
ULTRASCHALL_PORTABLE_BRANCH="linux-project-and-track-templates"
ULTRASCHALL_ASSETS_URL="https://github.com/Ultraschall/ultraschall-assets.git"

STUDIO_LINK_PLUGIN_RELEASE=v21.07.0-stable

if [ "$1" = "--help" ]; then
  echo "Usage: build.sh [ --release ]"
  exit 0
elif [ "$1" = "--release" ]; then
  ULTRASCHALL_BUILD_RELEASE=1
fi

echo "Checking whether required software packages are installed..."
ULTRASCHALL_DEPENDENCIES="cmake pandoc ninja-build libxrandr-dev libxinerama-dev libxcursor-dev libasound2-dev"
dpkg -l $ULTRASCHALL_DEPENDENCIES > /dev/null
if [ $? -ne 0 ]; then
  echo "Dependency check failed, required packages:"
  echo "$ULTRASCHALL_DEPENDENCIES"
  exit -1
fi
echo "Done."

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

# Create folder for intermediate data
if [ ! -d $ULTRASCHALL_BUILD_DIRECTORY ]; then
  mkdir $ULTRASCHALL_BUILD_DIRECTORY
fi

pushd $ULTRASCHALL_BUILD_DIRECTORY > /dev/null

if [ ! -d ultraschall-plugin ]; then
  echo "Downloading Ultraschall REAPER Plug-in..."
  git clone --branch $SOURCE_BRANCH --depth 1 $ULTRASCHALL_PLUGIN_URL ultraschall-plugin
  if [ ! -d ultraschall-plugin ]; then
    echo "Failed to download Ultraschall REAPER Plug-in."
    exit -1
  fi
else
  echo "Updating Ultraschall REAPER Plug-in..."
  pushd ultraschall-plugin > /dev/null
  git pull
  popd > /dev/null
fi
echo "Done."

if [ ! -d ultraschall-soundboard ]; then
  echo "Downloading Ultraschall Soundboard..."
  git clone --branch main --depth 1 $ULTRASCHALL_SOUNDBOARD_URL ultraschall-soundboard
  if [ ! -d ultraschall-soundboard ]; then
    echo "Failed to download Ultraschall Soundboard."
    exit -1
  fi
else
  echo "Updating Ultraschall Soundboard..."
  pushd ultraschall-soundboard > /dev/null
  git pull
  popd > /dev/null
fi
echo "Done."

if [ ! -d ultraschall-portable ]; then
  echo "Downloading Ultraschall REAPER API..."
  git clone --branch $ULTRASCHALL_PORTABLE_BRANCH --depth 1 $ULTRASCHALL_PORTABLE_URL ultraschall-portable
  if [ ! -d ultraschall-portable ]; then
    echo "Failed to download Ultraschall REAPER API."
    exit -1
  fi
else
  echo "Updating Ultraschall REAPER API..."
  pushd ultraschall-portable > /dev/null
  git pull
  popd > /dev/null
fi
echo "Done."

if [ ! -d ultraschall-assets ]; then
  echo "Downloading Ultraschall REAPER Resources..."
  git clone $ULTRASCHALL_ASSETS_URL ultraschall-assets
  if [ ! -d ultraschall-assets ]; then
    echo "Failed to download Ultraschall REAPER Resources."
    exit -1
  fi
else
  echo "Updating Ultraschall REAPER Resources..."
  pushd ultraschall-assets > /dev/null
  git pull
  popd > /dev/null
fi
echo "Done."

echo "Creating installer package directories..."
if [ ! -d "$ULTRASCHALL_INSTALLER_DIR" ]; then
  mkdir "$ULTRASCHALL_INSTALLER_DIR"
fi
pushd "$ULTRASCHALL_INSTALLER_DIR" > /dev/null
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
popd > /dev/null
echo "Done."

echo "Building Ultraschall documentation files..."
$ULTRASCHALL_PANDOC_TOOL --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output="$ULTRASCHALL_INSTALLER_DIR/README.html" ultraschall-plugin/docs/README.md
$ULTRASCHALL_PANDOC_TOOL --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output="$ULTRASCHALL_INSTALLER_DIR/INSTALL.html" ultraschall-plugin/docs/INSTALL.md
$ULTRASCHALL_PANDOC_TOOL --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output="$ULTRASCHALL_INSTALLER_DIR/CHANGELOG.html" ultraschall-plugin/docs/CHANGELOG.md
echo "Done."

pushd ultraschall-plugin > /dev/null
echo "Building Ultraschall REAPER Plug-in..."
$ULTRASCHALL_CMAKE_TOOL -B build -G Ninja -DCMAKE_BUILD_TYPE=Release --log-level=ERROR 2> build.log
if [ $? -ne 0 ]; then
  cat build.log
  echo "Failed to configure Ultraschall REAPER Plug-in."
  exit -1
fi
$ULTRASCHALL_CMAKE_TOOL --build build --target reaper_ultraschall --config Release -j $ULTRASCHALL_THREAD_COUNT 2>> build.log
if [ $? -ne 0 ]; then
  cat build.log
  echo "Failed to build Ultraschall REAPER Plug-in."
  exit -1
fi
popd > /dev/null
echo "Done."

pushd ultraschall-soundboard > /dev/null
echo "Configuring Ultraschall Soundboard..."
$ULTRASCHALL_CMAKE_TOOL -B build -G Ninja -DCMAKE_BUILD_TYPE=Release --log-level=ERROR 2> build.log
if [ $? -ne 0 ]; then
  cat build.log
  echo "Failed to configure Ultraschall Soundboard."
  exit -1
fi
echo "Done."
echo "Building Ultraschall Soundboard..."
$ULTRASCHALL_CMAKE_TOOL --build build --target UltraschallSoundboard_VST3 --config Release -j $ULTRASCHALL_THREAD_COUNT 2>> build.log
if [ $? -ne 0 ]; then
  cat build.log
  echo "Failed to build Ultraschall Soundboard."
  exit -1
fi
mkdir -p build/release
cp -R ./build/UltraschallSoundboard_artefacts/Release/VST3/Soundboard.vst3 ./build/release
popd > /dev/null
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

echo "Fetching StudioLink plugin"
curl https://download.studio.link/releases/$STUDIO_LINK_PLUGIN_RELEASE/linux/vst/studio-link-plugin.zip -o studio-link-plugin.zip
rm -rf studio-link-plugin.vst
unzip -d studio-link-plugin.vst studio-link-plugin.zip

echo "Fetching StudioLink OnAir plugin"
curl https://download.studio.link/releases/$STUDIO_LINK_PLUGIN_RELEASE/linux/studio-link-plugin-onair.zip -o studio-link-plugin-onair.zip
rm -rf studio-link-onair.lv2
unzip studio-link-plugin-onair.zip

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

# create a tar file
pushd ultraschall-theme > /dev/null
tar cvf "../$ULTRASCHALL_INSTALLER_DIR/themes/ultraschall-theme.tar" * > /dev/null
popd > /dev/null
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
tar -czf "artifacts/ULTRASCHALL_$ULTRASCHALL_BUILD_ID.tar.gz" "$ULTRASCHALL_INSTALLER_DIR"
if [ $? -ne 0 ]; then
  echo "Failed to build final installer package."
  exit -1
fi
echo "Done."

popd > /dev/null

exit 0
