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
