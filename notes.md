#How FIG Forth uses the 6502 CPU

FIG Forth implementation is tightly coupled to how the 6502 CPU works.
This is not unusual in such memory and capability contrained systems.

## Registers
The 6502 has 3 main registers plus 3 special registers:
- A = Accumulator. An 8 bit register used for all match operations.
- X = X register. Used in Forth as the Forth stack pointer.
- Y = Y register. Used in Forth for general purpose offsets.
- PC = 16 bit Programme counter. The address of the current instruction. Forth uses this extensively e.g. in the link list to create jumps to the executable code of the next word.
- S = 8 bit stack pointer. The 6502 CPU stack is a hardware stack starting at $0100 - $01FF. Stack starts at $01FF and counts downwards.
- P = 7 bit processor status. This contains logical bits of the last operation. n for negative (bit 7 = 1), v for overflow,  b for break, d for decimal, i for interupts disabled, x for is zero, c for carry

## Words and bytes
In the 6502 a byte is one octet (8 bits). A word is 2 octets (16 bits). Words are stored with the least significant byte first. Forth directly links to this, so all values on the stack are 16 bit signed integers.

The 6502 has special Zero Page instructions ($0000-$00FF). These use one byte adddress and are faster. Forth uses these instructions directly eto implement the Forth stack. That means the Forth stack is limited by the hardware and cannot be relocated without a huge rewrite of the assembly.

   
#How the Dictionary Works

In Forth, the dictionary holds the set of Forth words that can be executed. The dictionary consists of primitive words (machine code definitions) and high level utility definitions. Users can extend the dictionary with new words by referenceing other words in the dictionary to create more complex programmes. The dictionary is stored as a linked list.

# Primitive Words

Primitive words are Forth words that contain machine executable code. In other words, primitives link directly to the underlying assembly code which is read and executed by the CPU. There is no "byte code" or intermediate abstraction layer.

## Example Primitive Word in the Dictionary "OR"
```
;                                       OR
;                                       SCREEN 25 LINE 7
;
L469:     
          .BYTE $82,"O",$D2
          .WORD L453     ; link to AND
OR:       
          .WORD *+2
          LDA 0,X
          ORA 2,X
          PHA 
          LDA 1,X
          ORA 3,X
          INX
          INX 
          JMP PUT
;
```

## with comments

```
;                                       OR                 <- name of the word
;                                       SCREEN 25 LINE 7   <- source reference of the original Forth code
;
L469:                                   <- a unique label for the linked list item, no real meaning
          .BYTE $82,"O",$D2             <- count of the word length in bits 0-5 (2 in this case)
                                        <- letter 'O' in ASCII
                                        <- letter 'R' with bit7 set
          .WORD L453     ; link to AND  <- link to the previous word in the linked list
OR:                                     <- label for the start of assembler code
          .WORD *+2                     <- this is where execution jumps 2
                                        <- *+2 is the programme counter +2 -> LDA
          LDA 0,X                       <- the stack is referenced in Zero Page
                                           using the 6502 X register
                                        <- 0,X points to the top of the stack
                                        <- Each stack entry is 1 word = 2 octets.
          ORA 2,X                       <- logical OR with next stack entry bottom nibble
          PHA                           <- preserve the A register on the CPU stack
          LDA 1,X                       <- get the top nibble
          ORA 3,X                       <- logical OR with next stack entry top nibble
          INX                           <- move stack pointer up 2 octets
          INX                           <- which drops 1 word off the stack
          JMP PUT                       <- store A and A from the CPU stack
                                        <- on to the Forth stack
;

```

# Variable length words

FIG-Forth uses variable length words. Other implementations of Forth generally use the first 3 characters and the length to encode a word in the Dictionary.

1. The first byte of the name field has the natural character count in the low 5 bits (0-4).
2. The sixth bit (bit 5) = 1 when smudged, and will prevent a match by (FIND).
3. The seventh bit (bit 6) *= 1 for IMMEDIATE definitions; it is called the precedence bit.
4. The eighth or sign bit (but 7) is always = 1 for the 1st byte of the word.

