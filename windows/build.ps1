Write-Host "**********************************************************************"
Write-Host "*                                                                    *"
Write-Host "*            BUILDING ULTRASCHALL INSTALLER PACKAGE                  *"
Write-Host "*                                                                    *"
Write-Host "**********************************************************************"

$BuildDirectory = "./build"
$BuildId = "ULTRASCHALL_R5.1.0-preview"
$BuildFailed = $False

if ($args.Count -gt 0) {
  if ($args[0] -eq "--help") {
    Write-Host "Usage: build.ps1 [ --help | --release ]"
    return
  }
  elseif ($args[0] -eq "--release") {
    $BuildId = "Ultraschall-5.1.0"
  }
}

if ((Test-Path -PathType Container $BuildDirectory) -eq $False) {
  New-Item -ItemType Directory -Path $BuildDirectory | Out-Null
}
Write-Host "Entering build directory..."
Push-Location $BuildDirectory
Write-Host "Done."

if ($BuildFailed -eq $False) {
  $WixDirectory = "./wix-tool"
  if ((Test-Path -PathType Container $WixDirectory) -eq $False) {
    Write-Host "Downloading WiX Toolset..."
    New-Item -ItemType Directory -Path $WixDirectory | Out-Null
    Push-Location $WixDirectory
    Invoke-WebRequest -Uri "https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314-binaries.zip" -OutFile "./wix314-binaries.zip"
    Expand-Archive -Force -Path "./wix314-binaries.zip" -DestinationPath "./"
    Write-Host "Done."
    Pop-Location
  }
}

if ($BuildFailed -eq $False) {
  if ((Test-Path -PathType Leaf "./wix-tool/candle.exe") -ne $False) {
    $CandleProgramPath = Get-ChildItem "./wix-tool/candle.exe" | Select-Object $_.FullName
    $LightProgramPath = Get-ChildItem "./wix-tool/light.exe" | Select-Object $_.FullName
    $HeatProgramPath = Get-ChildItem "./wix-tool/heat.exe" | Select-Object $_.FullName
  }
  else {
    Write-Host -Foreground Red "Failed to download WiX Toolset."
    $BuildFailed = $True
  }
}

