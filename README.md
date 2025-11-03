## Windows

Dependencies:

- Building on Windows requires Visual Studio 2019 or later.
- Pandoc [https://pandoc.org/installixng.html](https://pandoc.org/installing.html)
	- the build script will will place a portable version in the build directory if not installed

```powershell
PS> cd win32/
PS> ./build.ps1
```

## macOS

Building on macOS requires Xcode 11 or later.

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
$ tar xvf ULTRASCHALL_R5.1.2-preview.tar.gz
$ cd R5.1.2-preview
$ ./install.sh
```
