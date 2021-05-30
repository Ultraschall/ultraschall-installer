#!/bin/bash

echo "**********************************************************************"
echo "*                                                                    *"
echo "*            BUILDING ULTRASCHALL INSTALLER PACKAGE                  *"
echo "*                                                                    *"
echo "**********************************************************************"

# Configuration
ULTRASCHALL_THREAD_COUNT=$(nproc)
ULTRASCHALL_CMAKE_TOOL=cmake
ULTRASCHALL_INSTALLER_DIR="ultraschall-installer"

ULTRASCHALL_BUILD_PRODUCT="ultraschall"
ULTRASCHALL_BUILD_VERSION="5.1"
ULTRASCHALL_BUILD_STAGE="pre-release"
ULTRASCHALL_BUILD_PLATFORM="macos"
ULTRASCHALL_BUILD_DATE=$(date -u "+%Y%m%dT%H%M%S")Z
ULTRASCHALL_BUILD_ID=$(uuidgen)

ULTRASCHALL_BUILD_BOOTSTRAP=0
ULTRASCHALL_BUILD_CLEAN=0
ULTRASCHALL_BUILD_RELEASE=0
ULTRASCHALL_BUILD_CODESIGN=0
ULTRASCHALL_BUILD_UPDATE=0

ULTRASCHALL_ROOT_DIRECTORY=$('pwd')
ULTRASCHALL_RESOURCES_DIRECTORY="$ULTRASCHALL_ROOT_DIRECTORY/installer-resources"
ULTRASCHALL_SCRIPTS_DIRECTORY="$ULTRASCHALL_ROOT_DIRECTORY/installer-scripts"
ULTRASCHALL_BUILD_DIRECTORY="$ULTRASCHALL_ROOT_DIRECTORY/build"
ULTRASCHALL_TOOLS_DIRECTORY="$ULTRASCHALL_BUILD_DIRECTORY/tools"
ULTRASCHALL_PAYLOAD_DIRECTORY="$ULTRASCHALL_BUILD_DIRECTORY/payload"

PANDOC_PACKAGE_URL="https://github.com/jgm/pandoc/releases/download/2.9.1.1/pandoc-2.9.1.1-linux-amd64.tar.gz"
ULTRASCHALL_PLUGIN_URL="https://github.com/Ultraschall/ultraschall-plugin.git"
ULTRASCHALL_SOUNDBOARD_URL="https://github.com/Ultraschall/ultraschall-soundboard.git"
ULTRASCHALL_PORTABLE_URL="https://github.com/Ultraschall/ultraschall-portable.git"
ULTRASCHALL_ASSETS_URL="https://github.com/Ultraschall/ultraschall-assets.git"

STUDIO_LINK_PLUGIN_RELEASE=v21.03.2-stable

if [ "$1" = "--help" ]; then
  echo "Usage: build.sh [ --release ]"
  exit 0
elif [ "$1" = "--release" ]; then
  ULTRASCHALL_BUILD_RELEASE=1
fi

SOURCE_BRANCH='develop'
if [ $ULTRASCHALL_BUILD_RELEASE = 1 ]; then
  SOURCE_BRANCH='master'
fi

echo "Building installer from $SOURCE_BRANCH branch..."

# Specify build id
if [ $ULTRASCHALL_BUILD_RELEASE = 1 ]; then
  ULTRASCHALL_BUILD_ID='R5.0.3'
else
  ULTRASCHALL_BUILD_ID='R5.1.0alpha1'
fi

# Specify build directory
ULTRASCHALL_BUILD_DIRECTORY='./build'

# Create folder for intermediate data
if [ ! -d $ULTRASCHALL_BUILD_DIRECTORY ]; then
  mkdir $ULTRASCHALL_BUILD_DIRECTORY
fi

pushd $ULTRASCHALL_BUILD_DIRECTORY > /dev/null

if [ ! -d pandoc-tool ]; then
  echo "Downloading Pandoc Universal Markup Converter..."
  mkdir pandoc-tool && pushd pandoc-tool > /dev/null
  curl -L -o pandoc.tar.gz $PANDOC_PACKAGE_URL
  if [ $? -ne 0 ]; then
    echo "Failed to download Pandoc Universal Markup Converter."
    exit -1
  fi
  mkdir pandoc
  tar xvf pandoc.tar.gz --directory pandoc --strip-components=1
  if [ $? -ne 0 ]; then
    echo "Failed to install Pandoc Universal Markup Converter."
    exit -1
  else
    rm pandoc.tar.gz
  fi

  popd > /dev/null
  echo "Done."
fi

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

if [ ! -d ultraschall-portable ]; then
  echo "Downloading Ultraschall REAPER API..."
  git clone --branch master --depth 1 $ULTRASCHALL_PORTABLE_URL ultraschall-portable
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

echo "Creating installer package directories..."
if [ ! -d ultraschall-installer ]; then
  mkdir ultraschall-installer
fi
pushd ultraschall-installer > /dev/null
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
popd
echo "Done."

echo "Building Ultraschall documentation files..."
pandoc-tool/pandoc/bin/pandoc --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output=ultraschall-installer/README.html ultraschall-plugin/docs/README.md
pandoc-tool/pandoc/bin/pandoc --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output=ultraschall-installer/INSTALL.html ultraschall-plugin/docs/INSTALL.md
pandoc-tool/pandoc/bin/pandoc --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output=ultraschall-installer/CHANGELOG.html ultraschall-plugin/docs/CHANGELOG.md
echo "Done."

