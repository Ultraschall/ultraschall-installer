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

**in development - currently testing only**

1. clone this repository

2. change directory

```bash
$ cd ultraschall-installer/linux
```

3. build

```bash
$ ./build.sh
```

To install Ultraschall, get the installer artifact in `linux/build/artifacts` (tar.gz file):

```bash
$ tar xvf ULTRASCHALL_R5.1.0-preview.tar.gz
$ cd R5.1.0-preview
$ ./install.sh
```
