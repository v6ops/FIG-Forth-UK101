# FIG-Forth-UK101

Port of FIG-Forth (6502 Assembler) to Compukit UK101 / Ohio Scientific Instruments Challenger 1E

OSI C1E was my first computer (around 45 years ago). I also had Forth on tape (which has long been discarded in the bin. FIG-Forth was published by the Forth Interest Group in the USA, which I believe is now defunct. So this is a bit of nostalgia and a bit of history.

If you can work out the licence, I'll apply that directly to my own port.

Aim is to have FIG Forth running either in a 6502 emulator, or on real 6502 hardware (Grant Searle UK101).

zip of original code downloaded from http://6502.org/documents/downloads/source/interpreters/forth65.zip

asm2ca65.pl      is PERL code to text edit rockwell AIM assembler syntax to ca65
out2monitor.pl   is PERL code to reformat raw hex into input commands for the CEGMON monitor
