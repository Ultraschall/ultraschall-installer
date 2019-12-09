Write-Host "**********************************************************************"
Write-Host "*                                                                    *"
Write-Host "*            BUILDING ULTRASCHALL INSTALLER PACKAGE                  *"
Write-Host "*                                                                    *"
Write-Host "**********************************************************************"

# Specify build directory
$BuildDirectory = "./_build"
$BuildId = "R4.0_GENERIC"
$BuildFailed = $False

if ((Test-Path -PathType Container $BuildDirectory) -eq $False) {
  New-Item -ItemType Directory -Path $BuildDirectory | Out-Null
}
Write-Host "Entering build directory..."
Push-Location $BuildDirectory
Write-Host "Done."

if ($BuildFailed -eq $False) {
  $CMakeDirectory = "./cmake-tool"
  if ((Test-Path -PathType Container $CMakeDirectory) -eq $False) {
    Write-Host "Downloading CMake Build Tool..."
    New-Item -ItemType Directory -Path $CMakeDirectory | Out-Null
    Push-Location $CMakeDirectory
    Invoke-WebRequest -Uri "https://github.com/Kitware/CMake/releases/download/v3.15.0/cmake-3.15.0-win64-x64.zip" -OutFile "./cmake-3.15.0-win64-x64.zip"
    Expand-Archive -Force -Path "./cmake-3.15.0-win64-x64.zip" -DestinationPath "./"
    Write-Host "Done."
    Pop-Location
  }
}

if ($BuildFailed -eq $False) {
  if ((Test-Path -PathType Leaf "./cmake-tool/cmake-3.15.0-win64-x64/bin/cmake.exe") -ne $False) {
    $CMakeProgramPath = Get-ChildItem "./cmake-tool/cmake-3.15.0-win64-x64/bin/cmake.exe" | Select-Object $_.FullName
  }
  else {
    Write-Host -Foreground Red "Failed to download CMake Build Tool."
    $BuildFailed = $True
  }
}

if ($BuildFailed -eq $False) {
  $PandocDirectory = "./pandoc-tool"
  if ((Test-Path -PathType Container $PandocDirectory) -eq $False) {
    Write-Host "Downloading Pandoc Universal Markup Converter..."
    New-Item -ItemType Directory -Path $PandocDirectory | Out-Null
    Push-Location $PandocDirectory
    Invoke-WebRequest -Uri "https://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-windows-x86_64.zip" -OutFile "./pandoc-2.7.3-windows-x86_64.zip"
    Expand-Archive -Force -Path "./pandoc-2.7.3-windows-x86_64.zip" -DestinationPath "./"
    if ((Test-Path -PathType Leaf "./pandoc-2.7.3-windows-x86_64/pandoc.exe") -eq $False) {
      Write-Host -Foreground Red "Failed to download Pandoc Universal Markup Converter."
      $BuildFailed = $True
    }
    Write-Host "Done."
    Pop-Location
  }
}

if ($BuildFailed -eq $False) {
  if ((Test-Path -PathType Leaf "./pandoc-tool/pandoc-2.7.3-windows-x86_64/pandoc.exe") -ne $False) {
    $PandocProgramPath = Get-ChildItem "./pandoc-tool/pandoc-2.7.3-windows-x86_64/pandoc.exe" | Select-Object $_.FullName
  }
  else {
    Write-Host -Foreground Red "Failed to download Pandoc Universal Markup Converter."
    $BuildFailed = $True
  }
}

if ($BuildFailed -eq $False) {
  $WixDirectory = "./wix-tool"
  if ((Test-Path -PathType Container $WixDirectory) -eq $False) {
    Write-Host "Downloading WiX Toolset..."
    New-Item -ItemType Directory -Path $WixDirectory | Out-Null
    Push-Location $WixDirectory
    Invoke-WebRequest -Uri "https://github.com/wixtoolset/wix3/releases/download/wix3111rtm/wix311-binaries.zip" -OutFile "./wix311-binaries.zip"
    Expand-Archive -Force -Path "./wix311-binaries.zip" -DestinationPath "./"
    Write-Host "Done."
    Pop-Location
  }
}

