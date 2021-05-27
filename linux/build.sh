#!/bin/bash

echo "**********************************************************************"
echo "*                                                                    *"
echo "*            BUILDING ULTRASCHALL INSTALLER PACKAGE                  *"
echo "*                                                                    *"
echo "**********************************************************************"

# Specify build type
BUILD_RELEASE=0

if [ "$1" = "--help" ]; then
  echo "Usage: build.sh [ --release ]"
  exit 0
elif [ "$1" = "--release" ]; then
  BUILD_RELEASE=1
fi

SOURCE_BRANCH='develop'
if [ $BUILD_RELEASE = 1 ]; then
  SOURCE_BRANCH='master'
fi

echo "Building installer from $SOURCE_BRANCH branch..."

# Specify build id
ULTRASCHALL_BUILD_ID='R5.0.0_GENERIC'

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
  curl -LO https://github.com/jgm/pandoc/releases/download/2.9.1.1/pandoc-2.9.1.1-linux-amd64.tar.gz;
  if [ $? -ne 0 ]; then
    echo "Failed to download Pandoc Universal Markup Converter."
    exit -1
  fi
  gunzip pandoc-2.9.1.1-linux-amd64.tar.gz;
  tar -xvf pandoc-2.9.1.1-linux-amd64.tar
  if [ $? -ne 0 ]; then
    echo "Failed to install Pandoc Universal Markup Converter."
    exit -1
  else
    rm pandoc-2.9.1.1-linux-amd64.tar
  fi

  popd > /dev/null
  echo "Done."
fi

if [ ! -d ultraschall-plugin ]; then
  echo "Downloading Ultraschall REAPER Plug-in..."
  git clone --branch $SOURCE_BRANCH --depth 1 https://github.com/Ultraschall/ultraschall-plugin.git ultraschall-plugin
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
  git clone https://github.com/Ultraschall/ultraschall-assets.git ultraschall-assets
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
if [ ! -d installer-package ]; then
  mkdir installer-package
fi
pushd installer-package > /dev/null
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
popd
echo "Done."

echo "Building Ultraschall documentation files..."
pandoc-tool/pandoc-2.9.1.1/bin/pandoc --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output=installer-package/README.html ultraschall-plugin/docs/README.md
pandoc-tool/pandoc-2.9.1.1/bin/pandoc --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output=installer-package/INSTALL.html ultraschall-plugin/docs/INSTALL.md
pandoc-tool/pandoc-2.9.1.1/bin/pandoc --from=markdown --to=html --standalone --self-contained --quiet --css=../installer-scripts/ultraschall.css --output=installer-package/CHANGELOG.html ultraschall-plugin/docs/CHANGELOG.md
echo "Done."

echo "Building Ultraschall REAPER Plug-in"
pushd ultraschall-plugin > /dev/null

if [ $BUILD_RELEASE = 1 ]; then
  ULTRASCHALL_BUILD_ID='Ultraschall-4.1.0'
else
  git describe --tags > ../version.txt
  ULTRASCHALL_BUILD_TAG=$(<../version.txt)
  ULTRASCHALL_BUILD_ID="ULTRASCHALL_$ULTRASCHALL_BUILD_TAG"
fi

if [ ! -d build ]; then
 mkdir build
fi
pushd build > /dev/null
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release ../
if [ $? -ne 0 ]; then
  echo "Failed to configure Ultraschall REAPER Plug-in."
  exit -1
fi
cmake --build . --target reaper_ultraschall --config Release -j 6
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

echo "Copying Ultraschall resources..."
cp ultraschall-assets/keyboard-layout/Keymap.pdf "installer-package/resources/Ultraschall Keyboard Layout.pdf"
cp ultraschall-assets/source/us-banner_400.png "installer-package/resources/Ultraschall Badge 400px.png"
cp ultraschall-assets/source/us-banner_800.png "installer-package/resources/Ultraschall Badge 800px.png"
cp ultraschall-assets/source/us-banner_2000.png "installer-package/resources/Ultraschall Badge 2000px.png"
echo "Done."

echo "Copying Ultraschall themes..."
cp ../ultraschall-theme/Ultraschall_4.0.ReaperConfigZip installer-package/themes/Ultraschall_4.0.ReaperConfigZip
echo "Done."

echo "Copying Ultraschall plugins..."
cp ../js-extension/reaper_js_ReaScriptAPI64.so installer-package/plugins/reaper_js_ReaScriptAPI64.so
cp ../reapack-extension/reaper_reapack-x86_64.so installer-package/plugins/reaper_reapack-x86_64.so
cp ../sws-extension/reaper_sws-x86_64.so installer-package/plugins/reaper_sws-x86_64.so
cp ../sws-extension/sws_python64.py installer-package/scripts/sws_python64.py
cp ../sws-extension/sws_python.py installer-package/scripts/sws_python.py
# FIXME studiolink
# FIXME studiolink-onair
# FIXME soundboard
cp ultraschall-plugin/build/src/reaper_ultraschall.so installer-package/plugins/reaper_ultraschall.so
cp -R ultraschall-api/ultraschall_api/ installer-package/plugins/ultraschall_api/
cp ultraschall-api/ultraschall_api.lua installer-package/plugins/ultraschall_api.lua
cp ultraschall-api/ultraschall_api_readme.txt installer-package/plugins/ultraschall_api_readme.txt
echo "Done."

echo "Copying install script..."
cp ../installer-scripts/install.sh installer-package
chmod +x installer-package/install.sh
echo "Done."

echo "Creating installer package..."
tar -czf "../$ULTRASCHALL_BUILD_ID.tar.gz" installer-package
if [ $? -ne 0 ]; then
  echo "Failed to build final installer package."
  exit -1
fi
echo "Done."

popd > /dev/null
exit 0
