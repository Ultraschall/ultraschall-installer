#!/bin/sh

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

ULTRASCHALL_BUILD_PRODUCT="ultraschall"
ULTRASCHALL_BUILD_VERSION="5.0.0"
ULTRASCHALL_BUILD_STAGE="pre-release"
ULTRASCHALL_BUILD_PLATFORM="macos"
ULTRASCHALL_BUILD_DATE=$(date -ju "+%Y%m%dT%H%M%S")Z
ULTRASCHALL_BUILD_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

ULTRASCHALL_BUILD_BOOTSTRAP=0
ULTRASCHALL_BUILD_CLEAN=0
ULTRASCHALL_BUILD_ALL=0
ULTRASCHALL_BUILD_RELEASE=0
ULTRASCHALL_BUILD_CODESIGN=0
ULTRASCHALL_BUILD_UPDATE=0

ULTRASCHALL_ROOT_DIRECTORY=$('pwd')
ULTRASCHALL_RESOURCES_DIRECTORY="$ULTRASCHALL_ROOT_DIRECTORY/installer-resources"
ULTRASCHALL_SCRIPTS_DIRECTORY="$ULTRASCHALL_ROOT_DIRECTORY/installer-scripts"
ULTRASCHALL_BUILD_DIRECTORY="$ULTRASCHALL_ROOT_DIRECTORY/build"
ULTRASCHALL_TOOLS_DIRECTORY="$ULTRASCHALL_BUILD_DIRECTORY/tools"
ULTRASCHALL_PAYLOAD_DIRECTORY="$ULTRASCHALL_BUILD_DIRECTORY/payload"

ULTRASCHALL_PLUGIN_URL="https://github.com/Ultraschall/ultraschall-plugin.git"
ULTRASCHALL_PLUGIN_BRANCH="<Unknown>"
ULTRASCHALL_PLUGIN_COMMIT="<Unknown>"
ULTRASCHALL_PORTABLE_URL="https://github.com/Ultraschall/ultraschall-portable.git"
ULTRASCHALL_PORTABLE_BRANCH="<Unknown>"
ULTRASCHALL_PORTABLE_COMMIT="<Unknown>"
ULTRASCHALL_STREAMDECK_URL="https://github.com/Ultraschall/ultraschall-stream-deck-plugin.git"
ULTRASCHALL_STREAMDECK_BRANCH="<Unknown>"
ULTRASCHALL_STREAMDECK_COMMIT="<Unknown>"
ULTRASCHALL_ASSETS_URL="https://github.com/Ultraschall/ultraschall-assets.git"
ULTRASCHALL_ASSETS_BRANCH="<Unknown>"
ULTRASCHALL_ASSETS_COMMIT="<Unknown>"

for arg in "$@"
do
case $arg in
    "-a"|"--all")
    ULTRASCHALL_BUILD_ALL=1
    shift # past argument
    ;;
    "-b"|"--bootstrap")
    ULTRASCHALL_BUILD_BOOTSTRAP=1
    shift # past argument
    ;;
    "-c"|"--clean")
    ULTRASCHALL_BUILD_CLEAN=1
    shift # past argument
    ;;
    "-h"|"--help")
    echo "Usage: build.sh [Options]"
    echo ""
    echo "Options:"
    echo "  -a|--all        Use with --clean to remove the build tools as well"
    echo "  -b|--bootstrap  Reinitialize build tools and build targets"
    echo "  -c|--clean      Delete intermediate build targets"
    echo "  -h|--help       Print this help screen"
    echo "  -r|--release    Build release version"
    echo "  -s|--sign       Code-sign executables and installer"
    echo "  -u|--update     Reinitialize build targets"
    echo ""
    exit 0
    shift # past argument
    ;;
    "-r"|"--release")
    ULTRASCHALL_BUILD_RELEASE=1
    shift # past argument
    ;;
    "-s"|"--sign")
    ULTRASCHALL_BUILD_CODESIGN=1
    shift # past argument
    ;;
    "-u"|"--update")
    ULTRASCHALL_BUILD_UPDATE=1
    shift # past argument
    ;;
    *)    # unknown option
    echo "Unknown option $arg"
    exit 1
    shift # past argument
    ;;