echo "Building Ultraschall REAPER Plug-in"
pushd ultraschall-plugin > /dev/null

if [ ! -d build ]; then
 mkdir build
fi
pushd build > /dev/null
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release ../
if [ $? -ne 0 ]; then
  echo "Failed to configure Ultraschall REAPER Plug-in."
  exit -1
fi
cmake --build . --target reaper_ultraschall --config Release -j $ULTRASCHALL_THREAD_COUNT
if [ $? -ne 0 ]; then
  echo "Failed to build Ultraschall REAPER Plug-in."
  exit -1
fi
popd > /dev/null
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

pushd ultraschall-soundboard > /dev/null
echo "Configuring Ultraschall Soundboard..."
$ULTRASCHALL_CMAKE_TOOL -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release --log-level=ERROR 2> build.log
if [ $? -ne 0 ]; then
  echo "Failed to configure Ultraschall Soundboard."
  exit -1
fi
echo "Done."
echo "Building Ultraschall Soundboard..."
$ULTRASCHALL_CMAKE_TOOL --build build --target UltraschallSoundboard_VST3 --config Release -j $ULTRASCHALL_THREAD_COUNT 2>> build.log
if [ $? -ne 0 ]; then
  echo "Failed to build Ultraschall Soundboard."
  exit -1
fi
mkdir -p build/release
cp -R ./build/UltraschallSoundboard_artefacts/Release/VST3/Soundboard.vst3 ./build/release
cp -R ./build
popd > /dev/null
echo "Done."

echo "Fetching StudioLink LV2 plugin"
curl https://download.studio.link/releases/$STUDIO_LINK_PLUGIN_RELEASE/linux/studio-link-plugin.zip -o studio-link-plugin.zip
rm -rf studio-link.lv2
unzip studio-link-plugin.zip

echo "Fetching StudioLink OnAir plugin"
curl https://download.studio.link/releases/$STUDIO_LINK_PLUGIN_RELEASE/linux/studio-link-plugin-onair.zip -o studio-link-plugin-onair.zip
rm -rf studio-link-onair.lv2
unzip studio-link-plugin-onair.zip

echo "Copying Ultraschall resources..."
cp ultraschall-assets/keyboard-layout/Keymap.pdf "ultraschall-installer/resources/Ultraschall Keyboard Layout.pdf"
cp ultraschall-assets/source/us-banner_400.png "ultraschall-installer/resources/Ultraschall Badge 400px.png"
cp ultraschall-assets/source/us-banner_800.png "ultraschall-installer/resources/Ultraschall Badge 800px.png"
cp ultraschall-assets/source/us-banner_2000.png "ultraschall-installer/resources/Ultraschall Badge 2000px.png"
echo "Done."

echo "Copying Ultraschall themes..."
cp -r ultraschall-portable/ ultraschall-theme
rm -rf ultraschall-theme/Plugins
rm -rf ultraschall-theme/UserPlugins
rm -f ultraschall-theme/Default_6.0.ReaperThemeZip
rm -f ultraschall-theme/reamote.exe
rm -f ultraschall-theme/ColorThemes/Default_6.0.ReaperThemeZip
rm -f ultraschall-theme/ColorThemes/Default_5.0.ReaperThemeZip
rm -f ultraschall-theme/ColorThemes/Ultraschall_3.1.ReaperThemeZip
rm -rf ultraschall-theme/osFiles
# create a tar file
pushd ultraschall-theme > /dev/null
tar cvf ../ultraschall-installer/themes/ultraschall-theme.tar *
popd > /dev/null
echo "Done."

echo "Copying Ultraschall plugins..."
cp ../js-extension/reaper_js_ReaScriptAPI64.so ultraschall-installer/plugins/reaper_js_ReaScriptAPI64.so
cp ../sws-extension/reaper_sws-x86_64.so ultraschall-installer/plugins/reaper_sws-x86_64.so
cp ../sws-extension/sws_python64.py ultraschall-installer/scripts/sws_python64.py
cp ../sws-extension/sws_python.py ultraschall-installer/scripts/sws_python.py
cp -r studio-link.lv2 ultraschall-installer/custom-plugins
cp -r studio-link-onair.lv2 ultraschall-installer/custom-plugins
cp -r ultraschall-soundboard/build/release/Soundboard.vst3 ultraschall-installer/custom-plugins
cp ultraschall-plugin/build/src/reaper_ultraschall.so ultraschall-installer/plugins/reaper_ultraschall.so
cp -R ultraschall-api/ultraschall_api/ ultraschall-installer/plugins/ultraschall_api/
cp ultraschall-api/ultraschall_api.lua ultraschall-installer/plugins/ultraschall_api.lua
cp ultraschall-api/ultraschall_api_readme.txt ultraschall-installer/plugins/ultraschall_api_readme.txt
echo "Done."

echo "Copying install script..."
cp ../installer-scripts/install.sh ultraschall-installer
chmod +x ultraschall-installer/install.sh
echo "Done."

echo "Creating installer package..."
tar -czf "../Ultraschall_$ULTRASCHALL_BUILD_ID.tar.gz" ultraschall-installer
if [ $? -ne 0 ]; then
  echo "Failed to build final installer package."
  exit -1
fi
echo "Done."

popd > /dev/null
exit 0
