# pc9801-assembly-toys

Some toy programs for the NEC PC-9801 series of computer, made in x86 assembly language.

NASM and Python are required to build the various programs, whose list is the following:

- _helloworld.asm_: prints "Hello, world!" on the second line of the display.
- _helloserial.asm_: prints "Hello, serial port world!" through the main RS-232C port.
- _soundtest.asm_: blasts a 440Hz square tone on the PC-98 speaker, or your headphone. A reset is needed to stop it.
- _biosdump.asm_: dumps the PC-9801 over the serial port, using the XMODEM protocol. Start this program before starting the XMODEM reciever.

Just run `make` to build everything.

Currently, nothing uses BIOS routines, these are just programs toying with the hardware.

## How to run the programs?

The expected runtime environment is the built-in N88-BASIC(86) environment, found on PC98s built
before 1993 or so.

You can download the programs as BASIC programs over the serial line by using the `LOAD "COM:N81NN"` command. Send the BASIC files as ASCII files with a terminal program on a modern computer, such as Minicom.

One a program is loaded on the PC-9801, just hit F5.

The `Direct statement in file` error at the end of file loading is expected: it seems there's no
way of properly ending the load.

## Do the programs work?

Well, they do on my PC-9801DA, at least. Your mileage may vary.