5. The following bytes contain the names' letters, up to the value in WIDTH.
6. In the byte containing the last letter saved, the sign bit = 1. (in the example this is ASCII for 'R' OR #$80.
7. In word addressing computer, a name may be padded with a blank to a word boundary.


## Forth variables
```
IP      Interpretative Pointer. A Zero Page location pointing to the current word.
```
## Forth subroutines

```
NEXT:   moves the Forth machine to the next word to execute by executing the
        zero page zump to the address stored at W and W+1.

        If you're confused about the assembler
        JMP W-1 ; (absolute!) in NEXT
        it's because it's a double indirection.
        In the warm start there's a couple of instructions to bootstrap this:
        LDA #$6C
        STA W-1
        #$6C is the 6502 opcode for JMP (relative)
        so it 1st jumps to W-1 and then executes a JMP (link address) 
        where link has been stored previously by NEXT to point to the next word.
        That's also why the words can't end on a page boundary, because
        JMP relative doesn't handle the carry well on addition e.g. 03FF->0300.
```

```
PUSH:   places A and A stored at the top of the CPU stack onto the Forth stack
        extensively used to store the results of stack operations.
```

```
TRACE:  outputs trace information on the status of the Forth machine.
        format:
        <CR><LF>
        <IP>
        < >
        <Word Name>
        <Code Field Address>
        < >
        <Forth stack location>               <- X register
        < >
        <Hardware/return stack location>     <- S register
```

#Lessons Learned during porting

It takes a while to load the hex on my hardware (12 minutes) which means testing takes quite a while.  :D

1) the LDY #0 inserted in BRAN to get things working was definitely a red herring. I could replace that with 2 * NOP and the code runs. Both have been removed from teh repository.

2) My hardware 6502 is NMOS. Physically marked "UM6502 8945T" "N channel, silicon gate, depletion load technology". It could be fake of course. Or really old (week 45 of 1989). It probably suffers from the JMP indirect bug for indirect locations over a page boundary. http://www.6502.org/tutorials/6502opcodes.html#JMP

3) Interestingly, despite removing the dependency on the JMP indirect ($6C) opcode by changing NEXT, I am definitely seeing paging problems. Is there anywhere else in the code that is page sensitive to your knowledge? I couldn't find anything.

Padding the BRAN with NOP changes behaviour despite not having any $6C anywhere in the hex.
CODE:
SELECT ALL
L89       .BYTE $86,'BRANC',$C8
          .WORD L75      ; link to EXCECUTE
BRAN      .WORD *+2
          ; Ray. Y reg looks undefined. Assume Bug.
          ;LDY #0        ; set offset to IP to 0. Doesn't change C bit.
          NOP
          NOP
          NOP
          NOP
          ; end 
0 NOP => echoes but crashes on loop
1 NOP => all OK
2 NOP or LDY #0 => all OK
3 NOP => all OK
4 NOP => all OK

I checked the .hex file and the only difference is the code placing and branch recalculation (which look OK). File increases in size by one octet and direct JMP calculations also move 1 octet.


*I apparently missed the JMP W-1 in EXECUTE, which explains the above.

Anyway, I reverted this change to go back to simple padding on an even page.


4) Lesson learned: The lib6502 emulator isn't transparent on keyboard input, at least running under Linux shell. :(

I wrote a small extra debug and entering both Ctrl-J and Ctrl-M actually send ASCII $0A (LF) to the INCH code. Other control characters ctrl-A to ctrl-O are sent transparently. So that explains 100% the emulator behaviour if anyone else hits this and finds this post. I couldn't find any switch to change this as it seems to be a hard-coded function of the Linux Terminal app. ctrl-v ctrl-m did send ctrl-m but then there's a LF for enter ....

So I altered INCH to translate #$0A to #$0D. Problem solved :)
CODE:
SELECT ALL
YSAVE     =XSAVE+2        ; temporary for Y register.

INCH:
    sty YSAVE
    lda $E000
    ldy YSAVE

                          ; lib6502 always send LF, even for Ctrl-M
    cmp #$0A              ; LF
    bne eofs
    lda #$0D              ; CR
 eofs:
; EOF ?
    cmp #$FF ; also clean carry :)
    beq byes
    rts
    
; exit for emulator  
byes:
    jmp $0000

5) Lesson Learned: A reliable way to add padding to avoid page boundaries

I inserted my monitor code between CLIT and DECNP/EXECUTE (in place of TRACE and TCOLON). I think that was the root cause of most of my problems. I have now relocated the monitor code to be directly after the warm start RENTR and before LIT. Then it becomes more obvious where the padding is needed: in the same place as the original code.

I was struggling on how to check the alignment in the symbol table. There is an easy way....

Lesson Learned: You can check padding for page alignment by examining the .lst file generated by ca65 and look for the location of the label 'LIT' (which is the first word in the Forth dictionary). Then check for even alignment of the code pointer that points to the opcode LDA (IP),Y. i.e. the memory contents at the location of symbol LIT must be an even number in the lower nibble. This avoids any page overflow (and associated bugs) on indirect lookups.

