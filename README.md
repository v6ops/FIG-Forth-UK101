# TL/DR;
There are two ways to run the code: via a 6502 simulator or via UK101 hardware.

You need to install lib6502 to run in simlator mode and ca65 to re-assemble (if you change anything) 

## install simulator
    mkdir lib6502
    cd lib6502
    git checkout https://github.com/ShonFrazier/lib6502
    cd lib6502
    make
    make install

## install ca65 - part of cc65
    apt install cc65

## run pre-assembled code in the simulator
    cd ~/FIG-Forth
    make run

## run on UK101 hardware with CEGMON
    cd ~/FIG-Forth
    vi monitor.s
    use_UK101_io = 1
    ; otherwise the 6502 emulator code will be used
    use_6502_emulator = 0

    make
    ./out2monitor.pl FIG6502
    cat FIG6502.mon
    <paste into CEGMON monitor on your UK101>


# FIG-Forth-UK101

Port of FIG-Forth (6502 Assembler) to Compukit UK101 / Ohio Scientific Instruments Challenger 1E

OSI C1E was my first computer (around 45 years ago). I also had Forth on tape (which has long been discarded in the bin. FIG-Forth was published by the Forth Interest Group in the USA, which I believe is now defunct. So this is a bit of nostalgia and a bit of history.

If you can work out the licence, I'll apply that directly to my own port.

Aim is to have FIG Forth running either in a 6502 emulator, or on real 6502 hardware (Grant Searle UK101).

zip of original code downloaded from http://6502.org/documents/downloads/source/interpreters/forth65.zip

asm2ca65.pl      is PERL code to text edit rockwell AIM assembler syntax to ca65
                 It can output monitor i/o for:
                 1. the original FIG Forth code (for diff)
                 2. OSI C1E UK101 code for loading into hardware
                 3. 6502 emulator for loading into https://github.com/ShonFrazier/lib6502
Change the use variables to select which monitor code to assemble.
Only one can be active.

; use the original FIG-Forth code
use_original_figforth = 0
; include the io code for the OSI C1E or UK101
use_UK101_io = 0
; otherwise the 6502 emulator code will be used
use_6502_emulator = 1
usage ./asm2ca65.pl FIG6502

You don't need to run this if you haven't edited FIG6502.ASM.

out2monitor.pl   is PERL code to reformat raw hex into input commands for the CEGMON monitor. usage ./out2monitor.pl FIG6502


FIG Forth uses a double indirect in the NEXT routine. What does that mean?
The contents of the Code Field is copied from the dictionary are copied to memory location W and W+1. The location W-1 contains $6C = JMP (relative).

Some hardware versions of the 6502 doesn't handle the carry if the lower nibble (W) is 0x$FF. See notes.md for details.



