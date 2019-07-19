Write-Host "**********************************************************************"
Write-Host "*                                                                    *"
Write-Host "*            BUILDING ULTRASCHALL INSTALLER PACKAGE                  *"
Write-Host "*                                                                    *"
Write-Host "**********************************************************************"

# Specify build directory
$BuildDirectory = "./_build"
$BuildId = "<unknown>"

$FailHandler = {
  Write-Host -Foreground Red "Failed to build $BuildId. /o\"
  Set-Location $PSScriptRoot
}

if ((Test-Path -PathType Container $BuildDirectory) -eq $False) {
  New-Item -ItemType Directory -Path $BuildDirectory | Out-Null
}
Write-Host "Entering build directory..."
Push-Location $BuildDirectory
Write-Host "Done."

$PandocDirectory = "./pandoc-tool"
if ((Test-Path -PathType Container $PandocDirectory) -eq $False) {
  Write-Host "Downloading Pandoc Universal Markup Converter..."
  New-Item -ItemType Directory -Path $PandocDirectory | Out-Null
  Push-Location $PandocDirectory
  Invoke-WebRequest -Uri "https://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-windows-x86_64.zip" -OutFile "./pandoc-2.7.3-windows-x86_64.zip"
  Expand-Archive -Force -Path "./pandoc-2.7.3-windows-x86_64.zip" -DestinationPath "./"
  if ((Test-Path -PathType Leaf "./pandoc-2.7.3-windows-x86_64/pandoc.exe") -eq $False) {
    Write-Host -Foreground Red "Failed to download Pandoc Universal Markup Converter."
    &$FailHandler
  }
  Write-Host "Done."
  Pop-Location
}

$WixDirectory = "./wix-tool"
if ((Test-Path -PathType Container $WixDirectory) -eq $False) {
  Write-Host "Downloading WiX Toolset..."
  New-Item -ItemType Directory -Path $WixDirectory | Out-Null
  Push-Location $WixDirectory
  Invoke-WebRequest -Uri "https://github.com/wixtoolset/wix3/releases/download/wix3111rtm/wix311-binaries.zip" -OutFile "./wix311-binaries.zip"
  Expand-Archive -Force -Path "./wix311-binaries.zip" -DestinationPath "./"
  if ((Test-Path -PathType Leaf "./candle.exe") -eq $False) {
    Write-Host -Foreground Red "Failed to download Downloading WiX Toolset."
    &$FailHandler
  }
  Write-Host "Done."
  Pop-Location
}

$PluginDirectory = "./ultraschall-plugin"
if ((Test-Path -PathType Container $PluginDirectory) -eq $False) {
  Write-Host "Downloading Ultraschall REAPER Plug-in..."
  git clone --branch develop --depth 1 https://github.com/Ultraschall/ultraschall-plugin.git $PluginDirectory
  if ((Test-Path -PathType Container $PluginDirectory) -eq $False) {
    Write-Host -Foreground Red "Failed to download Ultraschall REAPER Plug-in."
    &$FailHandler
  }
  Write-Host "Done."
}
else {
  Write-Host "Updating Ultraschall REAPER Plug-in..."
  Push-Location $PluginDirectory
  git pull
  Pop-Location
  Write-Host "Done."
}
Push-Location $PluginDirectory
$BuildId = (git describe --tags | Out-String).Trim()
Pop-Location

$PortableDirectory = "./ultraschall-portable"
if ((Test-Path -PathType Container $PortableDirectory) -eq $False) {
  Write-Host "Downloading Ultraschall REAPER API..."
  git clone --depth 1 https://github.com/Ultraschall/ultraschall-portable.git $PortableDirectory
  if ((Test-Path -PathType Container $PortableDirectory) -eq $False) {
    Write-Host -Foreground Red "Failed to download Ultraschall REAPER API."
    &$FailHandler
  }
  Write-Host "Done."
}
else {
  Write-Host "Updating Ultraschall REAPER API..."
  Push-Location $PortableDirectory
  git pull
  Pop-Location
  Write-Host "Done."
}

$AssetsDirectory = "./ultraschall-assets"
if ((Test-Path -PathType Container $AssetsDirectory) -eq $False) {
  Write-Host "Downloading Ultraschall REAPER Resources..."
  git clone --depth 1 https://github.com/Ultraschall/ultraschall-assets.git $AssetsDirectory
  if ((Test-Path -PathType Container $AssetsDirectory) -eq $False) {
    Write-Host -Foreground Red "Failed to download Ultraschall REAPER Resources."
    &$FailHandler
  }
  Write-Host "Done."
}
else {
  Write-Host "Ultraschall REAPER Resources..."
  Push-Location $AssetsDirectory
  git pull
  Pop-Location
  Write-Host "Done."
}

