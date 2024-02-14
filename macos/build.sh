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

ULTRASCHALL_BUILD_BOOTSTRAP=0
ULTRASCHALL_BUILD_CLEAN=0
ULTRASCHALL_BUILD_RELEASE=0
ULTRASCHALL_BUILD_CODESIGN=0
ULTRASCHALL_BUILD_UPDATE=0

ULTRASCHALL_ROOT_DIRECTORY=$('pwd')
ULTRASCHALL_RESOURCES_DIRECTORY="$ULTRASCHALL_ROOT_DIRECTORY/installer-resources"
ULTRASCHALL_SCRIPTS_DIRECTORY="$ULTRASCHALL_ROOT_DIRECTORY/installer-scripts"
ULTRASCHALL_BUILD_DIRECTORY="$ULTRASCHALL_ROOT_DIRECTORY/build"
ULTRASCHALL_ARTIFACTS_DIRECTORY="$ULTRASCHALL_BUILD_DIRECTORY/artifacts"
ULTRASCHALL_TOOLS_DIRECTORY="$ULTRASCHALL_BUILD_DIRECTORY/tools"
ULTRASCHALL_PAYLOAD_DIRECTORY="$ULTRASCHALL_BUILD_DIRECTORY/payload"

ULTRASCHALL_PLUGIN_URL="https://github.com/Ultraschall/ultraschall-plugin.git"
ULTRASCHALL_PLUGIN_BRANCH="main"
ULTRASCHALL_PORTABLE_URL="https://github.com/Ultraschall/ultraschall-portable.git"
ULTRASCHALL_PORTABLE_BRANCH="master"
ULTRASCHALL_STREAMDECK_URL="https://github.com/Ultraschall/ultraschall-stream-deck-plugin.git"
ULTRASCHALL_STREAMDECK_BRANCH="main"
ULTRASCHALL_ASSETS_URL="https://github.com/Ultraschall/ultraschall-assets.git"
ULTRASCHALL_ASSETS_BRANCH="master"

echo "**********************************************************************"
echo "*                                                                    *"
echo "*            BUILDING ULTRASCHALL INSTALLER PACKAGE                  *"
echo "*                                                                    *"
echo "**********************************************************************"

# Create folder for intermediate data
if [ ! -d $ULTRASCHALL_BUILD_DIRECTORY ]; then
  mkdir -p $ULTRASCHALL_BUILD_DIRECTORY
fi

# Enter build directory
pushd $ULTRASCHALL_BUILD_DIRECTORY > /dev/null

ULTRASCHALL_PANDOC_TOOL="pandoc"
if [ ! -x "$(command -v $ULTRASCHALL_PANDOC_TOOL)" ]; then
  ULTRASCHALL_PANDOC_TOOL="$ULTRASCHALL_TOOLS_DIRECTORY/pandoc-2.11.1.1/bin/pandoc"
  if [ ! -f $ULTRASCHALL_PANDOC_TOOL ]; then
    if [ ! -d $ULTRASCHALL_TOOLS_DIRECTORY ]; then
        mkdir -p $ULTRASCHALL_TOOLS_DIRECTORY
    fi
    if [ -d $ULTRASCHALL_TOOLS_DIRECTORY ]; then
      pushd $ULTRASCHALL_TOOLS_DIRECTORY > /dev/null
      echo "Downloading pandoc..."
      curl -LO "https://github.com/jgm/pandoc/releases/download/2.11.1.1/pandoc-2.11.1.1-macOS.zip"
      if [ $? -ne 0 ]; then
        echo "Failed to download pandoc."
        exit -1
      fi
      echo "Done."
      echo "Installing pandoc..."
      unzip "pandoc-2.11.1.1-macOS.zip";
      if [ $? -ne 0 ]; then
        echo "Failed to install pandoc."
        exit -1
      fi
      echo "Done."
      if [ -f "pandoc-2.11.1.1-macOS.zip" ]; then
        rm -f "pandoc-2.11.1.1-macOS.zip"
      fi
      popd > /dev/null
    else
      echo "Failed to create tools directory."
      exit -1
    fi
  fi
fi

ULTRASCHALL_PAYLOAD_DIRECTORY="$ULTRASCHALL_BUILD_DIRECTORY/payload"
if [ ! -d $ULTRASCHALL_PAYLOAD_DIRECTORY ]; then
  mkdir -p $ULTRASCHALL_PAYLOAD_DIRECTORY
fi

