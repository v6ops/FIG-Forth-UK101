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
out2monitor.pl   is PERL code to reformat raw hex into input commands for the CEGMON monitor

FIG Forth uses a double indirect in the NEXT routine. What does that mean?
The contents of the Code Field is copied from the dictionary are copied to memory location W and W+1. The location W-1 contains $6C = JMP (relative).
The 6502 doesn;'t handle the carry if the lower nibble (W) is 0x$FF.

```
;
;    NEXT is the address interpreter that moves from machine
;    level word to word.
;
NEXT:     LDY #1
          LDA (IP),Y     ; Fetch code field address pointed
          STA W+1        ; to by IP.
          DEY
          LDA (IP),Y
          STA W
;         JSR TRACE      ; Remove this when all is well
          CLC            ; Increment IP by two.
          LDA IP
          ADC #2
          STA IP
          BCC L54
          INC IP+1
L54:      JMP W-1        ; Jump to an indirect jump (W) which
```

You can check the code field labels using:
```
grep '*+2' *.lst|grep FF
```

The important thing is that the first octet is no #$FF.

To adjust this enter a value after the line .org *+2 reserving space using extra NOP (No Operation) instructions. THis is only relevant for primitive words that embed 6502 machine code directly in the dictionary.
```
;         .org *+2
NOP
```

