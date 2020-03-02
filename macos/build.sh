#!/bin/sh

BUILD_RELEASE=0

if [ "$1" = "--help" ]; then
  echo "Usage: build.sh [ --release ]"
  exit 0
elif [ "$1" = "--release" ]; then
  BUILD_RELEASE=1
fi

echo "**********************************************************************"
echo "*                                                                    *"
echo "*            BUILDING ULTRASCHALL INSTALLER PACKAGE                  *"
echo "*                                                                    *"
echo "**********************************************************************"

# Specify build directory
ULTRASCHALL_BUILD_DIRECTORY='./_build'

# Create folder for intermediate data
if [ ! -d $ULTRASCHALL_BUILD_DIRECTORY ]; then
  mkdir $ULTRASCHALL_BUILD_DIRECTORY
fi

# Enter %ULTRASCHALL_BUILD_DIRECTORY% folder
pushd $ULTRASCHALL_BUILD_DIRECTORY > /dev/null

if [ ! -d pandoc-tool ]; then
  echo "Downloading Pandoc Universal Markup Converter..."

  mkdir pandoc-tool && pushd pandoc-tool > /dev/null

  curl -LO https://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-macOS.zip;
  if [ $? -ne 0 ]; then
    echo "Failed to download Pandoc Universal Markup Converter."
    exit -1
  fi
  unzip pandoc-2.7.3-macOS.zip;
  if [ $? -ne 0 ]; then
    echo "Failed to install Pandoc Universal Markup Converter."
    exit -1
  fi

  popd > /dev/null
  echo "Done."
fi

if [ ! -d ultraschall-plugin ]; then
  echo "Downloading Ultraschall REAPER Plug-in..."
  git clone --branch master --depth 1 https://github.com/Ultraschall/ultraschall-plugin.git ultraschall-plugin
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
  git clone --branch master --depth 1 https://github.com/Ultraschall/ultraschall-portable.git ultraschall-portable
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
  git clone --branch master --depth 1 https://github.com/Ultraschall/ultraschall-assets.git ultraschall-assets
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

echo "Creating installer root directory..."
if [ ! -d installer-root ]; then
  mkdir installer-root
fi
echo "Done."

echo "Copying installer background image..."
if [ ! -d installer-root/.background ]; then
  mkdir installer-root/.background
fi
cp ../installer-resources/image-background.png installer-root/.background/background.png
echo "Done."

echo "Building Ultraschall documentation files..."
pandoc-tool/pandoc-2.7.3/bin/pandoc --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output=installer-root/README.html ultraschall-plugin/docs/README.md
pandoc-tool/pandoc-2.7.3/bin/pandoc --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output=installer-root/INSTALL.html ultraschall-plugin/docs/INSTALL.md
pandoc-tool/pandoc-2.7.3/bin/pandoc --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output=installer-root/CHANGELOG.html ultraschall-plugin/docs/CHANGELOG.md
echo "Done."

echo "Copying utility scripts..."
cp ../ultraschall-scripts/Uninstall.command installer-root/Uninstall.command
echo "Done."

echo "Copying Ultraschall Extras..."
if [ ! -d installer-root/Extras ]; then
  mkdir installer-root/Extras
fi
cp ultraschall-assets/keyboard-layout/Keymap.pdf "installer-root/Extras/Ultraschall Keyboard Layout.pdf"
cp ultraschall-assets/source/us-banner_400.png "installer-root/Extras/Ultraschall Badge 400px.png"
cp ultraschall-assets/source/us-banner_800.png "installer-root/Extras/Ultraschall Badge 800px.png"
cp ultraschall-assets/source/us-banner_2000.png "installer-root/Extras/Ultraschall Badge 2000px.png"
echo "Done."

echo "Copying Ultraschall REAPER Theme..."
cp ../ultraschall-theme/Ultraschall_4.0.ReaperConfigZip installer-root/Ultraschall_4.0.ReaperConfigZip
echo "Done."

echo "Copying Ultraschall Utilities..."
if [ ! -d installer-root/Utilities ]; then
  mkdir installer-root/Utilities
fi
cp ../ultraschall-hub/UltraschallHub-2015-11-12.pkg "installer-root/Utilities/Ultraschall Hub.pkg"
cp "../ultraschall-scripts/Remove legacy audio devices.command" "installer-root/Utilities/Remove legacy audio devices.command"
echo "Done."

echo "Building Ultraschall REAPER Plug-in"
pushd ultraschall-plugin > /dev/null
git describe --tags > ../version.txt
if [ ! -d build ]; then
 mkdir build
fi
pushd build > /dev/null
cmake -G "Xcode" -DCMAKE_BUILD_TYPE=Release ../
if [ $? -ne 0 ]; then
  echo "Failed to configure Ultraschall REAPER Plug-in."
  exit -1
fi
cmake --build . --target reaper_ultraschall --config Release
if [ $? -ne 0 ]; then
  echo "Failed to build Ultraschall REAPER Plug-in."
  exit -1
fi
popd > /dev/null
popd > /dev/null
echo "Done."

echo "Signing ULTRASCHALL REAPER Plug-in..."
codesign --force --sign "Developer ID Application: Heiko Panjas (8J2G689FCZ)" ultraschall-plugin/build/src/Release/reaper_ultraschall.dylib
if [ $? -ne 0 ]; then
  echo "Failed to sign ULTRASCHALL REAPER Plug-in."
  exit -1
