# AutoQuad Flight Control Firmware

This is a fork/continuation of [Bill Nesbitt's AutoQuad firmware](https://github.com/bn999/autoquad) for multicopter flight control.

* [AutoQuad Project Site](http://autoquad.org/)
* [AutoQuad Documetation](http://autoquad.org/wiki/wiki/)
* [AutoQuad Forums](http://forum.autoquad.org/)
* [AutoQuad Downloads Page](http://autoquad.org/software-downloads/)
* [AutoQuad Public FTP: ftp://ftp.autoquad.org/3/334693_22529/](ftp://ftp.autoquad.org/3/334693_22529/)

### USE AT YOUR OWN RISK!!! ABSOLUTELY NO RESPONSOBILITY IS ASSUMED BY THE AUTHORS OR PUBLISHERS OF THIS FIRMWARE. SEE LICENSE FILE FOR FULL TERMS.

#### Repository Structure:

  * `master` branch is current stable version.
  * `next` branch is to integrate all proposed changes for holistic testing before being committed to `master`.
  * Numbered branches (eg. `6.8`) are for older versions.
  * All other branches are "feature" branches used for testing individual changes before integration into `next`.

Pull requests should typically be submitted against the `next` branch, unless it is an important fix for something which affects `master` as well, or some other similarly good reason.

#### Binary Distributions

Pre-compiled firmware versions can be found at the [AutoQuad public FTP site: ftp://ftp.autoquad.org/3/334693_22529/aq-firmware/forks/mpaperno/aq_flight_control/](ftp://ftp.autoquad.org/3/334693_22529/aq-firmware/forks/mpaperno/aq_flight_control/).  The structure is organized by repository branch and then hardware version.

#### Getting The Source Code

If you already have a Git client installed (or are willing to learn), the easiest method is to clone this repository to your local machine. If you do not want to deal with Git, you may also download zip archives of the necessary projects.

##### Repository Checkout & Submodule Init/Update

This repository contains [Git submodules](http://blogs.atlassian.com/2011/12/git-submodules/) (for MAVLink headers) which must be initialized and updated. This is a simple process but you will get compile errors if you don't do it.

If you use a GUI Git client ([TortoiseGit](https://tortoisegit.org/docs/tortoisegit/tgit-dug-submodules.html), [SourceTree](https://blog.sourcetreeapp.com/2012/02/01/using-submodules-and-subrepositories/), etc) then look for options such as _recursive_ during cloning and commands like "Update Submodules". This is usually an option when (or after) you do a clone/checkout command. Refer to the program's help if necessary. After checking out the code, make sure the `lib/mavlink/include` folder exists.

It is also very easy to use the command line for clone, update, and checkout.

Here's a complete example starting with fresh copy of the repo, then checking out the `next` branch, and the submodule init:

```shell
git clone https://github.com/mpaperno/aq_flight_control.git
cd aq_flight_control
git checkout next
git submodule update --init
```

If you already have a clone of the repo and you only want to do a pull of the latest changes, run something like this (example uses the `master` branch and assumes "origin" for the remote name of this GitHub repo, which is a typical default):

```shell
git checkout master
git pull --recurse-submodules origin master
git submodule update --init
```

As you may have gathered by now, the point is to run `git submodule update` after cloning or updating the code from this repository.  The `--init` option is only necessary the first time, but it doesn't hurt to include it.

##### Download Code as Zip Archives

Unfortunately GitHub makes this a bit more complicated than it should be. To download a snapshot of the current code on any branch:

1. In the default GitHub _Code_ tab view, find the _Branch_ menu and select the branch you want to download.
2. To the right of the _Branch_ menu, click the _Download ZIP_ link and save the file (it will be named something like "aq\_flight\_control\_master.zip")
3. While still in the _Code_ view, click on the `lib` folder.
4. To the right of the `mavlink` folder there is an ID like "67a140b" or similar (7 hex digits).  Click on that. It will take you to a different code repository (AutoQuad/mavlink_headers) and to a specific commit in a specific branch (this is important).
5. Now click the _Download Zip_ link on this new page. Save the file (it will be named "mavlink\_headers-" with a long string of numbers at the end).
6. Unzip the "aq\_flight\_control\_master.zip" file into wherever you want to keep the firmware source code (preferably a directory path w/out spaces).
7. Unzip the "mavlink\_headers-xxxxx.zip" file into the `lib/mavlink` folder of the firmware source code tree.  So the final result should be a `lib/mavlink/include` folder with 2 subfolders and some .h files inside.


#### Compiling The Firmware

##### Supported Toolchains

Rowley [CrossWorks for ARM](http://www.rowley.co.uk/arm/index.htm) (versions 2 or 3) and [GNU ARM Embedded](https://launchpad.net/gcc-arm-embedded) (tested with versions 4.7 through 5.4, 5.x recommended).

##### Building with CrossWorks for ARM:

The project can be built with CW version 2.x or 3.x.

1. Install, start, and license (eval is OK) latest (3.x) version of [CrossWorks for ARM](http://www.rowley.co.uk/arm/index.htm).
2. Install the latest `STM32 CPU Support Package` (use the `Package Manager` found in `Tools` menu).
3. Open _autoquad.hzp_ file (from the root folder of this project) in CrossWorks.
4. In Project Explorer window, select the build type from the dropdown menu at the top left (eg: "Release-AQ6.r1-DIMU-PID").  The build type should match your AQ hardware (version, IMU type, etc). Be sure to select a "Release" type build (not "Debug").
5. Select `Build Solution` from the main `Build` menu, or press `SHIFT-F7`.  If all goes well, there should be a compiled firmware binary in a subfolder of the created `build` directory.

##### Building with _Makefile_:

###### Install Toolchain

For GNU ARM Embedded:  
* If you don't already have one, download and unpack/install a release from [GNU ARM Embedded](https://launchpad.net/gcc-arm-embedded/+download). It is best to install it to a directory path with no spaces in the names at all.

For CrossWorks for ARM:  
* Download and unpack/install latest (3.x) version of [CrossWorks for ARM](http://www.rowley.co.uk/arm/index.htm). It is best to install it to a directory path with no spaces in the names at all. You do not need to run this version, we just need the build toolchain.  You could also copy the files from an existing install into a folder path with no spaces (at minimum, the following 3 folders are expected to be inside the CW install folder: `gcc/arm-none-eabi/bin, lib, include`, and optionally the `bin/version.txt` file for automatic version detection in the _Makefile_).

###### Configure and Build

1. In a plain-text editor, create a new file in the root of this project named _Makefile.user_ (it goes next to the existing _Makefile_).
2. Enter the following on a line of the new file:  
    `CC_PATH ?= [path to toolchain]`  
    where "[path to toolchain]" is the path to where you installed GNU ARM or CrossWorks. This can be absolute or relative to the location of the _Makefile_.  Eg.  
    `CC_PATH ?= /usr/share/gcc/5.4` or `CC_PATH ?= c:/devel/crossworks_for_arm`  
    **On Windows** always use forward slashes in directory paths (see Notes for Windows users, below).
4. **GNU ARM Embedded only:** in _Makefile.user_, specify that you want to use GAE, like this:  
    `TOOLCHAIN = GAE`
4. **Crossworks only:** in _Makefile.user_, specify the CrossWorks version on a new line, like this:  
    `CW_VERSION = 3.7.1`
4. **Windows only:** in _Makefile.user_, also specify a path to the `mkdir` utility, like this:  
    `EXE_MKDIR = c:/[path to GNU utils]/mkdir`  
    where the "[path to GNU utils]" part would be wherever you have installed GNU tools (see Notes for Windows Users, below). Eg.  
    `EXE_MKDIR = c:/cygwin/bin/mkdir`.  
    _You can avoid this step if your GNU tools are on the `PATH` before the Windows system folders (see example batch file, below)._
5. Open a terminal/command prompt and navigate (`cd`) to the root of the project (where the _Makefile_ lives). 
6. Type the command `make` and see what happens.  With no other arguments, this should build a default firmware version for AQ6 revision 1 with DIMU. The binary should appear in a new `build/Release` folder.
7. To change the AQ hardware version, pass `BOARD_VER` and `BOARD_REV` arguments to `make`.  Eg. `make BOARD_VER=8 BOARD_REV=6` to build for M4 rev 6 (M4 v2). You could also put these in your _Makefile.user_ file.  Read the _Makefile_ for full list of versions and revisions available.

###### Tips for using _Makefile_

1. Read the _Makefile_ comments for more options, full list of build targets, and other information.
2. Use `-jX` for faster (parallel) compilation, where "X" equals the number of CPUs/cores/threads on your computer.  If you have `make` version 4+, also add the `-O` option for better progress output during compilation. Eg. `make -j8 -O` for a quad-core CPU.
3. The _Makefile.user_ file is the right place to specify build options you typically want, then you can avoid entering them on the command-line each time, or editing the main _Makefile_. You can also set any variable in the environment and `make` will use it instead of the default in the _Makefile_. Command-line options always override all other variables.
4. All directory paths are relative to the location of the _Makefile_. You can use relative or absolute paths for most options.  Paths should not contain spaces.
4. You can easily set up a local environment and specify build options using a batch or shell file. This is especially useful for Windows so you can specify a local `PATH` variable w/out having to change the system-wide `PATH` (and need to restart Windows). The order of the `PATH` entries also affects how Windows searches for commands (making it easy to, for example, override Windows' `mkidir` with GNU tools `mkdir`). 

Here is a basic example batch file to initiate a build (this also shows using environment variables to set all the build options):

```batchfile
@echo off
:: configure paths to compiler toolchain and GNU utilities
set PATH=c:\devel\gcc\5.4;c:\devel\cygwin\bin;%PATH%
:: toolchain path again, forward slashes for Makefile syntax
set CC_PATH=c:/devel/gcc/5.4
:: configure build options
set BUILD_TYPE=Release-M4.r6
set BOARD_VER=8
set BOARD_REV=6
set TOOLCHAIN=GAE
:: build
make bin 
```

###### Notes for Windows Users:

You will need some GNU (Unix/Linux) tools installed and in your [`PATH`](http://www.howtogeek.com/118594/how-to-edit-your-system-path-for-easy-command-line-access/). Make sure to install them on a path with no spaces (eg. `c:/cygwin/`) There are several good sources for these, including [Cygwin](https://cygwin.com/install.html) (recommended), [GnuWin32 CoreUtils](http://gnuwin32.sourceforge.net/packages/coreutils.htm), and [ezwinports](http://sourceforge.net/projects/ezwinports/files/). The following utilities are required: 

`sh, make, gawk, mv, echo, rm, mkdir, cat, expr, zip`. 

If using Cygwin, make sure the "make" package is installed from the "Devel" category.  The other Devel packages are not required.

Some distributions include an older version of 'make' (3.x). Version 4.x offers some improvements for parallel builds. Windows versions are available in current Cygwin distributions and from [ezwinports](http://sourceforge.net/projects/ezwinports/files/) (get a "w/out guile" version), or [Equation Solution](http://www.equation.com/servlet/equation.cmd?fa=make) (64 or 32 bit version, depending on your Windows type).

Note that all directory paths used by `make` should have forward slashes (`/`) instead of typical Windows backslashes (`\`).