if [ -d $ULTRASCHALL_PAYLOAD_DIRECTORY ]; then
  pushd $ULTRASCHALL_PAYLOAD_DIRECTORY > /dev/null

  #-------------------------------------------------------------------------------
  if [ ! -d ultraschall-plugin ]; then
    echo "Downloading Ultraschall REAPER Plugin..."
    git clone --branch $ULTRASCHALL_PLUGIN_BRANCH $ULTRASCHALL_PLUGIN_URL ultraschall-plugin
    if [ ! -d ultraschall-plugin ]; then
      echo "Failed to download Ultraschall REAPER Plugin."
      exit -1
    fi
  else
    echo "Updating Ultraschall REAPER Plugin..."
    pushd ultraschall-plugin > /dev/null
    git pull
    popd > /dev/null
  fi
  echo "Done."

  #-------------------------------------------------------------------------------
  if [ ! -d ultraschall-portable ]; then
    echo "Downloading Ultraschall REAPER Theme..."
    git clone --branch $ULTRASCHALL_PORTABLE_BRANCH $ULTRASCHALL_PORTABLE_URL ultraschall-portable
    if [ ! -d ultraschall-portable ]; then
      echo "Failed to download Ultraschall REAPER Theme."
      exit -1
    fi
  else
    echo "Updating Ultraschall REAPER Theme..."
    pushd ultraschall-portable > /dev/null
    git pull
    popd > /dev/null
  fi
  echo "Done."

  #-------------------------------------------------------------------------------
  if [ ! -d ultraschall-assets ]; then
    echo "Downloading Ultraschall REAPER Resources..."
    git clone --branch $ULTRASCHALL_ASSETS_BRANCH $ULTRASCHALL_ASSETS_URL ultraschall-assets
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

  #-------------------------------------------------------------------------------
  if [ ! -d ultraschall-streamdeck ]; then
    echo "Downloading Ultraschall REAPER Stream Deck Plug-in..."
    git clone --branch $ULTRASCHALL_STREAMDECK_BRANCH $ULTRASCHALL_STREAMDECK_URL ultraschall-streamdeck
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
  echo "Downloading release $ULTRASCHALL_STREAMDECK_TAG..."
  curl -LO "https://github.com/Ultraschall/ultraschall-stream-deck-plugin/releases/download/$ULTRASCHALL_STREAMDECK_TAG/fm.ultraschall.ultradeck.streamDeckPlugin"
  if [ $? -ne 0 ]; then
    echo "Failed to download release $ULTRASCHALL_STREAMDECK_TAG."
    exit -1
  fi
  echo "Done."
  popd > /dev/null

  #-------------------------------------------------------------------------------
  echo "Creating installer root directory..."
  if [ -d installer-root ]; then
    rm -rf installer-root
  fi
  mkdir -p installer-root
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Copying installer background image..."
  if [ ! -d installer-root/.background ]; then
    mkdir -p installer-root/.background
  fi
  cp $ULTRASCHALL_RESOURCES_DIRECTORY/image-background.png \
    installer-root/.background/background.png
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Building Ultraschall documentation files..."
  $ULTRASCHALL_PANDOC_TOOL \
    --from=markdown \
    --to=html \
    --embed-resources \
    --standalone \
    --quiet \
    --css=$ULTRASCHALL_SCRIPTS_DIRECTORY/ultraschall.css \
    --output=installer-root/README.html ultraschall-plugin/docs/README.md
  if [ $? -ne 0 ]; then
    echo "Failed to convert README.md."
    exit -1
  fi
  $ULTRASCHALL_PANDOC_TOOL \
    --from=markdown \
    --to=html \
    --embed-resources \
    --standalone \
    --quiet \
    --css=$ULTRASCHALL_SCRIPTS_DIRECTORY/ultraschall.css \
    --output=installer-root/INSTALL.html ultraschall-plugin/docs/INSTALL.md
  if [ $? -ne 0 ]; then
    echo "Failed to convert INSTALL.md."
    exit -1
  fi
  $ULTRASCHALL_PANDOC_TOOL \
    --from=markdown \
    --to=html \
    --embed-resources \
    --standalone \
    --quiet \
    --css=$ULTRASCHALL_SCRIPTS_DIRECTORY/ultraschall.css \
    --output=installer-root/CHANGELOG.html ultraschall-plugin/docs/CHANGELOG.md
  if [ $? -ne 0 ]; then
    echo "Failed to convert CHANGELOG.md."
    exit -1
  fi
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Copying utility scripts..."
  cp $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-scripts/Uninstall.command \
    installer-root/Uninstall.command
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Copying Ultraschall Extras..."
  if [ ! -d installer-root/Extras ]; then
    mkdir -p installer-root/Extras
  fi
  cp ultraschall-assets/keyboard-layout/Keymap.pdf \
    "installer-root/Extras/Ultraschall Keyboard Layout.pdf"
  cp ultraschall-assets/source/us-banner_400.png \
    "installer-root/Extras/Ultraschall Badge 400px.png"
  cp ultraschall-assets/source/us-banner_800.png \
    "installer-root/Extras/Ultraschall Badge 800px.png"
  cp ultraschall-assets/source/us-banner_2000.png \
    "installer-root/Extras/Ultraschall Badge 2000px.png"
  cp ultraschall-assets/images/Ultraschall-5-Logo.png \
    "installer-root/Extras/Ultraschall-5-Logo.png"
  echo "Done."

  echo "Copying Ultraschall Utilities..."
  if [ ! -d installer-root/Utilities ]; then
    mkdir -p installer-root/Utilities
  fi
  cp $ULTRASCHALL_PAYLOAD_DIRECTORY/ultraschall-streamdeck/fm.ultraschall.ultradeck.streamDeckPlugin \
    "installer-root/Utilities/fm.ultraschall.ultradeck.streamDeckPlugin"
  cp $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-hub/UltraschallHub-2015-11-12.pkg \
    "installer-root/Utilities/Ultraschall Hub.pkg"
  cp "$ULTRASCHALL_ROOT_DIRECTORY/ultraschall-scripts/Remove legacy audio devices.command" \
    "installer-root/Utilities/Remove legacy audio devices.command"
  echo "Done."

  echo "Building ULTRASCHALL REAPER Theme..."
  if [ ! -d ultraschall-theme ]; then
    mkdir -p ultraschall-theme
  fi
  cp -r ultraschall-portable/ ultraschall-theme
  rm -rf ultraschall-theme/.git
  rm -rf ultraschall-theme/Plugins/FX
  rm -r ultraschall-theme/Plugins/*.dll
  rm -r ultraschall-theme/Plugins/*.exe
  rm -rf ultraschall-theme/UserPlugins/FX
  rm -r ultraschall-theme/UserPlugins/reaper_js_ReaScriptAPI64.dll
  rm -r ultraschall-theme/UserPlugins/reaper_js_ReaScriptAPI64.so
  rm -r ultraschall-theme/UserPlugins/reaper_sws-aarch64.so
  rm -r ultraschall-theme/UserPlugins/reaper_sws-armv7l.so
  rm -r ultraschall-theme/UserPlugins/reaper_sws-i686.so
  rm -r ultraschall-theme/UserPlugins/reaper_sws-x64.dll
  rm -r ultraschall-theme/UserPlugins/reaper_sws-x86_64.so
  rm -r ultraschall-theme/UserPlugins/reaper_ultraschall.dll
  rm -r ultraschall-theme/UserPlugins/reaper_ultraschall.so
  rm -f ultraschall-theme/Default_6.0.ReaperThemeZip
  rm -f ultraschall-theme/reamote.exe
  rm -f ultraschall-theme/ColorThemes/Default_6.0.ReaperThemeZip
  rm -f ultraschall-theme/ColorThemes/Default_5.0.ReaperThemeZip
  rm -f ultraschall-theme/ColorThemes/Ultraschall_3.1.ReaperThemeZip
  rm -rf ultraschall-theme/osFiles
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Configure user access rights..."
  chown -R $(whoami) .
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Creating installer packages directory..."
  if [ ! -d installer-packages ]; then
    mkdir -p installer-packages
  fi
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Creating Ultraschall REAPER Theme installer package..."
  pkgbuild \
    --root ultraschall-theme \
    --scripts $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-theme/scripts \
    --identifier fm.ultraschall.reaper.theme \
    --install-location "/Library/Application Support/REAPER" \
    installer-packages/ultraschall-reaper-theme.pkg
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Creating Ultraschall Soundboard installer package..."
  pkgbuild \
    --root $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-soundboard/payload \
    --scripts $ULTRASCHALL_ROOT_DIRECTORY/ultraschall-soundboard/scripts \
    --identifier fm.ultraschall.soundboard \
    --install-location "/Library/Audio/Plug-Ins/Components" \
    installer-packages/ultraschall-soundboard.pkg
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Creating StudioLink installer packager..."
  pkgbuild \
    --root $ULTRASCHALL_ROOT_DIRECTORY/studio-link/payload \
    --scripts $ULTRASCHALL_ROOT_DIRECTORY/studio-link/scripts \
    --identifier fm.ultraschall.studiolink \
    --install-location "/Library/Audio/Plug-Ins/Components" \
    installer-packages/studio-link.pkg
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Creating StudioLink OnAir installer packager..."
  pkgbuild \
    --root $ULTRASCHALL_ROOT_DIRECTORY/studio-link-onair/payload \
    --scripts $ULTRASCHALL_ROOT_DIRECTORY/studio-link-onair/scripts \
    --identifier fm.ultraschall.studiolink.onair \
    --install-location "/Library/Audio/Plug-Ins/Components" \
    installer-packages/studio-link-onair.pkg
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Creating intermediate installer package..."
  if [ ! -d ultraschall-product ]; then
    mkdir -p ultraschall-product
  fi
  productbuild \
    --distribution $ULTRASCHALL_SCRIPTS_DIRECTORY/distribution.xml \
    --resources $ULTRASCHALL_RESOURCES_DIRECTORY \
    --package-path installer-packages \
    ultraschall-product/ultraschall-intermediate.pkg
  if [ $? -ne 0 ]; then
    echo "Failed to build intermediate installer package."
    exit -1
  fi
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Creating final installer package..."
  ULTRASCHALL_BUILD_NAME="ULTRASCHALL_R5.1.0-preview"

  if [ $ULTRASCHALL_BUILD_CODESIGN -eq 1 ]; then
    productsign \
      --sign "Developer ID Installer: Heiko Panjas (8J2G689FCZ)" \
      ultraschall-product/ultraschall-intermediate.pkg \
      "installer-root/$ULTRASCHALL_BUILD_NAME.pkg"
    if [ $? -ne 0 ]; then
      echo "Failed to build final installer package."
      exit -1
    fi
  else
    cp ultraschall-product/ultraschall-intermediate.pkg \
      "installer-root/$ULTRASCHALL_BUILD_NAME.pkg"
    if [ $? -ne 0 ]; then
      echo "Failed to build final installer package."
      exit -1
    fi
  fi
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Creating intermediate installer disk image..."
  if [ -f ultraschall-product/ultraschall-intermediate.dmg ]; then
    rm ultraschall-product/ultraschall-intermediate.dmg
  fi
  hdiutil create \
    -format UDRW \
    -srcfolder installer-root \
    -fs HFS+ \
    -volname $ULTRASCHALL_BUILD_NAME \
    ultraschall-product/ultraschall-intermediate.dmg
  if [ $? -ne 0 ]; then
    echo "Failed to create intermediate installer disk image."
    exit -1
  fi
  echo "Done."

  #-------------------------------------------------------------------------------
  echo "Mounting intermediate installer disk image..."
  if [ ! -d ultraschall-intermediate ]; then
    mkdir -p ultraschall-intermediate
  fi
  hdiutil attach \
    -mountpoint ./ultraschall-intermediate \
    ./ultraschall-product/ultraschall-intermediate.dmg
  if [ $? -ne 0 ]; then
    echo "Failed to mount intermediate installer disk image."
    exit -1
  fi
  echo "Done."

  sync

  #-------------------------------------------------------------------------------
  if [ $ULTRASCHALL_BUILD_CODESIGN -eq 1 ]; then
    echo "Signing uninstall script..."
    codesign \
      --sign "Developer ID Application: Heiko Panjas (8J2G689FCZ)" \
      ./ultraschall-intermediate/Uninstall.command
    if [ $? -ne 0 ]; then
      echo "Failed to sign uninstall script."
      exit -1
    fi
    echo "Done."

    echo "Signing device removal script..."
    codesign \
      --sign "Developer ID Application: Heiko Panjas (8J2G689FCZ)" \
      "./ultraschall-intermediate/Utilities/Remove legacy audio devices.command"
    if [ $? -ne 0 ]; then
      echo "Failed to sign device removal script."
      exit -1
    fi
    echo "Done."
  fi

  #-------------------------------------------------------------------------------
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

  #-------------------------------------------------------------------------------
  echo "Unmounting intermediate installer disk image..."
  hdiutil detach ultraschall-intermediate
  if [ $? -ne 0 ]; then
    echo "Failed to unmount intermediate installer disk image."
    exit -1
  fi
  echo "Done."

  # this is also very required
  sync

  #-------------------------------------------------------------------------------
  echo "Finalizing installer disk image..."
  if [ ! -d "$ULTRASCHALL_ARTIFACTS_DIRECTORY" ]; then
    mkdir -p "$ULTRASCHALL_ARTIFACTS_DIRECTORY"
  fi
  if [ -f "$ULTRASCHALL_ARTIFACTS_DIRECTORY/$ULTRASCHALL_BUILD_NAME.dmg" ]; then
    rm "$ULTRASCHALL_ARTIFACTS_DIRECTORY/$ULTRASCHALL_BUILD_NAME.dmg"
  fi
  hdiutil convert \
    -format UDRO \
    -o "$ULTRASCHALL_ARTIFACTS_DIRECTORY/$ULTRASCHALL_BUILD_NAME.dmg" \
    ultraschall-product/ultraschall-intermediate.dmg
  if [ $? -ne 0 ]; then
    echo "Failed to finalize installer disk image."
    exit -1
  fi
  echo "Done."

  popd > /dev/null
fi

popd > /dev/null
exit 0
