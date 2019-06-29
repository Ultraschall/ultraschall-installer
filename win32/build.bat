@echo off

echo **********************************************************************
echo *                                                                    *
echo *            BUILDING ULTRASCHALL INSTALLER PACKAGE                  *
echo *                                                                    *
echo **********************************************************************

rem Specify build directory
set ULTRASCHALL_BUILD_DIRECTORY=build

rem Create folder for intermediate data
if not exist %ULTRASCHALL_BUILD_DIRECTORY% (
    mkdir %ULTRASCHALL_BUILD_DIRECTORY%
)

rem Enter %ULTRASCHALL_BUILD_DIRECTORY% folder
pushd %ULTRASCHALL_BUILD_DIRECTORY%

if not exist pandoc-tool (
  echo Downloading Pandoc Universal Markup Converter...
  mkdir pandoc-tool && pushd pandoc-tool
  curl -LO https://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-windows-x86_64.zip
  unzip pandoc-2.7.3-windows-x86_64.zip
  popd
  if not exist pandoc-tool\pandoc-2.7.3-windows-x86_64\pandoc.exe (
    echo Failed to download Pandoc Universal Markup Converter.
    goto failed
  )
)
echo Done.

if not exist ultraschall-plugin (
  echo Downloading Ultraschall REAPER Plug-in...
  git clone https://github.com/Ultraschall/ultraschall-3.git ultraschall-plugin
  if not exist ultraschall-plugin (
    echo Failed to download Ultraschall REAPER Plug-in.
    goto failed
  )
) else (
  echo Updating Ultraschall REAPER Plug-in...
  pushd ultraschall-plugin
  git pull
  popd
)
pushd ultraschall-plugin
git describe --tags > ..\version.txt
set /p ULTRASCHALL_BUILD_ID= < ..\version.txt
popd
echo Done.

if not exist ultraschall-portable (
  echo Downloading Ultraschall REAPER API...
  git clone https://github.com/Ultraschall/ultraschall-portable.git ultraschall-portable
  if not exist ultraschall-portable (
    echo Failed to download Ultraschall REAPER API.
    goto failed
  )
) else (
  echo Updating Ultraschall REAPER API...
  pushd ultraschall-portable
  git pull
  popd
)
echo Done.

if not exist microsoft-redist (
  echo Copying Microsoft Visual C++ 2019 CRT...
  mkdir microsoft-redist
  copy "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\VC\Redist\MSVC\14.21.27702\MergeModules\Microsoft_VC142_CRT_x64.msm" microsoft-redist
  if not errorlevel 0 goto failed
  echo Done.
)

echo Building Ultraschall documentation files...
if not exist ultraschall-resources mkdir ultraschall-resources
pandoc-tool\pandoc-2.7.3-windows-x86_64\pandoc.exe --from=markdown --to=html --standalone --quiet --self-contained --css=..\installer-scripts\ultraschall.css --output=ultraschall-resources\README.html ultraschall-plugin\Docs\Release\README.md
if not errorlevel 0 goto failed
pandoc-tool\pandoc-2.7.3-windows-x86_64\pandoc.exe --from=markdown --to=html --standalone --quiet --self-contained --css=..\installer-scripts\ultraschall.css --output=ultraschall-resources\INSTALL.html ultraschall-plugin\Docs\Release\INSTALL.md
if not errorlevel 0 goto failed
pandoc-tool\pandoc-2.7.3-windows-x86_64\pandoc.exe --from=markdown --to=html --standalone --quiet --self-contained --css=..\installer-scripts\ultraschall.css --output=ultraschall-resources\CHANGELOG.html ultraschall-plugin\Docs\Release\CHANGELOG.md
if not errorlevel 0 goto failed
echo Done.

echo Building Ultraschall REAPER Plug-in...
pushd ultraschall-plugin
if not exist build mkdir build
pushd build
cmake -G "Visual Studio 16 2019" -A x64 -DCMAKE_BUILD_TYPE=Release ../Plugin
if not errorlevel 0 goto failed
cmake --build . --target reaper_ultraschall --config Release -j
if not errorlevel 0 goto failed
popd
popd
echo Done.

echo Copying Ultraschall API files...
if not exist ultraschall-api mkdir ultraschall-api
pushd ultraschall-api
xcopy ..\ultraschall-portable\UserPlugins\ultraschall_api /s /e /y /c
if not errorlevel 0 goto failed
popd
echo Done.

rem Leave %ULTRASCHALL_BUILD_DIRECTORY% folder
popd

echo Building installer package...
set ULTRASCHALL_BUILD_NAME=ULTRASCHALL-%ULTRASCHALL_BUILD_ID%
candle -nologo -arch x64 -out %ULTRASCHALL_BUILD_DIRECTORY%\%ULTRASCHALL_BUILD_NAME%.wixobj installer-scripts\distribution.wxs
if not errorlevel 0 goto failed
light -nologo -sw1076 -ext WixUIExtension -cultures:en-us -spdb %ULTRASCHALL_BUILD_DIRECTORY%\%ULTRASCHALL_BUILD_NAME%.wixobj -out %ULTRASCHALL_BUILD_NAME%.msi
if not errorlevel 0 goto failed
echo Done.

goto success

:failed
echo Failed to build %ULTRASCHALL_BUILD_ID%. /o\
goto end

:success
echo Successfully built %ULTRASCHALL_BUILD_ID%. \o/
goto end

:end
rem Clean-up if build completed successfully
set ULTRASCHALL_BUILD_ID=
set ULTRASCHALL_BUILD_NAME=
set ULTRASCHALL_BUILD_DIRECTORY=
