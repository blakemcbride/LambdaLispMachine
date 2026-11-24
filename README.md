# NOTICE

This is a maintained fork of Daniel Seagraves' LambdaDelta
(https://github.com/dseagrav/ld), which its author placed on indefinite
hiatus in December 2020. The fork builds with current compilers and uses
SDL3. It also carries the emulator fixes from the tumbleweed.nu fork
(https://tumbleweed.nu/r/ld/), including two upstream pull requests by
Björn Victor that were never merged.

This repository is self-contained: besides the emulator source it holds the
ROM images, tape images, already-installed disk images, the surviving LMI
software archives and the LMI documentation. See
[Quick Start](#quick-start) and [What Is In This Repository](#what-is-in-this-repository).

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [LAMBDADELTA](#lambdadelta)
    - [About the Lambda](#about-the-lambda)
    - [Contact](#contact)
- [Quick Start](#quick-start)
    - [A Ready-Made Machine](#a-ready-made-machine)
    - [Bogodyne ZetaLisp](#bogodyne-zetalisp)
    - [The 2017 Release 5.0 Kit](#the-2017-release-50-kit)
- [What Is In This Repository](#what-is-in-this-repository)
- [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Building LambdaDelta](#building-lambdadelta)
- [Configuring LambdaDelta](#configuring-lambdadelta)
- [Using LambdaDelta](#using-lambdadelta)
    - [Exiting](#exiting)
    - [Network](#network)
    - [Preparing ROM Images](#preparing-rom-images)
    - [Microcode Symbol Files](#microcode-symbol-files)
    - [Installing a New Machine](#installing-a-new-machine)
- [Working With the Lisp System](#working-with-the-lisp-system)

<!-- markdown-toc end -->
# LAMBDADELTA

LambdaDelta is an emulator of the LMI Lambda Lisp Machine. Its goal is to
simulate the hardware sufficiently to run original microcode and binaries
unmodified, with performance and capability comparable to the original
hardware.

LambdaDelta is written in C. It is intended to be portable to any reasonably
Unix-like operating system, but is developed primarily on Linux. The initial
versions will most likely fail to compile elsewhere, but attempts will be
made to rectify this as soon as practical.

SDL Version 3 is used for console IO, the Linux tuntap driver or
Berkeley Packet Filter is used for network IO, and standard Unix file
operations are used for disk and tape IO. LambdaDelta includes code from the
Fake86 project by Mike Chambers in its SDU implementation.

LambdaDelta is licensed under the GNU GPL Version 2 or later at your option.
Please see the file COPYING for details.

## About the Lambda

The LMI Lambda is a NuBus-based machine consisting of at least one Lambda
processor, a System Diagnostic Unit, and various NuBus and Multibus
peripherals. The System Diagnostic Unit has an Intel 8088 processor, and is
responsible for bootstrapping the Lambda processor. The Lambda processor is
made up of four cards in a specially wired area of the NuBus backplane.
The standard Multibus peripherals are a 3Com ethernet interface, an
Interphase SMD disk controller, a Tapemaster 9-track tape controller,
and a Quarterback QIC tape controller (not emulated). The SDU software 
mediates sharing of Multibus peripherals. The SDU hardware provides a
DMA path between Multibus space and NuBus space with mapping hardware
for routing pages between targets on both busses.

The NuBus peripherals are memory and the VCMEM console controller. There
must be one VCMEM for each Lambda processor. The standard configuration
has one pair. An optional configuration called LAMBDA-2x2 has two pairs.
This enables two simultaneous and separate Lisp environments to share one
backplane, memory, disk, and network interface. The result was a
considerable cost savings over buying a second machine. The 2x2 machine
was also used for operating system development.

There was also an optional 68000-based Unix processor which could run
V7 or SVR4. No attempt was made to emulate this. A configuration with a
Unix processor was given the suffix "plus", making a "LAMBDA-PLUS"
(or "LAMBDA+") a single-user Lambda with a Unix processor and a 
"LAMBDA-2X2-PLUS" a two-user Lambda with a Unix processor.

## Contact

Questions, ideas, problems, solutions, praise, complaints, or baseless
accusations may be directed to the LispM mailing list on tunes.org.
See http://lists.tunes.org/mailman/listinfo/lispm/ for more information.

All contributors to this project are listed in the AUTHORS file.

Related projects: the tumbleweed.nu LambdaDelta fork
(https://tumbleweed.nu/r/ld/), maintained by Alfred M. Szmidt, and Björn
Victor's chaosnet-bridge (https://github.com/bictorv/chaosnet-bridge),
which links Chaosnet hosts, including emulated Lisp Machines, over the
Internet.

# Quick Start

This brings up a Lisp Listener using the included, already-installed disk
image (Lambda Release 5.0, System 130.0, microcode 1762).

    autoreconf -i
    ./configure
    make
    mkdir -p disks
    xz -dc installed/disk.img.xz > disks/disk.img
    cp installed/CMOS.RAM installed/RTC.RAM installed/ulambda.lmc-sym .
    cp examples/ld.conf ld.conf
    src/lam

If LambdaDelta was built with libyaml it reads `lam.yml` instead of
`ld.conf`; in that case create a `lam.yml` containing

    sdu:
      switch: 1

A window opens showing the SDU monitor prompt (`>>`). Type `newboot` and
press enter, and at the `Command:` prompt type `boot`. Or start the
emulator as `src/lam -a`, which types `newboot -a` for you, so Lisp boots
with no typing. Lisp takes about 20
seconds to start on a current PC (about a minute at the speed of a real
Lambda; see [Using LambdaDelta](#using-lambdadelta)). From there, continue at step 21 of
[Installing a New Machine](#installing-a-new-machine) to name the machine,
create its file system and restore the system sources from
`tapes/02_system.tap`, or use the ready-made machine below, where that has
been done.

Ethernet needs a tuntap interface and the privilege to open it. Without
that LambdaDelta prints `ether_init(): Operation not permitted` and runs
without a network. See [Network](#network).

## A Ready-Made Machine

`installed/lama` holds a Release 5.0 machine that is fully set up. It is
the host LAMBDA-A (LAMA), its file system holds the system sources and
compiled files, and its current band, LOD2, has the patches loaded
(System 130.12). From the top of the tree:

    mkdir -p disks
    xz -dc installed/lama/disk.img.xz > disks/disk.img
    cp installed/lama/CMOS.RAM installed/lama/RTC.RAM installed/ulambda.lmc-sym .
    cp examples/ld.conf ld.conf
    src/lam -a

It comes from the tumbleweed.nu fork (`LAMA-disk.img.xz` and
`LAMA-CMOS.RAM` at https://tumbleweed.nu/r/ld/uvlist). That image's SDU
configuration had been made by another build of the emulator and expected a
board in slot 12, so newboot stopped with `Got timeout initializing board
in slot 12`. The SDU `config` command was run on it once, rewriting the
three disk blocks of the SDU's configuration file; nothing else differs
from the original, whose SHA3-256 is
`206b4b9986c72aaa74324e88ebaee326fed119e6ebce6bd5010605c34b5c1f94`.

## Bogodyne ZetaLisp

The `zetalisp` directory holds Bogodyne ZetaLisp System 500.0 Release 1
(microcode 1764), a 2020 release of the Lambda system software by Daniel
Seagraves, LambdaDelta's author. It is unpacked from
`ZetaLisp_R1.0_20200813.tgz`, from
https://www.bogodyne.com/download/download-zetalisp/, and its license and
release notes are in `zetalisp/README.ZetaLisp`. The directory is laid out
as a LambdaDelta working directory with its own ROMs and tapes (its
`SDU.ROM` is SDU Monitor 102, where the top-level one is version 8), so run
the emulator from inside it. After building LambdaDelta:

    cd zetalisp
    mkdir -p disks
    xz -dc installed/disk.img.xz > disks/disk.img
    cp installed/CMOS.RAM installed/RTC.RAM .
    cp ../examples/ld.conf ld.conf
    ../src/lam

Then type `newboot` and `boot` as above. `zetalisp/installed` was made by
installing from the release's tapes through step 17 of
[Installing a New Machine](#installing-a-new-machine), and the rest of that
procedure applies from step 21, except that the backup tape to restore is
`tapes/01-distribution.tap`. To install from scratch instead, follow the
whole procedure in the `zetalisp` directory; there `install` loads
everything from `tapes/00-install.tap` in one pass (SDU software,
microcode into LMC1 and the band into LOD1), so `read-tape` is not needed.

The default ZetaLisp site uses DHCP and tries for a while to get an
address, reporting `DHCP: Failed to get an offer` when there is no
network. This does no harm.

The ZetaLisp site's time zone is US Central, while a new `RTC.RAM` starts
out with Eastern. On the first boot after installing from scratch, Lisp
warns that the time zone in the clock chip is wrong, and until the warning
is seen the clock is not set: the message area shows `Process Initialize
Timebase wants to type out` and the status line shows no time. Type
Terminal 0 S (F4, then 0, then S) to see it; Lisp then sets the clock and
stores Central in the clock chip, so later boots are quiet. The time it
sets was read before the warning, so it is behind by however long the
warning waited; boot again to get the right time.
`zetalisp/installed/RTC.RAM` already holds Central.

## The 2017 Release 5.0 Kit

`release5-2017` holds the Lambda Software Release 5.0 kit that Daniel
Seagraves put together in 2017 to fix problems in the last official
release, 4.0 (`Lambda-Release5.tar.gz`, from
https://tumbleweed.nu/r/attic/sys130/uv/). Its notice,
`release5-2017/README.Release5`, says that the release is experimental,
that it is not authorized or endorsed by GigaMos Systems or Lisp Machines
Incorporated, and that no license is expressed or implied. It has three
tapes, in `release5-2017/tapes`:

- `01_install.tap`: the SDU software, microcode 1764 and a System 131.1
  band, a later build than the top-level `00_install.tap` (microcode 1762,
  System 130.0). `install` loads all of it in one pass, into LMC1, LMC2,
  LOD1 and LOD3, so `read-tape` is not needed.
- `02_system.tap`: the system sources, a backup tape to restore with the
  Backup activity's Restore option.
- `03_options.tap`: the options kit, to load with the Backup activity's
  Install Distribution option. Its directories are GATEWAY (with
  GATEWAY;DATABASE), FONTS, DEMO, HARDCOPY;TIGER, EXAMPLES,
  WINDOW;WINDOW-MAKER, WINDOW;FONT-EDITOR, VIDEO-DEVICE;GREY, OBJECTLISP,
  NETWORK;KERMIT, NETWORK;EDIT and CUSTOMER-SITE. Bitsavers does not have
  this tape.

The directory is a LambdaDelta working directory (its `roms` is a link to
the top-level one), and `release5-2017/installed` was made by installing
`01_install.tap` through step 17 of
[Installing a New Machine](#installing-a-new-machine). After building
LambdaDelta:

    cd release5-2017
    mkdir -p disks
    xz -dc installed/disk.img.xz > disks/disk.img
    cp installed/CMOS.RAM installed/RTC.RAM .
    cp ../examples/ld.conf ld.conf
    ../src/lam -a

Then continue at step 21 of the installation procedure, restoring
`02_system.tap` and then installing `03_options.tap` (F12 changes tapes).
`release5-2017/ulambda.lmc-sym` is the ZetaLisp one: the two releases'
microcode 1764 is the same apart from the tape header.

# What Is In This Repository

| Path        | Contents |
|-------------|----------|
| `src`       | The emulator (`lam`) and the partition tool `lpart`. |
| `tools`     | Tape and disk image utilities, `lmfuse`, a FUSE view of an LMFS file system, and `lmftpput.sh`, which copies a directory tree to a Lisp Machine by FTP (see [Network](#network)). |
| `roms`      | The three ROM images the emulator loads, under the names it expects. |
| `firmware`  | The original Bitsavers firmware archives the ROM images came from, along with the PAL and PROM dumps for the other boards. |
| `tapes`     | Tape images. `00_install.tap` is the installation tape and `02_system.tap` is a Lisp backup tape of the system sources. The others are LMI Unix boot and distribution tapes and two unidentified tapes. |
| `installed` | A disk image (compressed) and matching CMOS/RTC contents produced by running the installation procedure below through step 17, and the symbol file for its microcode (version 1762), which the emulator needs in order to make Lisp's beep audible. `installed/lama` is a fully set-up machine; see [A Ready-Made Machine](#a-ready-made-machine). |
| `software`  | Archives of Lambda file systems (`dj_full.tgz`, `jb_full.tgz`) and the K-Machine software (`k_machine.tgz`). These hold the Lisp system sources as ordinary files. `software/zeta-c` is Scott Burson's Zeta-C, a C compiler for Lisp Machines that he placed in the public domain in 2003. Its sources have LMI conditionals, but this copy's system definition is the Symbolics Genera 7 one, so building it on the Lambda will need some porting; it has not been tried. |
| `doc`       | `KEYCODES` and `OLDCONF.md` for the emulator, and in `doc/lmi` the LMI manuals (Lisp, editors, hardware, Unix, release notes), the field service manual, SDU description, K-Machine material and board photographs. `doc/lmi/tapes.txt` describes the two main tapes. `doc/hardware` has the specifications of hardware the emulator models: TI's 1983 NuBus specification, the Ciprico Tapemaster product specification and application note, and the Interphase SMD 2180 disk controller manual. `doc/mit-lisp-machine-manual` is the MIT Lisp Machine Manual, 6th edition (1984), one PDF per chapter. It stands in for volume 1 of LMI's Lisp manual, which Bitsavers does not have; most of it applies to Lambda Lisp. |
| `examples`  | Sample configuration files. |
| `zetalisp`  | Bogodyne ZetaLisp System 500.0 Release 1, with an installed disk image; see [Bogodyne ZetaLisp](#bogodyne-zetalisp). |
| `release5-2017` | The 2017 Lambda Release 5.0 kit (install, system and options tapes), with an installed disk image; see [The 2017 Release 5.0 Kit](#the-2017-release-50-kit). |

The ROM, tape, software and documentation files came from Bitsavers
(http://www.bitsavers.org/): directories `pdf/lmi` and `bits/LMI`, and for
`doc/hardware`, `doc/mit-lisp-machine-manual` and `software/zeta-c`,
`pdf/ti/nubus`, `pdf/ciprico/tapemaster`, `pdf/interphase/SMD_2180`,
`pdf/mit/cadr/chinual_6thEd_Jan84` and `bits/TI/Explorer/zeta-c`.
`release5-2017` and `installed/lama` came from tumbleweed.nu.

# Getting Started

## Prerequisites 

To build LambdaDelta you need a C compiler, the GNU autotools, pkg-config
and the development files for SDL3 (3.2 or later). The libyaml development
files are optional but recommended (they enable the YAML configuration file),
and the FUSE 2 development files are needed only for the `lmfuse` tool.
On Fedora: `dnf install gcc make autoconf automake pkgconf SDL3-devel libyaml-devel`.

LambdaDelta requires a set of ROM images from a physical Lambda, and
either a disk image of an installed system or images of the installation
and source tapes. All of these are included in this repository: the ROM
images are in the `roms` directory under the names the emulator expects,
an installed disk image is in `installed`, and the installation tape
(`00_install.tap`) and system source tape (`02_system.tap`) are in the
`tapes` directory. The LMI manuals are in `doc/lmi`.

Bogodyne ZetaLisp System 500.0 Release 1 is included too, in `zetalisp`;
see [Bogodyne ZetaLisp](#bogodyne-zetalisp).

## Building LambdaDelta

LambdaDelta uses the GNU auto* tools for configuration and compilation.
Most features and libraries should be configured automatically when
the `configure` script is run.

To build from a git checkout:

    autoreconf -i
    ./configure
    make

The emulator is `src/lam`. It looks for the `roms`, `tapes` and `disks`
directories in its working directory, so run it from the top of the tree
(`src/lam`) unless you have configured a different working directory.

The console window may be resized; the Lambda screen is scaled to fit.

If you wish to emulate the optional 2x2 configuration, run configure
with the option `--enable-config-2x2=yes`

If you are in possession of a physical Lambda keyboard and/or mouse,
you may enable the use of these with the options `--enable-config-physkbd`
and `--enable-config-physms`. You will need to provide serial interface
hardware as required to communicate with these items.

After compilation, run-time options are controlled by a configuration
file. If you have the YAML library installed (and configure found it),
it will use YAML configuration. Otherwise, it will use the old
configuration file.

# Configuring LambdaDelta
This is the new configuration method that is intended to be used going
forward. The YAML configuration file is named `lam.yml` and is searched
for in the following places, in order: 

<!-- TODO: make this a link to the file -->
*Note:* If you do not have libyaml on your system (or do not wish to install it), please see doc/OLDCONF.md for the legacy configuration system..

1. The directory specified in `SYSCONFDIR` if it was defined during build.
2. The user's home directory, as determined by:
    1. The `$HOME` environment variable, or if that is not defined:
    2. If we are root and were run by sudo, from the sudoer's passwd entry.
    3. If we are root and were not run by sudo, root's passwd entry.
    4. If we are not root, the user's passwd entry.
3. The current working directory.

Any or all of these locations are valid; Configuration items in later
files supersede those specified in earlier files.

You may also specify a configuration file of any name on the command line
by using the `-c` argument. This file, if provided, is loaded last.

Single YAML key/value pairs may also be specified on the command line
by specifying them in the form  `--section-key value`. For example, the
argument `--log-ALL 10` will enable maximum logging of all types.

A full description of the YAML configuration file is beyond the scope
of this document; See the "lam.yml" file in the examples directory.

# Using LambdaDelta

By default LambdaDelta runs as fast as the host allows, several times the
speed of a real Lambda. The clocks Lisp reads (its microsecond clock, the
60 Hz vertical blank interrupt and the SDU's real-time clock) follow the
host's clock in this mode,
so time in Lisp passes at the right rate. To run at the 5 MHz of a real
Lambda instead, start the emulator with `-t`, or set `throttle on` in
`ld.conf` (`throttle: on` in the `lam` section of `lam.yml`).

Start the emulator with `-a` to boot Lisp with no typing. Five emulated
seconds after starting, once the SDU monitor's prompt is up, it types
`newboot -a`, which boots the current band. (The SDU drops keys typed
before its prompt appears.) `-a` does nothing when the SDU switch is 0.

While the program is running, the window title bar has the following form:

    LambdaDelta: VC N | Tape: FNAME | STATUS | Speed S

or, when throttled,

    LambdaDelta: VC N | Tape: FNAME | STATUS | DT X

N is the number of the active console, either 0 or 1. N is always zero when
the 2x2 configuration is not in use. `FNAME` is the name of the active tape
image file. `STATUS` is a string describing the state of the Lambda processor
associated with this console. The strings have the following meanings:

| Status string    | Meaning                                                                                                        |
|------------------|----------------------------------------------------------------------------------------------------------------|
| Cold Halted      | The processor has been powered on and has no state.                                                            |
| Cold Running     | The halt flag is clear but the state is unknown.                                                               |
| Cold Booting     | The bootstrap is running.                                                                                      |
| Lisp Boot Halted | The processor halted while Lisp was initializing. (This is an error condition.)                                |
| Lisp Booting     | Lisp is initializing or warm booting.                                                                          |
| Running          | Lisp is running.                                                                                               |
| Halted           | Lisp has stopped running. The processor has valid state. If you did not halt lisp, this is an error condition. |
           
S is how many times faster than a real Lambda the emulator ran over the
last second.

When throttled, after the status string is the time offset. X is a number in deciseconds
which indicates how far apart real time and the emulator's time are.
The emulator will try to hold this number at 0, but if your computer is
not fast enough to run the emulator in real time this number will become
negative and decrease further as the times diverge. If the number becomes
positive and increases, the throttle is not operating properly. This is a
bug which should be reported.

The following keys control emulator functions are cannot be remapped:

F9 switches the active console if the 2x2 configuration is enabled.
  If the standard configuration is in use, F9 may be remapped.
F10 changes mouse operation according to the configured mouse mode.
  In mode 0, F10 toggles capture and release of the mouse pointer. Clicking
  inside the LambdaDelta window while the mouse is not captured will
  recapture it.
  In mode 1, F10 toggles visibility of the host mouse pointer.

F11 simulates the "return to newboot" keyboard chord, which terminates Lisp
  and recalls the Newboot interface. Limitations of the keyboard emulation
  make typing the actual chord fail, so this directly sends the expected
  sequence of bytes to make things happen.

F12 causes the active tape image file to rotate to the next file in
  ASCIIbetical order. Pressing shift and F12 at the same time causes
  the emulator to dump its state into a bunch of .DUMP files and write
  screenshots. These files
  are human-readable but not necessarily human-understandable. (It is our
  understanding that whether or not the developers are classified as human
  is a subject of ongoing debate.) Sending the emulator a `SIGUSR1` signal
  writes just the screenshots, as `VC0-SCREENSHOT.BMP` and
  `VC1-SCREENSHOT.BMP`.

All other keys on the keyboard may be remapped using the map_key option
described above. The standard mapping preserves the printed key label
of the standard typewriter keys. The other keys are mapped as follows:

| HOST KEY   | LISPM KEY   | NOTES                                  |
|------------|-------------|----------------------------------------|
| [          | (           | [ is the shift state, ( is unshifted   |
| ]          | )           | ] is the shift state, ) is unshifted   |
| RETURN     | ENTER       |                                        |
| BACKSPACE  | RUBOUT      |                                        |
| UP         | HAND UP     |                                        |
| DOWN       | HAND DOWN   |                                        |
| LEFT       | HAND LEFT   |                                        |
| RIGHT      | HAND RIGHT  |                                        |
| PAGE UP    | ABORT       |                                        |
| PAGE DOWN  | RESUME      |                                        |
| F1         | SYSTEM      |                                        |
| F2         | NETWORK     |                                        |
| F3         | STATUS      |                                        |
| F4         | TERMINAL    |                                        |
| F5         | HELP        |                                        |
| F6         | CLEAR       |                                        |
| F7         | BREAK       |                                        |
| RIGHT CTRL | LEFT GREEK  |                                        |
| RIGHT ALT  | LEFT SUPER  |                                        |
| LEFT ALT   | LEFT META   |                                        |
| RIGHT FLAG | RIGHT SUPER | Does not always work on some platforms |
| LEFT FLAG  | LEFT SUPER  | Does not always work on some platforms |
| MENU       | RIGHT HYPER |                                        |

The default keymap is still under development and is subject to change. Feel
free to make suggestions or comments.

## Exiting

To exit LambdaDelta, close its window. This saves the SDU's CMOS and
clock contents to `CMOS.RAM` and `RTC.RAM` and ends the program. Sending
the emulator a `SIGTERM` signal does the same thing. If closing the window
does nothing, the `sdl_quit` configuration option (`quit` in the keyboard
section of the YAML configuration) has been turned off.

Typing control-C in the terminal LambdaDelta was started from kills it
at once without saving `CMOS.RAM` and `RTC.RAM`. That loses any changes
made to the SDU configuration during the session.

The disk image is written as the Lambda writes to its disk, so nothing
needs to be flushed on the way out. Exiting is the same as switching off a
real Lambda, though: anything in the running Lisp world that has not been
saved to a file is lost. Save your editor buffers first.

To stop Lisp without leaving the emulator, evaluate `(si:%halt)`, or
press F11 to return to Newboot, where the `boot` command starts Lisp again.

### Quitting from Lisp

Lisp can shut the emulator down itself. NuBus slot `#xFE` is empty, and
the emulator watches it: writing `#x51554954` to address 0 there ends the
emulator the same way closing its window does, saving `CMOS.RAM` and
`RTC.RAM`. Any other access to the slot times out as it would on an empty
slot. Define a `quit` command for it in a Lisp Listener:

    (defun quit ()
      "Shut down the LambdaDelta emulator, as closing its window does."
      (si:%nubus-write #xFE 0 #x51554954))

Then `(quit)` closes the emulator. The definition lasts only until Lisp is
booted again. To keep it, save the world to a spare band after defining it
and make that band the one that boots, for example
`(si:disk-save "LOD2")` and then `(si:set-current-band "LOD2")`.

## Network

The Lambda's 3Com Ethernet board is connected to a host tap interface,
`ldtap` by default. On Linux, create it once, owned by the user who runs
the emulator, and give the host an address on its network:

    sudo ip tuntap add ldtap mode tap user $USER
    sudo ip link set ldtap up
    sudo ip addr add 10.0.0.1/24 dev ldtap

The Lambda's MAC address is set by `ether_addr` in `ld.conf` (`address`
in the `network` section of `lam.yml`). Each Lambda on a network needs its
own. If you run more than one emulator, set it to `laa` instead of an
address: the emulator then makes up a random locally administered address
the first time, saves it in `IFACE.LAA` (for example `ldtap.LAA`) in the
working directory, and uses that from then on. Give the interface before
the address in the configuration file, since the file is named after it.

Lisp also has to know its address. For Release 5, see that
`SYS: SITE; SITE.LISP` has a network entry like

    (:NETWORK-NAMES '((("CUSTOMER-NETWORK")
                       ((:INTERNET "10.0.0.0" "255.255.255.0")
                        (:CHAOS 7)))))
    (:DEFAULT-INTERNET-ROUTING "10.0.0.1")

and that `SYS: SITE; HOSTS.TEXT` names the host and the Lambda:

    HOST LAMBDA-HOST,  [INTERNET 10.0.0.1],USER,UNIX,VAX
    HOST LAMBDA-A,     [INTERNET 10.0.0.2, CHAOS 3430],USER,LISPM,LISPM,[LAM-A,LAMA]

replacing the addresses as needed. Then recompile the site files and
reconfigure the network, and save the world with `disk-save` to keep the
change:

    (make-system 'site :recompile)
    (network:configure)

With the network up, `tools/lmftpput.sh DIR` writes an `expect` script
that copies every file under `DIR` to the Lisp Machine by FTP, making the
directories as it goes; pipe it to `expect -`. Edit `HOST` and `LM` at the
top of the script to the Lambda's IP address and host name first.

To reach other Lisp Machines over the Internet by Chaosnet, see
chaosnet-bridge (https://github.com/bictorv/chaosnet-bridge).

## Preparing ROM Images

The ROM images go in the "roms" subdirectory, and are already there in this
repository. The necessary files are:

- `SDU.ROM`: 
The SDU's 8088 program ROM. 64K, merged from two chips on the board. 
It is `combined.BIN` from `firmware/SDU_15165-0003.ZIP`, with an MD5
checksum of `4795bf46168808d32012213c0b370f30`.
- `MEM.ROM`:
The nubus-space configuration ROM for a memory card. 2K.
There are two in `firmware/Memory`: `2243902_OF_27S291.BIN`
(MD5 `21089f3b4082548865f8cda6017f302e`, the one installed as `MEM.ROM`)
and `OF_27S291.BIN` (MD5 `1f898d018a2e2ab29279ecf00c7a4c82`).
Either one may be used, but the same one will be used for both cards simulated.
- `VCMEM.ROM` - The VCMEM's nubus-space configuration ROM. 2K. 
This contains 8088 program code that will be run by the SDU. 
It is `U43_2516_2242843-0001_0856TI200038.BIN` from `firmware/VC_MEM.ZIP`,
with an MD5 checksum of `0e53416a49294f02c7fd925c9de47f5a`.

## Microcode Symbol Files

In the lisp source tree (included here in `software/dj_full.tgz`, under
`dj_full/l/ubin`) there are files named `bootstrap.lam-uload` and 
`ulambda.lmc-sym`, each with a version number suffix, which correspond to
the Lambda bootstrap code downloaded by the SDU and the Lisp microcode.
Place these, without the suffix, in the LambdaDelta directory
to provide symbols for debugging. These are optional, but without
`ulambda.lmc-sym` the emulator cannot find the microcode's beep routine,
so it prints `can't find XBEEP ucode address` and Lisp's beep is silent.
The symbol file must match the microcode version in use. The one for the
included disk image is `installed/ulambda.lmc-sym`; others are in
`software/dj_full.tgz` under `dj_full/l/ubin`.

## Installing a New Machine

The included `installed/disk.img.xz` is the result of steps 1 through 17,
so this procedure is needed only to build a machine from scratch. The ROM
and tape images it uses are already in `roms` and `tapes`.

1. Prepare your config file and create the disk image file, which must be
   the size of the disk being emulated. For the Eagle used below:
   `mkdir -p disks ; truncate -s 431104000 disks/disk.img`.
   Ensure the SDU switch setting is zero in your configuration.
2. Start the emulator. Telnet to port 3637 on the host. The emulator should
   start, and you should have a SDU prompt in your telnet session. You may
   disconnect and reconnect at any time.

   Ignore the graphical console for the now - It is inoperative until
   the SDU firmware partition is loaded and the CMOS contents are valid.

3. Type `init` and push enter to initialize the busses and SDU. The SDU will
   reboot.

4. Ensure the install tape is the active tape. (`tapes/00_install.tap`
   sorts first, so it is the active tape at startup.)

5. Give the SDU command `/tar/setup clear eagle sp shell`. Your CMOS should
   be initialized.

6. Give the SDU command `/tar/load` and follow the prompts. (Answer `y`
   to creating a new label and `1` for the number of Lambda processors.)

7. When the `load >` prompt appears, give the command `install` and follow
   the prompts. With the included `00_install.tap` this loads only the SDU
   software and then reports `End of tape`, because that tape has a double
   file mark after each band. Give the command `read-tape` three more times,
   pressing enter each time to accept the suggested partition, to load the
   microcode into LMC1 and LMC2 and the Lisp band into LOD1. The `print`
   command shows the label so you can check the result. Do not run `install`
   a second time; it rewinds the tape.

8. Give the command `q` to return to the SDU

9. Close the emulator by closing its window

10. Edit your config file file and change the SDU switch setting to 1

11. Restart the emulator. You should get a SDU prompt on the console.

12. Give the `config` command to initialize the Lambda configuration.
    When asked if you want to change anything, type y and press enter.

13. At the `cmd:` prompt, give the command `lambda`.

14. At the `lambda cmd:` prompt, give the command `switches`

15. At the `->` prompt, give the command `set use_multiplier`

16. Push enter to return to the lambda command level.

17. Give the command `x` until config reboots the SDU.

18. At this point your machine is configured and you can save backups of your
    ld.conf, disk image, and CMOS image file.

19. At the SDU prompt, give the command `newboot` to bring up the
    bootstrap program.

20. At the `Command:` prompt, give the command `boot` to start lisp.

21. When the REPL arrives, evaluate `(si:set-pack-name "LISPM-A")` to set
    the hostname.

22. Evaluate `(si:%halt)` to halt Lisp.

23. When Lisp halts, press F11 to summon Newboot again

24. At the `Command:` prompt, give the boot command to cold-boot Lisp.

25. When the REPL arrives, evaluate `(fs:initialize-file-system)` to 
    format the LMFS. Answer `Yes` when prompted for confirmation.

26. Push F12 to switch tapes to your distribution tape. The window title
    shows the active tape; the included system source tape is
    `02_system.tap`.

27. Type System-B to summon the Backup activity.

At this point you can follow the instructions included with the
distribution tape. If it is a backup tape, simply restore it. If it is
an actual distribution tape, it may have special loading procedures.
The included `02_system.tap` is a backup tape.

# Working With the Lisp System

These notes come from the tumbleweed.nu fork's README. They apply to the
Release 5 system with its sources restored.

## (Re)Compiling the Whole System

To compile the files of the system that need it, evaluate

    (make-system 'system)

After many changes it may be worth recompiling everything:

    (make-system 'system ':recompile)

## Assembling the Microcode

To assemble a new microcode load, evaluate

    (load "sys:ulambda;ucode")
    (make-system 'ucode)

With the Bitsavers system tape, `SYS: ULAMBDA; UC-LAMBDA-ARRAY.LISP`
fails to compile; open the file and save it without changes, then try
again.

To load the result (the latest `SYS: UBIN; ULAMBDA LMC`) into a microcode
partition, evaluate

    (si:load-lmc-file t 2) ; Or another suitable partition.

To test it, press F11 to return to Newboot, use the `set-uload` command at
the `Command:` prompt to pick the new microcode for this boot, and then
`boot`. To make it the default, evaluate `(set-current-microload "LMC2")`.

## Generating a New Cold Load Band

To load the cold load generator and build a cold load band, evaluate

    (make-system 'cold)
    (cold:make-cold 2) ; Or another suitable partition.

This takes about 20 minutes on a current PC. Booting the band needs the
MINI server, so in a 2x2 configuration start it on the first processor
(System-7, F1 then 7, and in the right pane evaluate
`(mini-server-process)`), switch to the second with F9 and evaluate
`(disk-restore 2)`. When the cold load band has booted, evaluate
`(si:qld)` to load the rest of the system. When the new system works,
make it the default band with `(set-current-band "LOD2")`.

## Making Distribution Tapes

A distribution is two tapes: the install tape (installation software,
microcode and load band) and a backup tape of the SYS tree. To make one,
load `SYS: RELEASE; MAKE-TAPE.LISP` and `SYS: RELEASE; DEFTAPES.LISP`,
then evaluate `(SET-RELEASE)` and `(MAKE-PRODUCT-TAPE)` and choose the
kind of tape. `tools/dumptape` splits a tape image into its files; on the
install tape these are:

| File         | Contents |
|--------------|----------|
| `file-0.dat` | Tape header |
| `file-1.dat` | A tar archive of the SDU installation programs (`setup`, `load` and others) |
| `file-2.dat` | The UNX6 partition (SDU file system) |
| `file-3.dat` | LMC1 (Lambda microcode) |
| `file-4.dat` | LMC2 (Lambda microcode) |
| `file-5.dat` | LOD1 (Lisp load band) |

## Debugging the Other Processor

In a 2x2 configuration one processor can debug the other. Evaluate
`(lam:setup)` and choose the "local" option. Then System Control-D (F1,
then Control-D) starts the debugger; in its top pane choose `LAM for
novice` and use the menu on the right.

## Partition Names and More Disks

The Lambda can use several disk units, and the names of their partitions
matter. The first character of a partition's name must be the unit it is
on, so a FILE partition on unit 1 has to be named 1ILE or 1FILE. The last
character of the name of a partition holding writable data says which
processor uses it: PAGE, METR and FILE belong to the first processor and
PAG1, MET1 and FIL1 to the second.

The real Lambda could handle only two disk units, though its controller
supports four, as LambdaDelta does. To label a new disk, give the SDU
commands `/tar/setup clear eagle sp shell` and `/tar/load`, and at the
`load >` prompt `unit N`.