if ($BuildFailed -eq $False) {
  if ((Test-Path -PathType Leaf "./pandoc-tool/pandoc-2.7.3-windows-x86_64/pandoc.exe") -ne $False) {
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
    git clone --branch develop --depth 1 https://github.com/Ultraschall/ultraschall-plugin.git $PluginDirectory
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
  Push-Location $PluginDirectory
  $BuildId = (git describe --tags | Out-String).Trim()
  if ($BuildId.Length -gt 0) {
    $BuildId = "ULTRASCHALL_" + $BuildId
  }
  else {
    $BuildFailed = $True
  }
  Pop-Location
}

if ($BuildFailed -eq $False) {
  $PortableDirectory = "./ultraschall-portable"
  if ((Test-Path -PathType Container $PortableDirectory) -eq $False) {
    Write-Host "Downloading Ultraschall REAPER API..."
    git clone --depth 1 https://github.com/Ultraschall/ultraschall-portable.git $PortableDirectory
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
    git clone --depth 1 https://github.com/Ultraschall/ultraschall-assets.git $AssetsDirectory
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
  $RedistDirectory = "./microsoft-redist"
  if ((Test-Path -PathType Container $RedistDirectory) -eq $False) {
    Write-Host "Copying Microsoft Visual C++ 2019 CRT..."
    New-Item -ItemType Directory -Path $RedistDirectory | Out-Null
    Copy-Item -Force "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2019/Professional/VC/Redist/MSVC/14.24.28127/MergeModules/Microsoft_VC142_CRT_x64.msm" -Destination $RedistDirectory
    if ((Test-Path -PathType Leaf "$RedistDirectory/Microsoft_VC142_CRT_x64.msm") -eq $False) {
      Write-Host -Foreground Red "Failed to copy Microsoft Visual C++ 2019 CRT."
      $BuildFailed = $True
    }
    Write-Host "Done."
  }
}

if ($BuildFailed -eq $False) {
  $ResourcesDirectory = "./ultraschall-resources"
  Write-Host "Building Ultraschall documentation files..."
  if ((Test-Path -PathType Container $ResourcesDirectory) -eq $False) {
    New-Item -ItemType Directory -Path $ResourcesDirectory | Out-Null
  }
  if ((Test-Path -PathType Leaf $ResourcesDirectory/README.html) -eq $False) {
    & $PandocProgramPath --from=markdown --to=html --standalone --quiet --self-contained --css=../installer-scripts/ultraschall.css --output=ultraschall-resources/README.html ultraschall-plugin/docs/README.md
    if ($LASTEXITCODE -ne 0) {
      $BuildFailed = $True
    }
  }
  if ((Test-Path -PathType Leaf $ResourcesDirectory/INSTALL.html) -eq $False) {
    & $PandocProgramPath --from=markdown --to=html --standalone --quiet --self-contained --css=../installer-scripts/ultraschall.css --output=ultraschall-resources/INSTALL.html ultraschall-plugin/docs/INSTALL.md
    if ($LASTEXITCODE -ne 0) {
      $BuildFailed = $True
    }
  }
  if ((Test-Path -PathType Leaf $ResourcesDirectory/CHANGELOG.html) -eq $False) {
    & $PandocProgramPath --from=markdown --to=html --standalone --quiet --self-contained --css=../installer-scripts/ultraschall.css --output=ultraschall-resources/CHANGELOG.html ultraschall-plugin/docs/CHANGELOG.md
    if ($LASTEXITCODE -ne 0) {
      $BuildFailed = $True
    }
  }
  Write-Host "Done."
}

if ($BuildFailed -eq $False) {
  Write-Host "Building Ultraschall REAPER Plug-in..."
  Push-Location $PluginDirectory
  if ((Test-Path -PathType Container $BuildDirectory) -eq $False) {
    New-Item -ItemType Directory -Path $BuildDirectory | Out-Null
  }
  Push-Location $BuildDirectory
  & $CMakeProgramPath -G "Visual Studio 16 2019" -DCMAKE_BUILD_TYPE=Release ../
  if ($LASTEXITCODE -ne 0) {
    $BuildFailed = $True
  }
  & $CMakeProgramPath --build . --target reaper_ultraschall --config Release -j
  if ($LASTEXITCODE -ne 0) {
    $BuildFailed = $True
  }
  Pop-Location
  Pop-Location
  Write-Host "Done."
}

if ($BuildFailed -eq $False) {
  $APIDirectory = "./ultraschall_api"
  Write-Host "Copying Ultraschall API files..."
  if ((Test-Path -PathType Container $APIDirectory) -eq $False) {
    New-Item -ItemType Directory -Path $APIDirectory | Out-Null
  }
  Copy-Item -Force "./ultraschall-portable/UserPlugins/ultraschall_api.lua" -Destination $APIDirectory
  Copy-Item -Force "./ultraschall-portable/UserPlugins/ultraschall_api_readme.txt" -Destination $APIDirectory
  # Push-Location $APIDirectory
  Copy-Item -Force -Recurse "./ultraschall-portable/UserPlugins/ultraschall_api" -Destination $APIDirectory
  if ((Test-Path -PathType Container $APIDirectory/ultraschall_api/Scripts) -eq $False) {
    Write-Host -Foreground Red "Failed to copy Ultraschall API files."
    $BuildFailed = $True
  }
  # Pop-Location
  Write-Host "Done."
}

Write-Host "Leaving build directory."
Pop-Location
Write-Host "Done."

$env:ULTRASCHALL_BUILD_ID = $BuildId
$env:ULTRASCHALL_API_SOURCE = ".\_build\ultraschall_api"
if ($BuildFailed -eq $False) {
  Write-Host "Compiling API Files..."
  & $HeatProgramPath dir $env:ULTRASCHALL_API_SOURCE -nologo -cg UltraschallApiFiles -ag -scom -sreg -sfrag -srd -dr ReaperPluginsFolder -var env.ULTRASCHALL_API_SOURCE -out ./_build/ultraschall_api.wxs
  if ($LASTEXITCODE -eq 0) {
    & $CandleProgramPath -nologo -arch x64 -out ./_build/ultraschall_api.wixobj ./_build/ultraschall_api.wxs
    if ($LASTEXITCODE -ne 0) {
      $BuildFailed = $True
    }
  }
  else {
    $BuildFailed = $True
  }
  Write-Host "Done."
}

if ($BuildFailed -eq $False) {
  Write-Host "Building installer package..."
  & $CandleProgramPath -nologo -arch x64 -out ./_build/distribution.wixobj ./installer-scripts/distribution.wxs
  if ($LASTEXITCODE -eq 0) {
    & $LightProgramPath -nologo -sice:ICE64 -sice:ICE38 -sw1076 -ext WixUIExtension -cultures:en-us -spdb -out "$BuildId.msi" ./_build/distribution.wixobj ./_build/ultraschall_api.wixobj
    if ($LASTEXITCODE -ne 0) {
      $BuildFailed = $True
    }
  }
  else {
    $BuildFailed = $True
  }
  Write-Host "Done."
}

$env:ULTRASCHALL_API_SOURCE = ""
$env:ULTRASCHALL_BUILD_ID = ""

if ($BuildFailed -eq $False) {
  Write-Host -Foreground Green "Successfully built $BuildId. \o/"
}
else {
  Write-Host -Foreground Red "Failed to build $BuildId. /o\"
  Set-Location $PSScriptRoot
}