esac
done

# Delete intermediate build targets and exit
if [ $ULTRASCHALL_BUILD_CLEAN -eq 1 ]; then
  if [ -d $ULTRASCHALL_PAYLOAD_DIRECTORY ]; then
    rm -rf $ULTRASCHALL_PAYLOAD_DIRECTORY
  fi
  if [ $ULTRASCHALL_BUILD_ALL -eq 1 ]; then
    if [ -d $ULTRASCHALL_TOOLS_DIRECTORY ]; then
      rm -rf $ULTRASCHALL_TOOLS_DIRECTORY
    fi
    rm -rf $ULTRASCHALL_BUILD_DIRECTORY
  fi
  exit 0
fi

# Reinit build tools and targets
if [ $ULTRASCHALL_BUILD_BOOTSTRAP -eq 1 ]; then
  if [ -d $ULTRASCHALL_PAYLOAD_DIRECTORY ]; then
    rm -rf $ULTRASCHALL_PAYLOAD_DIRECTORY
  fi
  if [ -d $ULTRASCHALL_TOOLS_DIRECTORY ]; then
    rm -rf $ULTRASCHALL_TOOLS_DIRECTORY
  fi
fi

# Reinit build targets
if [ $ULTRASCHALL_BUILD_UPDATE -eq 1 ]; then
  if [ -d $ULTRASCHALL_PAYLOAD_DIRECTORY ]; then
    rm -rf $ULTRASCHALL_PAYLOAD_DIRECTORY
  fi
fi

echo "**********************************************************************"
echo "*                                                                    *"
echo "*            BUILDING ULTRASCHALL INSTALLER PACKAGE                  *"
echo "*                                                                    *"
echo "**********************************************************************"

# Create folder for intermediate data
if [ ! -d $ULTRASCHALL_BUILD_DIRECTORY ]; then
  mkdir $ULTRASCHALL_BUILD_DIRECTORY
fi

# Enter build directory
pushd $ULTRASCHALL_BUILD_DIRECTORY > /dev/null

if [ ! -d $ULTRASCHALL_TOOLS_DIRECTORY ]; then
  mkdir -p $ULTRASCHALL_TOOLS_DIRECTORY
fi

ULTRASCHALL_PANDOC_TOOL="$ULTRASCHALL_TOOLS_DIRECTORY/pandoc-2.11.1.1/bin/pandoc"
ULTRASCHALL_CMAKE_TOOL="$ULTRASCHALL_TOOLS_DIRECTORY/cmake-3.19.6-macos-universal/CMake.app/Contents/bin/cmake"

if [ -d $ULTRASCHALL_TOOLS_DIRECTORY ]; then
  pushd $ULTRASCHALL_TOOLS_DIRECTORY > /dev/null

  if [ ! -d "$ULTRASCHALL_TOOLS_DIRECTORY/cmake-3.19.6-macos-universal" ]; then
    echo "Downloading cmake..."
    curl -LO "https://github.com/Kitware/CMake/releases/download/v3.19.6/cmake-3.19.6-macos-universal.tar.gz"
    if [ $? -ne 0 ]; then
      echo "Failed to download cmake."
      exit -1
    fi
    tar xvzf "cmake-3.19.6-macos-universal.tar.gz";
    if [ $? -ne 0 ]; then
      echo "Failed to install cmake."
      exit -1
    fi
    if [ -f "cmake-3.19.6-macos-universal.tar.gz" ]; then
      rm -f "cmake-3.19.6-macos-universal.tar.gz"
    fi
  fi

  if [ ! -d "$ULTRASCHALL_TOOLS_DIRECTORY/pandoc-2.11.1.1" ]; then
    echo "Downloading pandoc..."
    curl -LO "https://github.com/jgm/pandoc/releases/download/2.11.1.1/pandoc-2.11.1.1-macOS.zip"
    if [ $? -ne 0 ]; then
      echo "Failed to download pandoc."
      exit -1
    fi
    unzip "pandoc-2.11.1.1-macOS.zip";
    if [ $? -ne 0 ]; then
      echo "Failed to install pandoc."
      exit -1
    fi
    if [ -f "pandoc-2.11.1.1-macOS.zip" ]; then
      rm -f "pandoc-2.11.1.1-macOS.zip"
    fi
  fi
  popd > /dev/null
  echo "Done."
