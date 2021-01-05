## Windows

Building on Windows requires Visual Studio 2019 16.2.

```powershell
PS> cd win32/
PS> ./build.ps1
```

## macOS

Building on macOS requires Xcode 10.3.

```bash
$ cd macos/
$ ./build.sh
```

## Linux

**experimental - for testing only**

1. clone this repository
```bash
$ git clone https://github.com/Ultraschall/ultraschall-installer.git 
```

2. change directory 
```bash
$ cd ultraschall-installer/linux
```

3. build
```bash
$ ./build.sh
```

4. change directory 
```bash
$ cd build/installer-package
```

5. install (you must have reaper installed) 
```bash
$ ./install.sh
```


## Notice for Linux: 
Some features like StudioLink, StuidoLink-onair and soundboard are still missing. 
A StudioLink VST is available for testing: https://download.studio.link/releases/v20.12.1-stable/linux/vst/studio-link-plugin.zip 
Download the file and extract it to /home/[username]/.vst3 