if ($BuildFailed -eq $False) {
  $PluginDirectory = "./ultraschall-plugin"
  if ((Test-Path -PathType Container $PluginDirectory) -eq $False) {
    Write-Host "Downloading Ultraschall REAPER Plug-in..."
    git clone --branch main https://github.com/Ultraschall/ultraschall-plugin.git $PluginDirectory
    if ((Test-Path -PathType Container $PluginDirectory) -eq $False) {
      Write-Host -Foreground Red "Failed to download Ultraschall REAPER Plug-in."
      $BuildFailed = $True
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
}

if ($BuildFailed -eq $False) {
  $PortableDirectory = "./ultraschall-portable"
  if ((Test-Path -PathType Container $PortableDirectory) -eq $False) {
    Write-Host "Downloading Ultraschall REAPER API..."
    git clone --branch master https://github.com/Ultraschall/ultraschall-portable.git $PortableDirectory
    if ((Test-Path -PathType Container $PortableDirectory) -eq $False) {
      Write-Host -Foreground Red "Failed to download Ultraschall REAPER API."
      $BuildFailed = $True
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
}

if ($BuildFailed -eq $False) {
  $AssetsDirectory = "./ultraschall-assets"
  if ((Test-Path -PathType Container $AssetsDirectory) -eq $False) {
    Write-Host "Downloading Ultraschall REAPER Resources..."
    git clone --branch master https://github.com/Ultraschall/ultraschall-assets.git $AssetsDirectory
    if ((Test-Path -PathType Container $AssetsDirectory) -eq $False) {
      Write-Host -Foreground Red "Failed to download Ultraschall REAPER Resources."
      $BuildFailed = $True
    }
    Write-Host "Done."
  }
  else {
    Write-Host "Updating Ultraschall REAPER Resources..."
    Push-Location $AssetsDirectory
    git pull
    Pop-Location
    Write-Host "Done."
  }
}

if ($BuildFailed -eq $False) {
  $StreamDeckDirectory = "./ultraschall-stream-deck-plugin"
  if ((Test-Path -PathType Container $StreamDeckDirectory) -eq $False) {
    Write-Host "Downloading Ultraschall Stream Deck Plugin......"
    git clone --branch main https://github.com/Ultraschall/ultraschall-stream-deck-plugin.git $StreamDeckDirectory
    if ((Test-Path -PathType Container $StreamDeckDirectory) -eq $False) {
      Write-Host -Foreground Red "Failed to download Ultraschall stream deck plugin."
      $BuildFailed = $True
    }
    Write-Host "Done."
  }
  else {
    Write-Host "Updating Ultraschall REAPER Stream Deck Plugin..."
    Push-Location $StreamDeckDirectory
    git pull
    Pop-Location
    Write-Host "Done."
  }
}

if ($BuildFailed -eq $False) {
  Push-Location $StreamDeckDirectory
      $StreamDeckTag = (git describe --tags | Out-String).Trim()
      $StreamDeckUrl = "https://github.com/Ultraschall/ultraschall-stream-deck-plugin/releases/download/" + $StreamDeckTag + "/fm.ultraschall.ultradeck.streamDeckPlugin"
      Invoke-WebRequest -Uri $StreamDeckUrl -OutFile "./fm.ultraschall.ultradeck.streamDeckPlugin"
  Pop-Location
}

if ($BuildFailed -eq $False) {
  $ResourcesDirectory = "./ultraschall-resources"
  $PandocProgramPath = "pandoc"
  Write-Host "Building Ultraschall documentation files..."
  if ((Test-Path -PathType Container $ResourcesDirectory) -eq $False) {
    New-Item -ItemType Directory -Path $ResourcesDirectory | Out-Null
  }
  if ((Test-Path -PathType Leaf $ResourcesDirectory/README.html) -eq $False) {
    & $PandocProgramPath --from=markdown --to=html --embed-resources --standalone --quiet --css=../installer-scripts/ultraschall.css --output=ultraschall-resources/README.html ultraschall-plugin/docs/README.md
    if ($LASTEXITCODE -ne 0) {
      $BuildFailed = $True
    }
  }
  if ((Test-Path -PathType Leaf $ResourcesDirectory/INSTALL.html) -eq $False) {
    & $PandocProgramPath --from=markdown --to=html --embed-resources --standalone --quiet --css=../installer-scripts/ultraschall.css --output=ultraschall-resources/INSTALL.html ultraschall-plugin/docs/INSTALL.md
    if ($LASTEXITCODE -ne 0) {
      $BuildFailed = $True
    }
  }
  if ((Test-Path -PathType Leaf $ResourcesDirectory/CHANGELOG.html) -eq $False) {
    & $PandocProgramPath --from=markdown --to=html --embed-resources --standalone --quiet --css=../installer-scripts/ultraschall.css --output=ultraschall-resources/CHANGELOG.html ultraschall-plugin/docs/CHANGELOG.md
    if ($LASTEXITCODE -ne 0) {
      $BuildFailed = $True
    }
  }
  Write-Host "Done."
}

if ($BuildFailed -eq $False) {
  $ThemeDirectory = "./ultraschall-theme"
  Write-Host "Copying Ultraschall Theme files..."
  if ((Test-Path -PathType Container $ThemeDirectory) -eq $False) {
    New-Item -ItemType Directory -Path $ThemeDirectory | Out-Null
  }
  Copy-Item -Force -Recurse "./ultraschall-portable/*" -Destination $ThemeDirectory
  if ((Test-Path -PathType Leaf $ThemeDirectory/reaper.ini) -eq $True) {

    Remove-Item -Recurse -Force $ThemeDirectory/.git
    Remove-Item -Force $ThemeDirectory/.gitignore

    Remove-Item -Force $ThemeDirectory/UserPlugins/reaper_js_ReaScriptAPI64.dylib
    Remove-Item -Force $ThemeDirectory/UserPlugins/reaper_js_ReaScriptAPI64.so
    Remove-Item -Force $ThemeDirectory/UserPlugins/reaper_js_ReaScriptAPI64ARM.dylib
    Remove-Item -Force $ThemeDirectory/UserPlugins/reaper_sws-aarch64.so
    Remove-Item -Force $ThemeDirectory/UserPlugins/reaper_sws-arm64.dylib
    Remove-Item -Force $ThemeDirectory/UserPlugins/reaper_sws-armv7l.so
    Remove-Item -Force $ThemeDirectory/UserPlugins/reaper_sws-i686.so
    Remove-Item -Force $ThemeDirectory/UserPlugins/reaper_sws-x86_64.dylib
    Remove-Item -Force $ThemeDirectory/UserPlugins/reaper_sws-x86_64.so
    Remove-Item -Force $ThemeDirectory/UserPlugins/reaper_ultraschall.dylib
    Remove-Item -Force $ThemeDirectory/UserPlugins/reaper_ultraschall.so

    Remove-Item -Recurse -Force $ThemeDirectory/UserPlugins/FX
    Remove-Item -Recurse -Force $ThemeDirectory/ColorThemes/Default_6.0.ReaperThemeZip

    Remove-Item -Force $ThemeDirectory/reaper-kb.ini
    Copy-Item -Force $ThemeDirectory/osFiles/Win/reaper-kb.ini -Destination $ThemeDirectory

    Remove-Item -Recurse -Force $ThemeDirectory/TrackTemplates
    New-Item -ItemType Directory -Path $ThemeDirectory/TrackTemplates  | Out-Null
    Copy-Item -Force -Recurse $ThemeDirectory/osFiles/Win/TrackTemplates/* -Destination $ThemeDirectory/TrackTemplates

    Remove-Item -Recurse -Force $ThemeDirectory/ProjectTemplates
    New-Item -ItemType Directory -Path $ThemeDirectory/ProjectTemplates | Out-Null
    Copy-Item -Force -Recurse $ThemeDirectory/osFiles/Win/ProjectTemplates/* -Destination $ThemeDirectory/ProjectTemplates

    Remove-Item -Recurse -Force $ThemeDirectory/osFiles
  }
  else {
    Write-Host -Foreground Red "Failed to copy Ultraschall Theme files."
    $BuildFailed = $True
  }
  Write-Host "Done."
}

Write-Host "Leaving build directory."
Pop-Location
Write-Host "Done."

$env:ULTRASCHALL_BUILD_ID = $BuildId
$env:ULTRASCHALL_THEME_SOURCE = ".\build\ultraschall-theme"

if ($BuildFailed -eq $False) {
  Write-Host "Compiling Theme Files..."
  & $HeatProgramPath dir $env:ULTRASCHALL_THEME_SOURCE -nologo -cg UltraschallThemeFiles -ag -scom -sreg -sfrag -srd -dr ReaperFolder -var env.ULTRASCHALL_THEME_SOURCE -out ./build/ultraschall-theme.wxs
  if ($LASTEXITCODE -eq 0) {
    & $CandleProgramPath -nologo -arch x64 -out ./build/ultraschall-theme.wixobj ./build/ultraschall-theme.wxs
    if ($LASTEXITCODE -ne 0) {
      Write-Host -Foreground Red "Failed to compile Ultraschall Theme files."
      $BuildFailed = $True
    }
  }
  else {
    Write-Host -Foreground Red "Failed to harvest Ultraschall Theme files."
    $BuildFailed = $True
  }
  Write-Host "Done."
}

if ($BuildFailed -eq $False) {
  Write-Host "Building installer package..."
  & $CandleProgramPath -nologo -arch x64 -out ./build/distribution.wixobj ./installer-scripts/distribution.wxs
  if ($LASTEXITCODE -eq 0) {
    New-Item -ItemType Directory -Path "./build/artifacts" -Force | Out-Null
    & $LightProgramPath -nologo -sice:ICE64 -sice:ICE38 -sw1076 -ext WixUIExtension -cultures:en-us -spdb -out "./build/artifacts/$BuildId.msi" ./build/distribution.wixobj ./build/ultraschall-theme.wixobj
    if ($LASTEXITCODE -ne 0) {
      Write-Host -Foreground Red "Failed to build Ultraschall Package files."
      $BuildFailed = $True
    }
  }
  else {
    Write-Host -Foreground Red "Failed compile Ultraschall Package files."
    $BuildFailed = $True
  }
  Write-Host "Done."
}

$env:ULTRASCHALL_THEME_SOURCE = ""
$env:ULTRASCHALL_BUILD_ID = ""

if ($BuildFailed -eq $False) {
  Write-Host -Foreground Green "Successfully built $BuildId. \o/"
}
else {
  Write-Host -Foreground Red "Failed to build $BuildId. /o\"
  Set-Location $PSScriptRoot
}