fi

ULTRASCHALL_PAYLOAD_DIRECTORY="$ULTRASCHALL_BUILD_DIRECTORY/payload"
if [ ! -d $ULTRASCHALL_PAYLOAD_DIRECTORY ]; then
  mkdir -p $ULTRASCHALL_PAYLOAD_DIRECTORY
fi

if [ -d $ULTRASCHALL_PAYLOAD_DIRECTORY ]; then
  pushd $ULTRASCHALL_PAYLOAD_DIRECTORY > /dev/null

  if [ ! -d ultraschall-plugin ]; then
    echo "Downloading Ultraschall REAPER Plug-in..."
    git clone --branch main --depth 1 $ULTRASCHALL_PLUGIN_URL ultraschall-plugin
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
  pushd ultraschall-plugin > /dev/null
  ULTRASCHALL_PLUGIN_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  ULTRASCHALL_PLUGIN_COMMIT=$(git rev-parse HEAD)
  ULTRASCHALL_BUILD_TAG="ULTRASCHALL_$(git describe --tags)"
  popd > /dev/null
  echo "Done."

  if [ ! -d ultraschall-portable ]; then
    echo "Downloading Ultraschall REAPER Theme & API..."
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
  pushd ultraschall-portable > /dev/null
  chmod -R u+rw .
  ULTRASCHALL_PORTABLE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  ULTRASCHALL_PORTABLE_COMMIT=$(git rev-parse HEAD)
  popd > /dev/null
  echo "Done."

  if [ ! -d ultraschall-assets ]; then
    echo "Downloading Ultraschall REAPER Resources..."
    git clone --branch master --depth 1 $ULTRASCHALL_ASSETS_URL ultraschall-assets
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

  pushd ultraschall-assets > /dev/null
  ULTRASCHALL_ASSETS_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  ULTRASCHALL_ASSETS_COMMIT=$(git rev-parse HEAD)
  popd > /dev/null

  if [ ! -d ultraschall-streamdeck ]; then
    echo "Downloading Ultraschall REAPER Stream Deck Plug-in..."
    git clone --branch master $ULTRASCHALL_STREAMDECK_URL ultraschall-streamdeck
    if [ ! -d ultraschall-streamdeck ]; then
      echo "Failed to download Ultraschall REAPER Stream Deck Plug-in."
      exit -1
    fi
  else
    echo "Updating Ultraschall REAPER Stream Deck Plug-in..."
    pushd ultraschall-streamdeck > /dev/null
    git pull
    popd > /dev/null
  fi
  echo "Done."

  pushd ultraschall-streamdeck > /dev/null
  ULTRASCHALL_STREAMDECK_TAG="$(git describe --tags)"
  ULTRASCHALL_STREAMDECK_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  ULTRASCHALL_STREAMDECK_COMMIT=$(git rev-parse HEAD)
  echo "Downloading release $ULTRASCHALL_STREAMDECK_TAG..."
  curl -LO "https://github.com/Ultraschall/ultraschall-stream-deck-plugin/releases/download/$ULTRASCHALL_STREAMDECK_TAG/fm.ultraschall.ultradeck.streamDeckPlugin"
  if [ $? -ne 0 ]; then
    echo "Failed to download release $ULTRASCHALL_STREAMDECK_TAG."
    exit -1
  fi
  echo "Done."
  popd > /dev/null

  echo "Creating installer root directory..."
  if [ -d installer-root ]; then
    rm -rf installer-root
  fi
  mkdir -p installer-root
  echo "Done."

  echo "Copying installer background image..."
  if [ ! -d installer-root/.background ]; then
    mkdir installer-root/.background
  fi
  cp $ULTRASCHALL_RESOURCES_DIRECTORY/image-background.png installer-root/.background/background.png
  echo "Done."

  echo "Building Ultraschall documentation files..."
  $ULTRASCHALL_PANDOC_TOOL --from=markdown --to=html --standalone --self-contained --quiet --css=$ULTRASCHALL_SCRIPTS_DIRECTORY/ultraschall.css --output=installer-root/README.html ultraschall-plugin/docs/README.md
  $ULTRASCHALL_PANDOC_TOOL --from=markdown --to=html --standalone --self-contained --quiet --css=$ULTRASCHALL_SCRIPTS_DIRECTORY/ultraschall.css --output=installer-root/INSTALL.html ultraschall-plugin/docs/INSTALL.md
  $ULTRASCHALL_PANDOC_TOOL --from=markdown --to=html --standalone --self-contained --quiet --css=$ULTRASCHALL_SCRIPTS_DIRECTORY/ultraschall.css --output=installer-root/CHANGELOG.html ultraschall-plugin/docs/CHANGELOG.md
  echo "Done."

  echo "Copying utility scripts..."
  cp $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-scripts/Uninstall.command installer-root/Uninstall.command
  echo "Done."

  echo "Copying Ultraschall Extras..."
  if [ ! -d installer-root/Extras ]; then
    mkdir installer-root/Extras
  fi
  cp ultraschall-assets/keyboard-layout/Keymap.pdf "installer-root/Extras/Ultraschall Keyboard Layout.pdf"
  cp ultraschall-assets/source/us-banner_400.png "installer-root/Extras/Ultraschall Badge 400px.png"
  cp ultraschall-assets/source/us-banner_800.png "installer-root/Extras/Ultraschall Badge 800px.png"
  cp ultraschall-assets/source/us-banner_2000.png "installer-root/Extras/Ultraschall Badge 2000px.png"
  cp ultraschall-assets/images/Ultraschall-4-Logo.png "installer-root/Extras/Ultraschall-4-Logo.png"
  echo "Done."

  echo "Copying Ultraschall Utilities..."
  if [ ! -d installer-root/Utilities ]; then
    mkdir installer-root/Utilities
  fi
  cp $ULTRASCHALL_PAYLOAD_DIRECTORY/ultraschall-streamdeck/fm.ultraschall.ultradeck.streamDeckPlugin "installer-root/Utilities/fm.ultraschall.ultradeck.streamDeckPlugin"
  cp $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-hub/UltraschallHub-2015-11-12.pkg "installer-root/Utilities/Ultraschall Hub.pkg"
  cp "$ULTRASCHALL_ROOT_DIRECTORY/ultraschall-scripts/Remove legacy audio devices.command" "installer-root/Utilities/Remove legacy audio devices.command"
  echo "Done."

  echo "Building Ultraschall REAPER Plug-in"
  pushd ultraschall-plugin > /dev/null

  if [ ! -d build ]; then
    mkdir build
  fi
  pushd build > /dev/null
  $ULTRASCHALL_CMAKE_TOOL -G"Unix Makefiles" -Wno-dev -DCMAKE_BUILD_TYPE=Release ../
  if [ $? -ne 0 ]; then
    echo "Failed to configure Ultraschall REAPER Plug-in."
    exit -1
  fi
  $ULTRASCHALL_CMAKE_TOOL --build . --target reaper_ultraschall --config Release -j $(nproc --all)
  if [ $? -ne 0 ]; then
    echo "Failed to build Ultraschall REAPER Plug-in."
    exit -1
  fi
  mkdir -p release
  cp ./src/reaper_ultraschall.dylib release/
  popd > /dev/null
  popd > /dev/null
  echo "Done."

  if [ $ULTRASCHALL_BUILD_CODESIGN -eq 1 ]; then
    echo "Signing ULTRASCHALL REAPER Plug-in..."
    codesign --force --sign "Developer ID Application: Heiko Panjas (8J2G689FCZ)" ultraschall-plugin/build/release/reaper_ultraschall.dylib
    if [ $? -ne 0 ]; then
      echo "Failed to sign ULTRASCHALL REAPER Plug-in."
      exit -1
    fi
    echo "Done."
  fi

  echo "Building ULTRASCHALL REAPER API..."
  if [ ! -d ultraschall-api ]; then
    mkdir ultraschall-api
  fi
  if [ ! -d ultraschall-api/ultraschall_api ]; then
    mkdir ultraschall-api/ultraschall_api
  fi
  cp -r ultraschall-portable/UserPlugins/ultraschall_api ultraschall-api
  cp ultraschall-portable/UserPlugins/ultraschall_api.lua ultraschall-api/
  echo "Done."

  echo "Building ULTRASCHALL REAPER Theme..."
  if [ ! -d ultraschall-theme ]; then
    mkdir ultraschall-theme
  fi
  cp -r ultraschall-portable/ ultraschall-theme
  rm -rf ultraschall-theme/Plugins
  rm -rf ultraschall-theme/UserPlugins
  rm -f ultraschall-theme/Default_6.0.ReaperThemeZip
  rm -f ultraschall-theme/reamote.exe
  rm -f ultraschall-theme/ColorThemes/Default_6.0.ReaperThemeZip
  rm -f ultraschall-theme/ColorThemes/Default_5.0.ReaperThemeZip
  rm -f ultraschall-theme/ColorThemes/Ultraschall_3.1.ReaperThemeZip

  # ----------------------------------------------------------------------
  # FIXME Still required by Ultraschall 5
  # rm -f ultraschall-theme/ColorThemes/Ultraschall_3.1.ReaperTheme
  # ----------------------------------------------------------------------

  echo "Done."

  echo "Creating Bill of Materials..."
  ULTRASCHALL_BOM_NAME="ultraschall-theme/$ULTRASCHALL_BUILD_TAG.yml"

  if [ $ULTRASCHALL_BUILD_RELEASE -eq 1 ]; then
    ULTRASCHALL_BUILD_STAGE="release"
  fi

  echo "products:" > $ULTRASCHALL_BOM_NAME
  echo "  name: $ULTRASCHALL_BUILD_PRODUCT" >> $ULTRASCHALL_BOM_NAME
  echo "  version: $ULTRASCHALL_BUILD_VERSION" >> $ULTRASCHALL_BOM_NAME
  echo "  platform: $ULTRASCHALL_BUILD_PLATFORM" >> $ULTRASCHALL_BOM_NAME
  echo "  stage: $ULTRASCHALL_BUILD_STAGE" >> $ULTRASCHALL_BOM_NAME
  echo "  timestamp: $ULTRASCHALL_BUILD_DATE" >> $ULTRASCHALL_BOM_NAME
  echo "  id: $ULTRASCHALL_BUILD_ID" >> $ULTRASCHALL_BOM_NAME
  echo "  assets:" >> $ULTRASCHALL_BOM_NAME
  echo "    - name: ultraschall-portable" >> $ULTRASCHALL_BOM_NAME
  echo "      url:    $ULTRASCHALL_PORTABLE_URL" >> $ULTRASCHALL_BOM_NAME
  echo "      branch: $ULTRASCHALL_PORTABLE_BRANCH" >> $ULTRASCHALL_BOM_NAME
  echo "      commit: $ULTRASCHALL_PORTABLE_COMMIT" >> $ULTRASCHALL_BOM_NAME
  echo "    - name: ultraschall-plugin" >> $ULTRASCHALL_BOM_NAME
  echo "      url:    $ULTRASCHALL_PLUGIN_URL" >> $ULTRASCHALL_BOM_NAME
  echo "      branch: $ULTRASCHALL_PLUGIN_BRANCH" >> $ULTRASCHALL_BOM_NAME
  echo "      commit: $ULTRASCHALL_PLUGIN_COMMIT" >> $ULTRASCHALL_BOM_NAME
  echo "    - name: ultraschall-stream-deck-plugin" >> $ULTRASCHALL_BOM_NAME
  echo "      url:    $ULTRASCHALL_STREAMDECK_URL" >> $ULTRASCHALL_BOM_NAME
  echo "      branch: $ULTRASCHALL_STREAMDECK_BRANCH" >> $ULTRASCHALL_BOM_NAME
  echo "      commit: $ULTRASCHALL_STREAMDECK_COMMIT" >> $ULTRASCHALL_BOM_NAME
  echo "    - name: ultraschall-assets" >> $ULTRASCHALL_BOM_NAME
  echo "      url:    $ULTRASCHALL_ASSETS_URL" >> $ULTRASCHALL_BOM_NAME
  echo "      branch: $ULTRASCHALL_ASSETS_BRANCH" >> $ULTRASCHALL_BOM_NAME
  echo "      commit: $ULTRASCHALL_ASSETS_COMMIT" >> $ULTRASCHALL_BOM_NAME
  echo "" >> $ULTRASCHALL_BOM_NAME
  echo "Done."

  echo "Creating installer packages directory..."
  if [ ! -d installer-packages ]; then
    mkdir installer-packages
  fi
  echo "Done."

  echo "Creating Ultraschall REAPER Plug-in installer package..."
  pkgbuild --root ultraschall-plugin/build/release --scripts $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-plugin/scripts --identifier fm.ultraschall.reaper.plugin --install-location "/Library/Application Support/REAPER/UserPlugins" installer-packages/ultraschall-reaper-plugin.pkg
  echo "Done."

  echo "Creating Ultraschall REAPER Theme installer package..."
  pkgbuild --root ultraschall-theme --scripts $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-theme/scripts --identifier fm.ultraschall.reaper.theme --install-location "/Library/Application Support/REAPER" installer-packages/ultraschall-reaper-theme.pkg
  echo "Done."

  echo "Creating Ultraschall REAPER API installer package..."
  pkgbuild --root ultraschall-api --scripts $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-api/scripts --identifier fm.ultraschall.reaper.api --install-location "/Library/Application Support/REAPER/UserPlugins" installer-packages/ultraschall-reaper-api.pkg
  echo "Done."

  echo "Creating Ultraschall Soundboard installer package..."
  pkgbuild --root $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-soundboard/payload --scripts $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-soundboard/scripts --identifier fm.ultraschall.soundboard --install-location "/Library/Audio/Plug-Ins/Components" installer-packages/ultraschall-soundboard.pkg
  echo "Done."

  echo "Creating StudioLink installer packager..."
  pkgbuild --root $ULTRASCHALL_ROOT_DIRECTORY/studio-link/payload --scripts $ULTRASCHALL_ROOT_DIRECTORY/studio-link/scripts --identifier fm.ultraschall.studiolink --install-location "/Library/Audio/Plug-Ins/Components" installer-packages/studio-link.pkg
  echo "Done."

  echo "Creating StudioLink OnAir installer packager..."
  pkgbuild --root $ULTRASCHALL_ROOT_DIRECTORY/studio-link-onair/payload --scripts $ULTRASCHALL_ROOT_DIRECTORY/studio-link-onair/scripts --identifier fm.ultraschall.studiolink.onair --install-location "/Library/Audio/Plug-Ins/Components" installer-packages/studio-link-onair.pkg
  echo "Done."

  echo "Creating REAPER SWS Extension Plugins installer package..."
  pkgbuild --root $ULTRASCHALL_ROOT_DIRECTORY/sws-extension/payload --scripts $ULTRASCHALL_ROOT_DIRECTORY/sws-extension/scripts --identifier fm.ultraschall.reaper.sws.plugins --install-location "/Library/Application Support/REAPER/UserPlugins" installer-packages/reaper-sws-extension-plugins.pkg
  echo "Done."

  echo "Creating REAPER SWS Extension Scripts installer package..."
  pkgbuild --root $ULTRASCHALL_ROOT_DIRECTORY/sws-scripts/payload --scripts $ULTRASCHALL_ROOT_DIRECTORY/sws-scripts/scripts --identifier fm.ultraschall.reaper.sws.scripts --install-location "/Library/Application Support/REAPER/Scripts" installer-packages/reaper-sws-extension-scripts.pkg
  echo "Done."

  echo "Creating REAPER JS Extension installer package..."
  pkgbuild --root $ULTRASCHALL_ROOT_DIRECTORY/js-extension/payload --scripts $ULTRASCHALL_ROOT_DIRECTORY/js-extension/scripts --identifier fm.ultraschall.reaper.js --install-location "/Library/Application Support/REAPER/UserPlugins" installer-packages/reaper-js-extension.pkg
  echo "Done."

  echo "Creating REAPER ReaPack Extension installer package..."
  pkgbuild --root $ULTRASCHALL_ROOT_DIRECTORY/reapack-extension/payload --scripts $ULTRASCHALL_ROOT_DIRECTORY/reapack-extension/scripts --identifier fm.ultraschall.reaper.reapack --install-location "/Library/Application Support/REAPER/UserPlugins" installer-packages/reaper-reapack-extension.pkg
  echo "Done."

  echo "Creating intermediate installer package..."
  if [ ! -d ultraschall-product ]; then
    mkdir ultraschall-product
  fi
  productbuild --distribution $ULTRASCHALL_SCRIPTS_DIRECTORY/distribution.xml --resources $ULTRASCHALL_RESOURCES_DIRECTORY --package-path installer-packages ultraschall-product/ultraschall-intermediate.pkg
  if [ $? -ne 0 ]; then
    echo "Failed to build intermediate installer package."
    exit -1
  fi
  echo "Done."

  echo "Creating final installer package..."
  ULTRASCHALL_BUILD_NAME="<Unknown>"
  if [ $ULTRASCHALL_BUILD_RELEASE -eq 1 ]; then
    ULTRASCHALL_BUILD_NAME="Ultraschall-5.0.0"
  else
    ULTRASCHALL_BUILD_NAME=$ULTRASCHALL_BUILD_TAG
  fi

  if [ $ULTRASCHALL_BUILD_CODESIGN -eq 1 ]; then
    productsign --sign "Developer ID Installer: Heiko Panjas (8J2G689FCZ)" ultraschall-product/ultraschall-intermediate.pkg "installer-root/$ULTRASCHALL_BUILD_NAME.pkg"
    if [ $? -ne 0 ]; then
      echo "Failed to build final installer package."
      exit -1
    fi
  else
    cp ultraschall-product/ultraschall-intermediate.pkg "installer-root/$ULTRASCHALL_BUILD_NAME.pkg"
    if [ $? -ne 0 ]; then
      echo "Failed to build final installer package."
      exit -1
    fi
  fi
  echo "Done."

  echo "Creating intermediate installer disk image..."
  if [ -f ultraschall-product/ultraschall-intermediate.dmg ]; then
    rm ultraschall-product/ultraschall-intermediate.dmg
  fi
  hdiutil create -format UDRW -srcfolder installer-root -fs HFS+ -volname $ULTRASCHALL_BUILD_NAME ultraschall-product/ultraschall-intermediate.dmg
  if [ $? -ne 0 ]; then
    echo "Failed to create intermediate installer disk image."
    exit -1
  fi
  echo "Done."

  echo "Mounting intermediate installer disk image..."
  if [ ! -d ultraschall-intermediate ]; then
    mkdir ultraschall-intermediate
  fi
  hdiutil attach -mountpoint ./ultraschall-intermediate ./ultraschall-product/ultraschall-intermediate.dmg
  if [ $? -ne 0 ]; then
    echo "Failed to mount intermediate installer disk image."
    exit -1
  fi
  echo "Done."

  sync

  if [ $ULTRASCHALL_BUILD_CODESIGN -eq 1 ]; then
    echo "Signing uninstall script..."
    codesign --sign "Developer ID Application: Heiko Panjas (8J2G689FCZ)" ./ultraschall-intermediate/Uninstall.command
    if [ $? -ne 0 ]; then
      echo "Failed to sign uninstall script."
      exit -1
    fi
    echo "Done."

    echo "Signing device removal script..."
    codesign --sign "Developer ID Application: Heiko Panjas (8J2G689FCZ)" "./ultraschall-intermediate/Utilities/Remove legacy audio devices.command"
    if [ $? -ne 0 ]; then
      echo "Failed to sign device removal script."
      exit -1
    fi
    echo "Done."
  fi

  echo "Creating installer disk window layout..."
  echo "tell application \"Finder\"" > create-window-layout.script
  echo "  tell disk \"ultraschall-intermediate\"" >> create-window-layout.script
  echo "        open" >> create-window-layout.script
  echo "        set current view of container window to icon view" >> create-window-layout.script
  echo "        set toolbar visible of container window to false" >> create-window-layout.script
  echo "        set statusbar visible of container window to false" >> create-window-layout.script
  echo "        set the bounds of container window to {100, 100, 800, 540}" >> create-window-layout.script
  echo "        set viewOptions to the icon view options of container window" >> create-window-layout.script
  echo "        set arrangement of viewOptions to not arranged" >> create-window-layout.script
  echo "        set background picture of viewOptions to file \".background:background.png\"" >> create-window-layout.script
  echo "        set position of item \"$ULTRASCHALL_BUILD_NAME.pkg\" of container window to {50, 30}" >> create-window-layout.script
  if [ $ULTRASCHALL_BUILD_RELEASE -eq 0 ]; then
    cp $ULTRASCHALL_BOM_NAME ultraschall-intermediate/
    echo "        set position of item \"$ULTRASCHALL_BUILD_NAME.yml\" of container window to {250, 30}" >> create-window-layout.script
  fi
  echo "        set position of item \"README.html\" of container window to {50, 140}" >> create-window-layout.script
  echo "        set position of item \"INSTALL.html\" of container window to {200, 140}" >> create-window-layout.script
  echo "        set position of item \"CHANGELOG.html\" of container window to {350, 140}" >> create-window-layout.script
  echo "        set position of item \"Extras\" of container window to {50, 230}" >> create-window-layout.script
  echo "        set position of item \"Uninstall.command\" of container window to {50, 330}" >> create-window-layout.script
  echo "        set position of item \"Utilities\" of container window to {200, 230}" >> create-window-layout.script
  echo "        close" >> create-window-layout.script
  echo "        open" >> create-window-layout.script
  echo "        update without registering applications" >> create-window-layout.script
  echo "        delay 2" >> create-window-layout.script
  echo "  end tell" >> create-window-layout.script
  echo "end tell" >> create-window-layout.script
  osascript create-window-layout.script
  if [ $? -ne 0 ]; then
    echo "Failed to create installer disk window layout."
    exit -1
  fi
  echo "Done."

  # this is very required
  sync

  echo "Unmounting intermediate installer disk image..."
  hdiutil detach ultraschall-intermediate
  if [ $? -ne 0 ]; then
    echo "Failed to unmount intermediate installer disk image."
    exit -1
  fi
  echo "Done."

  # this is also very required
  sync

  echo "Finalizing installer disk image..."
  if [ -f "$ULTRASCHALL_ROOT_DIRECTORY/$ULTRASCHALL_BUILD_NAME.dmg" ]; then
    rm "$ULTRASCHALL_ROOT_DIRECTORY/$ULTRASCHALL_BUILD_NAME.dmg"
  fi
  hdiutil convert -format UDRO -o "$ULTRASCHALL_ROOT_DIRECTORY/$ULTRASCHALL_BUILD_NAME.dmg" ultraschall-product/ultraschall-intermediate.dmg
  if [ $? -ne 0 ]; then
    echo "Failed to finalize installer disk image."
    exit -1
  fi
  echo "Done."

  popd > /dev/null
fi

popd > /dev/null
exit 0