fi
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

echo "Creating installer packages directory..."
if [ ! -d installer-packages ]; then
 mkdir installer-packages
fi
echo "Done."

echo "Creating Ultraschall REAPER Plug-in installer package..."
pkgbuild --root ultraschall-plugin/build/src/Release --identifier fm.ultraschall.reaper.plugin --install-location "/Library/Application Support/REAPER/UserPlugins" installer-packages/ultraschall-reaper-plugin.pkg
echo "Done."

echo "Creating Ultraschall REAPER API installer package..."
pkgbuild --root ultraschall-api --identifier fm.ultraschall.reaper.api --install-location "/Library/Application Support/REAPER/UserPlugins" installer-packages/ultraschall-reaper-api.pkg
echo "Done."

echo "Creating Ultraschall Soundboard installer package..."
pkgbuild --root ../ultraschall-soundboard/ --identifier fm.ultraschall.soundboard --install-location "/Library/Application Support/REAPER/UserPlugins/FX" installer-packages/ultraschall-soundboard.pkg
echo "Done."

echo "Creating StudioLink installer packager..."
pkgbuild --root ../studio-link --identifier fm.ultraschall.studiolink --install-location "/Library/Application Support/REAPER/UserPlugins/FX" installer-packages/studio-link.pkg
echo "Done."

echo "Creating StudioLink OnAir installer packager..."
pkgbuild --root ../studio-link-onair --identifier fm.ultraschall.studiolink.onair --install-location "/Library/Application Support/REAPER/UserPlugins/FX" installer-packages/studio-link-onair.pkg
echo "Done."

echo "Creating REAPER SWS Extension Plugins installer package..."
pkgbuild --root ../sws-extension/payload/plugins --identifier fm.ultraschall.reaper.sws.plugins --install-location "/Library/Application Support/REAPER/UserPlugins" installer-packages/reaper-sws-extension-plugins.pkg
echo "Done."

echo "Creating REAPER SWS Extension Scripts installer package..."
pkgbuild --root ../sws-extension/payload/scripts --identifier fm.ultraschall.reaper.sws.scripts --install-location "/Library/Application Support/REAPER/Scripts" installer-packages/reaper-sws-extension-scripts.pkg
echo "Done."

echo "Creating REAPER JS Extension installer package..."
pkgbuild --root ../js-extension --identifier fm.ultraschall.reaper.js --install-location "/Library/Application Support/REAPER/UserPlugins" installer-packages/reaper-js-extension.pkg
echo "Done."

echo "Creating REAPER ReaPack Extension installer package..."
pkgbuild --root ../reapack-extension --identifier fm.ultraschall.reaper.reapack --install-location "/Library/Application Support/REAPER/UserPlugins" installer-packages/reaper-reapack-extension.pkg
echo "Done."

echo "Creating intermediate installer package..."
if [ ! -d ultraschall-product ]; then
 mkdir ultraschall-product
fi
productbuild --distribution ../installer-scripts/distribution.xml --resources ../installer-resources --package-path installer-packages ultraschall-product/ultraschall-intermediate.pkg
if [ $? -ne 0 ]; then
  echo "Failed to build intermediate installer package."
  exit -1
fi
echo "Done."

echo "Creating final installer package..."
if [ $BUILD_RELEASE -eq 1 ]; then
  ULTRASCHALL_BUILD_ID="4.0-RC1"
else
  ULTRASCHALL_BUILD_ID=$(<version.txt)
fi
ULTRASCHALL_BUILD_NAME="ULTRASCHALL-$ULTRASCHALL_BUILD_ID"
productsign --sign "Developer ID Installer: Heiko Panjas (8J2G689FCZ)" ultraschall-product/ultraschall-intermediate.pkg "installer-root/$ULTRASCHALL_BUILD_NAME.pkg"
if [ $? -ne 0 ]; then
  echo "Failed to build final installer package."
  exit -1
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
hdiutil attach -mountpoint ultraschall-intermediate ultraschall-product/ultraschall-intermediate.dmg
if [ $? -ne 0 ]; then
  echo "Failed to mount intermediate installer disk image."
  exit -1
fi
echo "Done."

sync

echo "Signing uninstall script..."
codesign --sign "Developer ID Application: Heiko Panjas (8J2G689FCZ)" ultraschall-intermediate/Uninstall.command
if [ $? -ne 0 ]; then
  echo "Failed to sign uninstall script."
  exit -1
fi
echo "Done."

echo "Signing device removal script..."
codesign --sign "Developer ID Application: Heiko Panjas (8J2G689FCZ)" "ultraschall-intermediate/Utilities/Remove legacy audio devices.command"
if [ $? -ne 0 ]; then
  echo "Failed to sign device removal script."
  exit -1
fi
echo "Done."

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
echo "        set position of item \"Ultraschall_4.0.ReaperConfigZip\" of container window to {200, 30}" >> create-window-layout.script
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
if [ -f "../$ULTRASCHALL_BUILD_NAME.dmg" ]; then
  rm "../$ULTRASCHALL_BUILD_NAME.dmg"
fi
hdiutil convert -format UDRO -o "../$ULTRASCHALL_BUILD_NAME.dmg" ultraschall-product/ultraschall-intermediate.dmg
if [ $? -ne 0 ]; then
  echo "Failed to finalize installer disk image."
  exit -1
fi
echo "Done."

popd > /dev/null
exit 0