$RedistDirectory = "./microsoft-redist"
if ((Test-Path -PathType Container $RedistDirectory) -eq $False) {
  Write-Host "Copying Microsoft Visual C++ 2019 CRT..."
  New-Item -ItemType Directory -Path $RedistDirectory | Out-Null
  Copy-Item -Force "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2019/Professional/VC/Redist/MSVC/14.21.27702/MergeModules/Microsoft_VC142_CRT_x64.msm" -Destination $RedistDirectory
  if ((Test-Path -PathType Leaf "$RedistDirectory/Microsoft_VC142_CRT_x64.msm") -eq $False) {
    Write-Host -Foreground Red "Failed to copy Microsoft Visual C++ 2019 CRT."
    &$FailHandler
  }
  Write-Host "Done."
}

$ResourcesDirectory = "./ultraschall-resources"
Write-Host "Building Ultraschall documentation files..."
if ((Test-Path -PathType Container $ResourcesDirectory) -eq $False) {
  New-Item -ItemType Directory -Path $ResourcesDirectory | Out-Null
}
if ((Test-Path -PathType Leaf $ResourcesDirectory/README.html) -eq $False) {
  ./pandoc-tool/pandoc-2.7.3-windows-x86_64/pandoc.exe --from=markdown --to=html --standalone --quiet --self-contained --css=../installer-scripts/ultraschall.css --output=ultraschall-resources/README.html ultraschall-plugin/docs/README.md
  if ($LASTEXITCODE -ne 0) {
    &$FailHandler
  }
}
if ((Test-Path -PathType Leaf $ResourcesDirectory/INSTALL.html) -eq $False) {
  ./pandoc-tool/pandoc-2.7.3-windows-x86_64/pandoc.exe --from=markdown --to=html --standalone --quiet --self-contained --css=../installer-scripts/ultraschall.css --output=ultraschall-resources/INSTALL.html ultraschall-plugin/docs/INSTALL.md
  if ($LASTEXITCODE -ne 0) {
    &$FailHandler
  }
}
if ((Test-Path -PathType Leaf $ResourcesDirectory/CHANGELOG.html) -eq $False) {
  ./pandoc-tool/pandoc-2.7.3-windows-x86_64/pandoc.exe --from=markdown --to=html --standalone --quiet --self-contained --css=../installer-scripts/ultraschall.css --output=ultraschall-resources/CHANGELOG.html ultraschall-plugin/docs/CHANGELOG.md
  if ($LASTEXITCODE -ne 0) {
    &$FailHandler
  }
}
Write-Host "Done."

Write-Host "Building Ultraschall REAPER Plug-in..."
Push-Location $PluginDirectory
if ((Test-Path -PathType Container $BuildDirectory) -eq $False) {
  New-Item -ItemType Directory -Path $BuildDirectory | Out-Null
}
Push-Location $BuildDirectory
cmake -G "Visual Studio 16 2019" -DCMAKE_BUILD_TYPE=Release ../
if ($LASTEXITCODE -ne 0) {
  &$FailHandler
}
cmake --build . --target reaper_ultraschall --config Release -j
if ($LASTEXITCODE -ne 0) {
  &$FailHandler
}
Pop-Location
Pop-Location
Write-Host "Done."

$APIDirectory = "./ultraschall-api"
Write-Host "Copying Ultraschall API files..."
if ((Test-Path -PathType Container $APIDirectory) -eq $False) {
  New-Item -ItemType Directory -Path $APIDirectory | Out-Null
}
Push-Location $APIDirectory
Copy-Item -Force -Recurse "../ultraschall-portable/UserPlugins/ultraschall_api" -Destination $APIDirectory
if ((Test-Path -PathType Container $APIDirectory/Scripts) -eq $False) {
  Write-Host -Foreground Red "Failed to copy Ultraschall API files."
}
Pop-Location
Write-Host "Done."

Write-Host "Leaving build directory."
Pop-Location
Write-Host "Done."

Write-Host "Building installer package..."
$env:ULTRASCHALL_BUILD_ID = $BuildId
./_build/wix-tool/candle.exe -nologo -arch x64 -out ./_build/$BuildId.wixobj ./installer-scripts/distribution.wxs
if ($LASTEXITCODE -ne 0) {
  &$FailHandler
}
./_build/wix-tool/light.exe -nologo -sw1076 -ext WixUIExtension -cultures:en-us -spdb ./_build/$BuildId.wixobj -out "$BuildId.msi"
if ($LASTEXITCODE -ne 0) {
  &$FailHandler
}
Write-Host "Done."

$env:ULTRASCHALL_BUILD_ID = ""
Write-Host -Foreground Green "Successfully built $BuildId. \o/"
