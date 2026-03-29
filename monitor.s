; Ray Hunter 2026
; This code updates the i/o routines for either
; - the original monitor code so you can diff for invariance
; - UK101 hardware with CEGMON monitor
; - the simulator code

; use the original FIG-Forth code
use_original_figforth = 0
; include the io code for the OSI C1E or UK101
use_UK101_io = 1
; otherwise the 6502 emulator code will be used
use_6502_emulator = 0


.if    use_original_figforth       ; this is the original code from FIG-Forth
                                      ; these symbols are commented out in FIG6502.s
ORIG      =$0200         ; start of the code page
TIBX      =$0100         ; terminal input buffer of 84 bytes.


;         Monitor calls for terminal support
;         
OUTCH     =$D2C1         ; output one ASCII char. to term.
INCH      =$D1DC         ; input one ASCII char. to term.
TCR       =$D0F1         ; terminal return and line feed.

;    Monitor routines needed to trace.
;         
XBLANK    =$D0AF         ; print one blank
CRLF      =$D0D2         ; print a carriage return and line feed.
HEX2      =$D2CE         ; print accum as two hex numbers
LETTER    =$D2C1         ; print accum as one ASCII character
ONEKEY    =$D1DC         ; wait for keystroke
XW        =$12           ; scratch reg. to next code field add
NP        =$14           ; scratch reg. pointing to name field
.endif

.if use_UK101_io
;   start UK101 hardware 
;    We assume CEGMON is installed. Otherwise you'll have to write your own i/o
;    This is a small piece of RAM in the C1E / UK101 that was free
;    for user machine code. Create a symbol for possible future use.
PAGE2START =$0240         ; above CEGMON which ends at $0234
PAGE2END   =$02FF         ; below BASIC or other code which starts at $0300

ORIG      =$0400         ; start of the code page. use $0400 to avoid used space
TIBX      =$0240         ; terminal input buffer of 84 bytes.

; Ray Hunter 2026 inspired from code for the Ohio Scientific C1E or UK101
; BY G. SEARLE 2013 and the authors of CEGMON 1980
INPUT  := $FB46           ; blocking input routine in CEGMON
OUTPUT := $FF9B           ; output routine in CEGMON
TCR    := $FBF5           ; output CRLF to terminal. used by FIG-Forth
; symbols for FIG-Forth Trace
CRLF   := $FBF5           ; output CRLF to terminal. also used by FIG-Forth
SPCOUT := $FBE6           ; output <space> to terminal
XBLANK := SPCOUT          ; output <space> to terminal. used by FIG-Forth
LETTER := OUTCH           ; used by FIG-Forth
ONEKEY := INCH            ; used by FIG-Forth
XW        =$E0            ; scratch reg. to next code field add
NP        =$E2            ; scratch reg. pointing to name field

INCH:                     ; used by FIG-Forth
    jsr INPUT
eofs:
; EOF ?
    cmp #$04 ; ctrl-d to exit (choice of char is arbitrary). also clean carry :)
    beq byes
    rts
OUTCH:                    ; used by FIG-Forth
    pha
    cmp #13    ; convert CR to print CR/LF. Possibly not reliable for all code.
    bne not_cr
    jsr OUTPUT ; output the CR
    lda #10 ; LF ; and now add an LF
not_cr:
    jsr OUTPUT
    pla
    rts
; exit to CEGMON NEWMON (machine code monitor)
byes:
    jmp $FE00
; end Ray Hunter inspired from code by Grant Searle and authors of CEGMON
;   end UK101 hardware 


HEXOUT:
    and #$0F            ; mask to lower nibble only
    cmp	#$0A		; set carry for +1 if >9	
    bcc NoAdjust	; branch if <=9
    adc #6		; adjust if A to F
			; (six plus carry = 7!)
NoAdjust:
    adc #$30		; add ASCII "0"
    jmp OUTCH

HEX2:                    ; this could almost certainly be made more compact
    pha                  ; save accum for later
    lsr a                ; upper nibble only
    lsr a
    lsr a
    lsr a
    jsr HEXOUT           ; print the upper nibble
    pla
    jmp HEXOUT           ; print the lower nibble


.endif  ; use_UK101_io

.if use_6502_emulator  ; use_6502_emulator

;   start lib6502 emulator
ORIG      =$0400         ; start of the code page. use $0400 to avoid used space
TIBX      =$0100         ; terminal input buffer of 84 bytes.
INCH:
    lda $E000
eofs:
; EOF ?
    cmp #$FF ; also clean carry :)
    beq byes
    rts

OUTCH:
    sta $E000
    rts

; exit for emulator  
byes:
    jmp $0000
;

CRLF:
    lda #10
    jsr OUTCH
    lda #13
    jmp OUTCH

TCR    := CRLF
LETTER := OUTCH
ONEKEY := INCH

SPCOUT:
    lda #32
    jmp OUTCH

XBLANK := SPCOUT
XW        =$12           ; scratch reg. to next code field add
NP        =$14           ; scratch reg. pointing to name field

HEXOUT:
    and #$0F            ; mask to lower nibble only
    cmp	#$0A		; set carry for +1 if >9	
    bcc NoAdjust	; branch if <=9
    adc #6		; adjust if A to F
			; (six plus carry = 7!)
NoAdjust:
    adc #$30		; add ASCII "0"
    jmp OUTCH

HEX2:                    ; this could almost certainly be made more compact
    pha                  ; save accum for later
    lsr a                ; upper nibble only
    lsr a
    lsr a
    lsr a
    jsr HEXOUT           ; print the upper nibble
    pla
    jmp HEXOUT           ; print the lower nibble

;   end lib6502 emulator
;---------------------------------------------------------------------
.endif  ; use_6502_emulator


