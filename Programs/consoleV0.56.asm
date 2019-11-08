#include "cpudef.asm"

;Console_v0

bootload:
    #addr 0x00
    MOV Si, #0x00                       ; RAM program start address to be copied to
    MOV Di, #start                      ; ROM address to start copying from
    MOV Rd, #(end - start + 1)[7:0]     ; RAM program length (LSB), (rows)
    MOV Rc, #(end - start + 1)[15:8]    ; RAM program length (MSB), (pages)
    MOV Rb, #0x00                       ; Set Rb to 0x00 to compare

copyseq:
    CMP Rb, Rd        ; check row count
    JZ [#copyseqNP]   ; if zero, write byte and decrease page count
    CPY [Si], [Di]    ; Copy from ROM to RAM at desired locations(auto increment)
    DEC Rd            ; decrease row counter
    MOV PC, #copyseq  ; copy next row
copyseqNP:     
    CMP Rb, Rc        ; check if there are any more pages to copy
    JZ [#vectorLoad]  
    CPY [Si], [Di]    ; don't forget to copy this byte
    DEC Rc            ; If yes, decrease page counter
    DEC Rd            ; and reset row counter (0xFF)
    MOV PC, #copyseq  ; And copy next page

vectorLoad:
    MOV Si, #0xFEFE   ; copy keyboard address handler
    MOV Di, #kbHandler
    MOV Rd, #(kbEnd - kbHandler + 1)[7:0]     ; handler length (LSB)
    MOV Rc, #(kbEnd - kbHandler + 1)[15:8]          ; handler length (MSB)

copyHan:
    CMP Rb, Rd        ; check row count
    JZ [#copyHanNP]   ; if zero, write byte and decrease page count
    CPY [Si], [Di]    ; Copy from ROM to RAM at desired locations(auto increment)
    DEC Rd            ; decrease row counter
    MOV PC, #copyHan  ; copy next row
copyHanNP:    
    CMP Rb, Rc        ; check if there are any more pages to copy
    JZ [#endBootload]
    CPY [Si], [Di]    ; don't forget to copy this byte   
    DEC Rc            ; If yes, decrease page counter
    DEC Rd            ; and reset row counter (0xFF)
    MOV PC, #copyHan  ; And copy next page


endBootload:
    MOV Ra, STT       ; STT |= 0x40
    MOV Rb, #0x40
    OR  Ra, Rb
    MOV PC, #memswitch  ; Next instruction will change instruction fetch
                        ; memory device

; RAM
rv = 0x8000     ; start address to store variables
inputBuffer = 0x80FF
; Variable map
    ; '_'	prefix means is local variable
    ; rv+0 	short cursor x
    ; rv+1 	short cursor y
    ; _rv+2 char shifted char data
    ; _rv+3 short i in writeChar
    ; _rv+4 short j in writeChar
	; rv+5  bool shifted
	; rv+6	bool released
    ; rv+7  char returned by keyboardDecode or char printed by writeChar
    ; rv+8  string MSB pointer taken by writeString
    ; rv+9  string LSB pointer taken by writeString
    ; rv+10 last char of blinking cursor
    ; rv+11 input buffer EOT string MSB pointer 
    ; rv+12 input buffer EOT string LSB pointer 
    ; rv+13 char escapeChar taken by writeString
    ; rv+14 int device taken by writeString
    ; rv+15 char escapeChar taken by cmpStr
    ; rv+16 str1 pointer high taken by cmpStr
    ; rv+17 str1 pointer low taken by cmpStr
    ; rv+18 str2 pointer high taken by cmpStr
    ; rv+19 str2 pointer low taken by cmpStr
    ; rv+20 bool equal returned by cmpStr
    ; rv+21 *nextWord in input buffer high pointer
    ; rv+22 *nextWord in input buffer low pointer
    ; rv+23 uint returned by strToUint  (HIGH)
    ; rv+24 uint returned by strToUint  (LOW)
    ; rv+25 bool carry returned by strToUint
    ; rv+26 uint taken by uintToStr (HIGH)
    ; rv+27 uint taken by uintToStr (LOW)
    ; rv+28 str returned by uintToStr
    ; ...
    ; rv+33 eot char in str returned by uintToStr   (DUP)

start:  ; void main()
    NOP
    NOP
    MOV SP, #0xFEFC             ; initialize stack
    MOV Ra, #0x00               ; VR2R VR1W
    MOV CTL, Ra
	STO [#rv+5], Ra             ; bool shifted = 0
	STO [#rv+6], Ra             ; bool released = 0

    CALL [#fillScreen-start]    ; Set screen black
    MOV Ra, #0x02               ; VR1R VR1W
    MOV CTL, Ra

    MOV Ra, #0x20               ; char lastCursor = ' '
    STO [#rv+10], Ra

    MOV Ra, #0x24+2
    STO [#rv], Ra               ; short cursorX = 0x24+2
    MOV Rb, #0x09+2
    STO [#rv+1], Rb             ; short cursorY = 0x09+2

    MOV Si, #inputBuffer        ; *endInBuffer = inputBuffer
    STX [#rv+11], Si

    MOV Ra, #0x20               ; EOT char in cmpStr
    STO [#rv+15], Ra

    MOV Si, #string
    STX [#rv+8], Si
    MOV Ra, #0x0A               ; EOT char=\n
    STO [#rv+13], Ra
    MOV Ra, #0x00               ; int device = 0
    STO [#rv+14], Ra
    CALL [#writeString-start]   ; print welcome string

    MOV Ra, #0x24+2
    STO [#rv], Ra               ; cursorX = 0x24+2
    MOV Rb, #0x09+11
    STO [#rv+1], Rb             ; cursorY = 0x09+10

    MOV Ra, #0x3E               ; print '>'
    STO [#rv+7], Ra
    CALL [#writeChar-start]

    MOV Ra, #0x24+8
    STO [#rv], Ra               ; cursorX = 0x24+8



loop:   ;void loop()
    MOV Rb, #0x01               ; times to repeat 16bit count (multiplier)
    MOV Rc, #0xCF               ; MSB of 16bit count delay
    MOV Rd, #0xFF               ; LSB of 16bit count delay

    .init:
    MOV Ra, #0x40               ; Enable interrupts
    MOV STT, Ra

    MOV Ra, #0x00               ; compare value
    CMP Ra, Rd                  ; if zero, decrease high byte
    JZ [#.continue1-start]
    DEC Rd                      ; else decrease low byte
    MOV PC, #.init-start        ; and start again
    .continue1:
    MOV Rd, #0xFF               ; reset low byte
    CMP Ra, Rc                  ; if zero, decrease multiplier
    JZ [#.continue2-start]
    DEC Rc                      ; else decrease high byte
    MOV PC, #.init-start        ; and start again
    .continue2:
    MOV Rc, #0xFF               ; reset high byte
    CMP Ra, Rb                  ; if zero, change cursor
    JZ [#.blink-start]
    DEC Rb                      ; else decrease multiplier
    MOV PC, #.init-start        ; and start again
    .blink:
    LOD Ra, [#rv+10]            ; load lastCursor
    MOV Rb, #0x20               ; check if it was ' '
    CMP Ra, Rb
    JNZ [#.print-start]         ; if not, char c = ' '
    MOV Rb, #0x5F               ; if yes then char c = '_'
    .print:
    STO [#rv+10], Rb            ; update lastCursor
    MOV Rc, #0x60               ; disable interrupts
    MOV STT, Rc
    STO [#rv+7], Rb             ; char c
    CALL [#writeChar-start]              
    MOV PC, #loop-start


fillScreen:     ; void fillScreen(byte color)
    MOV Ra, #0x24   ; x starting address
    MOV Rb, #0x09   ; y starting address
    MOV Rc, #0x00   ; black color
    .writeP:
        MOV AVR, Rb     ; set y
        MOV AVR, Ra     ; set x
        MOV VRAM, Rc    ; load color

        MOV Rd, #0xC4           ; x end address
        CMP Ra, Rd              ; if reached the end
        JZ [#.nextLine-start]   ; go to next line
        INC Ra                  ; else increase x
        MOV PC, #.writeP-start  ; and write next pixel

    .nextLine:
        MOV Ra, #0x24           ; reset X address
        MOV Rd, #0x81           ; y end address
        CMP Rb, Rd              ; if reached the end
        JZ [#.finished-start]   ; finished writing
        INC Rb                  ; else increase Y
        MOV PC, #.writeP-start  ; and write next line

    .finished:
        POP PC      ; return
endFillScreen:


writeChar:      ;void writeChar(char c)
    PUSH Ra
    PUSH Rb
    PUSH Rc
	PUSH Rd
    PUSH Di

    ;Registers will be trated as 16bit to calculate array index
    MOV Rc, #font[15:8]       ; default offset in case c<0x20 or c>7D
    MOV Rd, #font[7:0]        ; in that case, write space
    LOD Rb, [#rv+7]           ; char c
    MOV Ra, #0x7D             ; c must be 0x20 < c < 0x7D
    CMP Ra, Rb
    JN [#.continue1-start]    ; if c > 0x7D then offset = 0
    MOV Ra, #0x20
    CMP Rb, Ra                ; if c < 0x20 then offset = 0
    JN [#.continue1-start]    ; else calculate array offset
    SUB Rb, Ra                ; ASCII offset
    MOV Ra, #0x00             ; Now Ra=0x00 Rb=ASCIIoffset
    MOV Rd, Rb                ; copy ASCIIoffset
    MOV Rc, #0x03             ; multiply by 8
    .multiply:
    LSL Rb                    ; logical shift left three times
    CSL Ra
    DEC Rc                    ; shift counter
    JNZ [#.multiply-start]    ; if jumps, Rc=0x00 Rd=ASCIIoffset
    SUB Rb, Rd                ; subtract one, result is multiplication by 7
    SBB Ra, Rc                ; now RaRb=ASCIIoffset*7=arrayOffset
    MOV Rc, #font[15:8]       ; RcRd will hold GLOBAL offset
    MOV Rd, #font[7:0]        ; now RaRb=arrayOffset, RcRd=globalOffset
    ADD Rd, Rb                ; RcRd = globalOffset + arrayOffset
    ADC Rc, Ra                ; Finished calculation

    .continue1:
    MOV Di, RcRd              ; Di points to start char font address
    PUSH Di

    MOV Di, #offsetChars
    MOV Rd, #0x04             ; counter
    LOD Ra, [#rv+7]           ; char c
    .loop:
    LDD Rc, [Di]              ; load array of characters to offset
    CMP Ra, Rc                ; check if it is one of them
    JNZ [#.continue-start]
    MOV Rc, #0x01             ; 1px offset
    MOV PC, #.printC-start
    .continue:
    DEC Rd                    ; decrease counter
    JNZ [#.loop-start]        ; if no coincidence, exit
    MOV Rc, #0x00             ; no offset
    
    .printC:
    POP Di
    LOD Ra, [#rv]             ; load cursor x
    LOD Rb, [#rv+1]           ; load cursor Y
    ADD Rb, Rc                ; add y offset
    MOV Rc, #0x07             ; short i = 7 (rows)
    STO [#rv+3], Rc

    .writeSprite:
        MOV Rc, #0x05         ; short j = 5 (columns)
        STO [#rv+4], Rc
        LDD Rc, [Di]          ; load line char data
        

        .writeLine:
            MOV AVR, Rb             ; set y
            MOV AVR, Ra             ; set x
            MOV Rd, #0x1F           ; clean D5, D6 and D7 from LSL ops
            AND Rc, Rd 
            STO [#rv+2],Rc          ; shifted char data
            MOV Rd, #0x10           ; check if pixel is written
            AND Rc, Rd
            CMP Rc, Rd
            MOV Rd, #0xFF           ; white color
            JZ [#.setColor-start]
            MOV Rd, #0x00           ; change to black if not written
            .setColor:
                PUSH Ra             ; I need more registers to do the ops
                PUSH Rb
                MOV Rb, #0x0F       ; Due to async comm, apparent succesful attempts counter
                .sendPixel:
                    MOV Ra, STT                ; STT &= !0x80
                    MOV Rc, #0x7F
                    AND Ra, Rc
                    MOV STT, Ra                ; image bit is now clear
                    MOV VRAM, Rd               ; attempt write
                    MOV Ra, STT                ; check image bit
                    MOV Rc, #0x80              ; mask 0b10000000
                    AND Ra, Rc
                    CMP Ra, Rc
                    JZ [#.sendPixel-start]     ; try again if IMG==1
                    DEC Rb
                    JNZ [#.sendPixel-start]    ; do another succesful attempt



            .success:
            POP Rb                  ; get y into Rb again
            POP Ra                  ; get x into Ra again
            LOD Rd, [#rv+4]         ; load j
            LOD Rc, [#rv+2]         ; load shifted char data
            LSL Rc                  ; shift char data
            INC Ra                  ; increase x
            DEC Rd                  ; decrease j
            STO [#rv+4], Rd         ; store j
            JNZ [#.writeLine-start] ; write more pixels if j>0
        
        MOV Rd, #0x05               ; reset cursor X
        SUB Ra, Rd
        LOD Rd, [#rv+3]             ; load i
        INC Rb                      ; increase y
        DEC Rd                      ; decrease i
        STO [#rv+3], Rd             ; store i
        JNZ [#.writeSprite-start]   ; write more lines if i>0

    POP Di
    POP Rd
    POP Rc
    POP Rb
    POP Ra
    POP PC      ;return
endWriteChar:

writeString:    ; void writeString(char[] *str, char escapeChar, int device)
    PUSH Ra
    PUSH Rc
    PUSH Di

    LDX Di, [#rv+8]             ; load Di with pointer
    .loop:
        LOD Ra, [#rv+14]        ; load int device, ROM(0) RAM(1)
        MOV Rc, #0x01           ; compare value
        CMP Ra, Rc
        LDD Rc, [Di]            ; load character (pointer auto increment) (ROM by default)
        JNZ [#.continue-start]
        DEC Di                  ; was autoincremented by default
        LOD Rc, [Di]            ; load character from RAM
        INC Di                  ; increment pointer
        .continue:
        LOD Ra, [#rv+13]        ; EOT character
        CMP Ra, Rc              ; check EOT
        JZ [#.eot-start]        ; if EOT, return
        STO [#rv+7], Rc         ; else call writeChar(char c)
        CALL [#writeChar-start]
        LOD Ra, [#rv+0]         ; load cursor X
        MOV Rc, #0x06
        ADD Ra, Rc              ; set next cursor position
        STO [#rv+0], Ra         ; and store it
        MOV PC, #.loop-start    ; read next char

    .eot:
    POP Di
    POP Rc
    POP Ra
    POP PC                      ; return
endWriteString:

cmpStr:         ; int cmpStr(const char[] *str2, char escapeChar)
    PUSH Ra
    PUSH Rb
    PUSH Rc
    PUSH Rd
    PUSH Si
    PUSH Di

    MOV Si, #inputBuffer                    ; load Si with *inputBuffer
    LDX Di, [#rv+18]                        ; load Di with const *char[] str
    LOD Ra, [#rv+15]                        ; load Ra with escapeCharacter
    MOV Rb, #0x00                           ; false by default

    .loop:
    LOD Rc, [Si]                            ; load Rc with str1
    INC Si                                  ; increase pointer
    LDD Rd, [Di]                            ; load Rd with str2 (auto increment)
    CMP Ra, Rd                              ; compare escape char with str2
    JZ [#.getResult-start]
    CMP Rc, Rd                              ; compare characters from both strings
    JZ [#.loop-start]                       ; if equal, cmp next characters
    MOV PC, #.exit-start                    ; else exit

    .getResult:
    CMP Ra, Rc                              ; now compare escape char with str1
    JNZ [#.exit-start]                      ; if not equal then exit
    STX [#rv+21], Si                        ; store *nextWord in input buffer pointer
    MOV Rb, #0x01                           ; else set equal to true

    .exit:
    STO [#rv+20], Rb                        ; store result, Equal=1, Different=0
    POP Di
    POP Si
    POP Rd
    POP Rc
    POP Rb
    POP Ra
    POP PC               

endcmpStr:

strToUint:      ; uint strToUint(char[] *str), *str is currently fixed to *nextWord
    ; rv+23 uint returned by strToUint  (HIGH)
    ; rv+24 uint returned by strToUint  (LOW)
    ; rv+25 bool carry returned by strToUint
    PUSH Ra
    PUSH Rb
    PUSH Rc
    PUSH Rd
    PUSH Si

    MOV Si, #0x0000                         ; initialize result to 0
    STX [#rv+23], Si
    MOV Ra, #0x01                           ; bool error(carry) defaults to true
    STO [#rv+25], Ra
    LDX Si, [#rv+21]                        ; load *nextWord

    ; We have to ensure '0'<=str<='9' else exit
    .loop:
    LOD Ra, [Si]                            ; load char str
    MOV Rb, #0x30                           ; '0'
    SUB Ra, Rb                              ; str -= '0'
    JNC  [#.exit-start]
    MOV Rb, #0x0A                           ; str must now be <=0x09, else exit
    CMP Ra, Rb                              ; if str >= 0x0A
    JC [#.exit-start]                       ; then exit else continue
    INC Si                                  ; increment pointer
    MOV Rc, #0x01                           ; bool error(carry) defaults to true
    STO [#rv+25], Rc                        ; every new char is read
    PUSH Ra                                 ; save (uint)str on to the stack for later
    LOD Ra, [#rv+23]                        ; load previous result HIGH
    LOD Rb, [#rv+24]                        ; load previous result LOW
    PUSH Ra                                 ; save result HIGH
    PUSH Rb                                 ; save result LOW
    MOV Rc, #0x03                           ; multiply by 8
    .multiply:
    LSL Rb                                  ; logical shift left three times
    CSL Ra
    JC [#.exit-start]                       ; if carry, exit with error(carry)
    DEC Rc                                  ; shift counter
    JNZ [#.multiply-start]                  ; keep shifting left (*2)
    POP Rd                                  ; get unmodified previous result in RcRd
    POP Rc
    LSL Rd                                  ; multiply by 2
    CSL Rc                                  ; no need to test carry here if *10 did not exit
    ADD Rb, Rd                              ; prevResult*8 + prevResult*2 = prevResult*10
    ADC Ra, Rc
    JC [#.exit-start]                       ; if carry, exit with error(carry)
    MOV Rc, #0x00                           ; RcRd=(int)str
    POP Rd                                  ; get str
    ADD Rb, Rd                              ; result = prevResult*10 + str
    ADC Ra, Rc
    JC [#.exit-start]                       ; if carry, exit with error(carry)
    STO [#rv+23], Ra                        ; Store result
    STO [#rv+24], Rb
    MOV Rc, #0x00                           ; if nothing made carry, set error to false
    STO [#rv+25], Rc
    MOV PC, #.loop-start                    ; keep reading until end of unsigned integer

    .exit:
    STX [#rv+21], Si                        ; store *nextWord
    POP Si
    POP Rd
    POP Rc
    POP Rb
    POP Ra
    POP PC


endStrToUint:

uintToStr:      ; *char[] uintToStr(uint n)
    ; rv+26 uint taken by uintToStr (HIGH)
    ; rv+27 uint taken by uintToStr (LOW)
    ; rv+28 str returned by uintToStr
    ; ...
    ; rv+33 eot char in str returned by uintToStr
    PUSH Ra
    PUSH Rb
    PUSH Rc
    PUSH Rd
    PUSH Si

    LDX Si, [#rv+26]                    ; load RaRb with uint
    MOV RaRb, Si

    MOV Rc, #0x00-0x30                  ; null - '0'
    PUSH Rc                             ; save EOT
    MOV Rc, #0x00                       ; RcRd is Divisor = 10
    MOV Rd, #0x0A                        
    .loop:
    MOV Si, #0x0000                     ; Sub count (quotient)
    .divide:                            ; RaRb=dividend, RcRd=divisor

        .compareHigh:
        CMP Ra, Rc                      ; Compare high bytes
        JZ [#.compareLow-start]         ; if dividenH - divisorH = 0 then compare low bytes
        JNC [#.getChar-start]           ; if dividenH - divisorH < 0 then continue
        ; a carry flag not set in a subtraction means operand2>operand1
        INC Si                          ; increase quotient every sub cycle
        SUB Rb, Rd                      ; subtract divisor from dividend
        SBB Ra, Rc                          
        MOV PC, #.divide-start          ; subtract again if possible

        .compareLow:
        CMP Rb, Rd                      ; compare low bytes
        JNC [#.getChar-start]           ; if dividenL - divisorL >= 0 then continue
        INC Si                          ; increase quotient every sub cycle
        SUB Rb, Rd                      ; subtract divisor from dividend
        SBB Ra, Rc                          
        MOV PC, #.divide-start          ; subtract again if possible


    .getChar:
    PUSH Rb                             ; push remainder, which is a char of str
    MOV RaRb, Si                        ; quotient is the next dividend
    CMP Ra, Rc                          ; compare quotientH with zero
    JNZ [#.loop-start]                  
    CMP Rb, Rc                          ; compare quotientL with zero
    JNZ [#.loop-start]                  ; if quotient == 0 then continue

    MOV Si, #rv+28                      ; Si points to returned str
    .writeStr:
    POP Rb                              ; get digit
    MOV Rd, #0x30                       ; digit + '0' to get ascii code
    ADD Rb, Rd
    CMP Rb, Rc                          ; compare digit with null
    JZ [#.exit-start]
    STO [Si], Rb                        ; store char
    INC Si
    MOV PC, #.writeStr-start            ; get next char from SP and store

    .exit:
    STO [Si], Rb                        ; store EOT
    POP Si
    POP Rd
    POP Rc
    POP Rb
    POP Ra
    POP PC

endUintToStr:

isDigit:        ; int isDigit(char c)
    ;USES Ra AS ARGUMENT AND returns int in Rc
    ;DOES NOT PUSH ANY REGISTERS, USE WITH CARE
    ;SUBROUTINE OF atof
    MOV Rc, #0x00                           ; bool defaults to false
    MOV Rb, #0x30                           ; ASCII '0'
    CMP Ra, Rb                              ; c - '0' must be positive
    JNC [#.exit-start]                      ; if carry==0, result is negative and exit
    MOV Rb, #0x39                           ; ASCII '9'
    CMP Rb, Ra                              ; '9' - c must be positive
    JNC [#.exit-start]                      ; if carry==0, result is negative and exit
    MOV Rc, #0x01                           ; set isDigit to true
    .exit:
    POP PC                                  ; return

endIsDigit:

int48Lshift:
    ;USES Di AS ARGUMENT AND updates Di to Di-5 memory contents
    ;DOES NOT PUSH ANY REGISTERS, USE WITH CARE
    ;SUBROUTINE OF addDigit and atof
    ;Di must be set to lower byte of int40 (high memory address)
    MOV Ra, #0x06                           ; Byte counter
    MOV Rc, #0x03                           ; arbitrary value                           
    INC Rc                                  ; ensure carry flag is CLEAR
    MOV Rc, STT                             ; Rc holds flags for shift operations
    .loop:
    MOV STT, Rc                             ; set flags from last shift
    LOD Rd, [Di]                            ; load operand byte
    CSL Rd                                  ; shift left with carry
    MOV Rc, STT                             ; save flags for later
    STO [Di], Rd                            ; save shifted byte
    DEC Di                                  ; decrease pointer
    DEC Ra                                  ; decrease byte counter
    JNZ [#.loop-start]                      ; shift all bytes
    MOV STT, Rc                             ; set flags from last shift
    POP PC                                  ; return
endInt40Lshift:

int48add:
    ;USES Si and Di AS ARGUMENT AND updates Di to Di-5 memory contents
    ;DOES NOT PUSH ANY REGISTERS, USE WITH CARE
    ;SUBROUTINE OF addDigit and atof
    ;Si and Di must be set to lower bytes of the int40 (high memory address)
    MOV Rd, #0x06                           ; Byte counter
    MOV Rb, #0x03                           ; arbitrary value                           
    INC Rb                                  ; ensure carry flag is CLEAR
    MOV Rb, STT                             ; Rb holds flags for addition ops
    .loop:
    MOV STT, Rb                             ; set flags from last addition
    LOD Ra, [Di]                            ; load operand1 byte
    LOD Rc, [Si]                            ; load operand2 byte
    ADC Ra, Rc                              ; add with carry that byte
    MOV Rb, STT                             ; save flags for later
    STO [Di], Ra                            ; save result byte
    DEC Di                                  ; decrease op1 pointer
    DEC Si                                  ; decrease op2 pointer
    DEC Rd                                  ; decrease byte counter
    JNZ [#.loop-start]                      ; shift all bytes
    MOV STT, Rb                             ; set flags from last addition
    POP PC                                  ; return
endInt48add:


addDigit:
    ;USES Ra AS ARGUMENT AND returns int in Rc
    ;DOES NOT PUSH ALL REGISTERS, USE WITH CARE
    ;SUBROUTINE OF atof
    ; mantisa *=10
    ; mantissa += c -'0'
    ; rv+33 x5 mantissa
    ; rv+34 x4 mantissa
    ; rv+35 x3 mantissa
    ; rv+36 x2 mantissa
    ; rv+37 x1 mantissa
    ; rv+38 x0 mantissa
    ; rv+44 t5 (temporary int48)
    ; rv+45 t4
    ; rv+46 t3
    ; rv+47 t2
    ; rv+48 t1
    ; rv+49 t0
    PUSH Si                                 ; leave Si untouched at the end
    MOV Rb, #0x30
    SUB Ra, Rb                              ; Ra = c - '0'
    PUSH Ra                                 ; save for later
    MOV Di, #rv+33                          ; Di points to mantissa high
    MOV Si, #rv+44                          ; Si points to mantissaCopy high
    MOV Rc, #0x06                           ; Counter to copy previous mantissa
    .savePrevMant:
    LOD Ra, [Di]                            ; load mantissa byte
    INC Di                                  ; increase pointer
    STO [Si], Ra                            ; store to mantissaCopy
    INC Si
    DEC Rc                                  ; Decrease counter
    JNZ [#.savePrevMant-start]              ; keep copying else continue
    MOV Rb, #0x03                           ; Shift counter
    .multiply8:
    MOV Di, #rv+38                          ; Di points to mantissa low
    CALL [#int48Lshift-start]               ; mantissa << 1
    JC [#.exit-start]                       ; exit with carry if overflow
    DEC Rb                                  ; Decrease shift counter
    JNZ [#.multiply8-start]                 ; shift three times
    ;DEBUG
    MOV Rd, #0x2F
    CALL [#mdebug-start]
    DEC Si                                  ; Si points to copyMantissa low
    MOV Di, Si                              ; set lshift argument
    CALL [#int48Lshift-start]               ; mantissaCopy << 1
    ;DEBUG
    MOV Rd, #0x2F
    CALL [#mdebug-start]
    MOV Di, #rv+38                          ; Di points to mantissa low
    MOV Si, #rv+49                          ; Si points to copyMantissa low
    CALL [#int48add-start]                  ; x = mantissa*8 + mantissa*2
    JC [#.exit-start]                       ; exit with carry if overflow
    ;DEBUG
    MOV Rd, #0x2F
    CALL [#mdebug-start]
    MOV Si, #rv+49                          ; Si points to t low
    POP Ra                                  ; load c - '0'
    STO [Si], Ra                            ; and store it in t low
    DEC Si
    MOV Ra, #0x00                           ; store 0 in higher bytes of t
    MOV Rb, #0x05                           ; copy counter
    .saveDigit:
    STO [Si], Ra                            ; store 0
    DEC Si                                  ; decrease pointer
    DEC Rb                                  ; decrease copy counter
    JNZ [#.saveDigit-start]                 ; reset 5 higher order bytes
    MOV Di, #rv+38                          ; Di points to mantissa low
    MOV Si, #rv+49                          ; Si points to c - '0'
    CALL [#int48add-start]                  ; x += c - '0'
    ;DEBUG
    MOV Rd, #0x2F
    CALL [#mdebug-start]
    MOV PC, #.finish-start                  ; exit
    .exit:
    POP Ra
    .finish:
    POP Si
    POP PC                                  ; return
endAddDigit:

strToFloat:     ; float atof(char *str)
    PUSH Ra
    PUSH Rb
    PUSH Rc
    PUSH Rd
    PUSH Si
    PUSH Di
    ; 32bit float: 1bit sign, 8bits exponent, 23 bits significand
    ; Exponent bias = 127
    ; v = (2^(e-127)*(1+s/2^23))*i, where 'v' is number value, 'e' is exponent,
    ; 's' is the significand and 'i' is the sign
    ; An exponent of 0(0x00) represents 0 if s==0 or subnormal numbers when s!=0,
    ; which are not supported by this function
    ; An exponent of 255(0xFF) will represent +-infinity when s==0 or NaN when s!=0
    ; The parser will follow this representation:
    ; v = x * 10^e
    ; Where 38>e>-45, so e is a int8, value obtained from max and min float numbers
    ; And since float provides 10 significant decimal digits, x is int48 to handle
    ; converter operations

    ; rv+33 x5 mantissa
    ; rv+34 x4 mantissa
    ; rv+35 x3 mantissa
    ; rv+36 x2 mantissa
    ; rv+37 x1 mantissa
    ; rv+38 x0 mantissa
    ; rv+39 e, power of ten exponent
    ; rv+40 eExplicit, power of ten exponent defined by user at the end
    ; rv+41 *str high taken by atof
    ; rv+42 *str low taken by atof
    ; rv+43 byte parserState
    ; rv+44 t5 (temporary int48)
    ; rv+45 t4
    ; rv+46 t3
    ; rv+47 t2
    ; rv+48 t1
    ; rv+49 t0
    ; rv+50 digx, meaning stored digits
    ; rv+51 explicitExponent sign
    ; rv+52 float sign
    ; rv+53 y, power of two exponent

    ; Initialize
    LDX Si, [#rv+41]                            ; Si points to *str
    MOV Ra, #0x00
    STO [#rv+40], Ra                            ; explicitExponent = 0                           
    STO [#rv+43], Ra                            ; parserState = 0 (return NaN)
    STO [#rv+52], Ra                            ; float sign = 0  positive by default
    STO [#rv+39], Ra                            ; e = 0     zero  by default
    STO [#rv+50], Ra                            ; digx = 0  zero by default
    STO [#rv+51], Ra                            ; explicitExponent sign = 0  positive by default
    MOV Rb, #0x06                               ; copy counter
    MOV Di, #rv+38                              ; Di points to x0 (mantissa low)
    .initMantissa:
    STO [Di], Ra                                ; store 0
    DEC Di                                      ; decrease pointer
    DEC Rb                                      ; decrease copy counter
    JNZ [#.initMantissa-start]                  ; initalize all 6 bytes
    ; Parser
    .whiteSpaceParse:
        MOV Rb, #0x20                           ; ASCII space
        .getC_s1:
        LOD Ra, [Si]                            ; load char
        INC Si                                  ; increase pointer
        CMP Ra, Rb                              ; if char==' '
        JZ [#.getC_s1-start]                    ; then keep reading else continue
    .numberSign:
        MOV Rb, #0x2B                           ; ASCII '+'
        CMP Ra, Rb                              ; if char == +
        JZ [#.isPlus_s2-start]
        MOV Rb, #0x2D                           ; ASCII '-'
        CMP Ra, Rb                              ; else if char == -
        JZ [#.isMinus_s2-start]
        CALL [#isDigit-start]                   ; if char == digit
        MOV Rb, #0x01                           ; check if true
        CMP Rb, Rc                              ; Rc is bool returned
        JZ [#.isDigit_s2-start]
        MOV PC, #.parserEnd-start               ; else exit with NaN
        .isMinus_s2:
        MOV Rb, #0x01                           ; set float sign to -
        STO [#rv+52], Rb
        ;DEBUG
        MOV Rd, Ra
        CALL [#mdebug-start]
        MOV PC, #.leadingZerosMantissa-start     ; continue next state
        .isDigit_s2:
        DEC Si                                   ; Next phase must reload this digit
        MOV PC, #.leadingZerosMantissa-start     ; continue next state
        .isPlus_s2:
        ;DEBUG
        MOV Rd, Ra
        CALL [#mdebug-start]
        ;continue
    .leadingZerosMantissa:
        MOV Rb, #0x30                           ; ASCII '0'
        .getC_s3:
        LOD Ra, [Si]                            ; load next char
        INC Si                                  ; increase pointer
        ;DEBUG
        MOV Rd, Ra
        CALL [#mdebug-start]
        CMP Ra, Rb                              ; if char == '0'
        JZ [#.getC_s3-start]                    ; then keep reading else continue
        MOV Rb, #0x2E                           ; ASCII '.'
        CMP Ra, Rb                              ; if char != '.'
        JNZ [#.mantissaInt-start]               ; then jump to mantissaInt else continue
    .leadingZerosFrac:
        MOV Rb, #0x30                           ; ASCII '0'
        MOV Rc, #0x01                           ; e, starts at one due to decrease before check
        .getC_s4:
        DEC Rc                                  ; e--
        LOD Ra, [Si]                            ; load next char
        INC Si                                  ; increase pointer
        CMP Ra, Rb                              ; if char == '0'
        JZ [#.getC_s4-start]                    ; then keep reading else continue
        STO [#rv+39], Rc                        ; store e
        MOV PC, #.mantissaFrac-start            ; and parse mantissa fractional part
    .mantissaInt:
        DEC Si                                  ; reload char
        ;DEBUG
        MOV Rd, #0x23
        CALL [#mdebug-start]
        .loop_s5:
        LOD Ra, [Si]                            ; load next char
        INC Si                                  ; increase pointer
        CALL [#isDigit-start]                   ; if char == digit
        MOV Rb, #0x01                           ; check if true
        CMP Rb, Rc                              ; Rc is bool returned
        JNZ [#.continue_s5-start]               ; if not a digit continue
        ;DEBUG
        MOV Rd, Ra
        CALL [#mdebug-start]
        LOD Rd, [#rv+50]                        ; load digx
        INC Rd                                  ; increase digx
        MOV Rb, #0x0C                           ; maxDigits=12
        CMP Rb, Rd                              ; if digx <= 12
        JNC [#.maxDigits_s5-start]              ; just increase exponent
        CALL [#addDigit-start]                  ; else add digit to integer mantissa
        JNC [#.notOverflow_s5]                  ; exit if mantissa overflowed
        MOV Ra, #0x02                           ; parserState = 2 (overflow)
        STO [#rv+43], Ra
        MOV PC, #.parserEnd-start               ; exit with overflow
        .notOverflow_s5:
        MOV Ra, #0x01                           ; parserState = 1 (return float)
        STO [#rv+43], Ra
        MOV PC, #.loop_s5-start                 ; and check next char
        .maxDigits_s5:
        LOD Rd, [#rv+39]                        ; load e
        INC Rd                                  ; increase exponent
        STO [#rv+39], Rd                        ; and store it
        MOV PC, #.loop_s5-start                 ; and check next char
        .continue_s5:
        MOV Rb, #0x2E                           ; ASCII '.'
        CMP Ra, Rb                              ; if char != '.'
        JNZ [#.mantissaFrac-start]              ; then go to next state
        ;DEBUG
        MOV Rd, Ra
        CALL [#mdebug-start]
        LOD Ra, [Si]                            ; else load next char and go to next state
        INC Si                                  ; increase pointer
    .mantissaFrac:
        ; Ra holds next character already
        ;DEBUG
        MOV Rd, #0x24
        CALL [#mdebug-start]
        .loop_s6:
        CALL [#isDigit-start]                   ; if char == digit then add digit
        MOV Rb, #0x01                           ; check if true
        CMP Rb, Rc                              ; Rc is bool returned
        JNZ [#.continue_s6-start]               ; if not a digit continue
        ;DEBUG
        MOV Rd, Ra
        CALL [#mdebug-start]
        LOD Rd, [#rv+50]                        ; load digx
        INC Rd                                  ; increase digx
        MOV Rb, #0x0C                           ; maxDigits=12
        CMP Rb, Rd                              ; if digx <= 12
        JNC [#.maxDigits_s6-start]              ; ignore this digit(exceeded precission)
        CALL [#addDigit-start]                  ; else add digit to integer mantissa
        JNC [#.notOverflow_s6]                  ; exit if mantissa overflowed
        MOV Ra, #0x02                           ; parserState = 2 (overflow)
        STO [#rv+43], Ra
        MOV PC, #.parserEnd-start               ; exit with overflow
        .notOverflow_s6:
        MOV Ra, #0x01                           ; parserState = 1 (return float)
        STO [#rv+43], Ra
        LOD Rd, [#rv+39]                        ; load e
        DEC Rd                                  ; decrease exponent
        STO [#rv+39], Rd                        ; and store it
        LOD Ra, [Si]                            ; load next char
        INC Si                                  ; increase pointer
        MOV PC, #.loop_s6-start                 ; and check next char
        .maxDigits_s6:
        LOD Ra, [Si]                            ; load next char
        INC Si                                  ; increase pointer
        MOV PC, #.loop_s6-start                 ; and check next char
        .continue_s6:
        MOV Rb, #0x45                           ; ASCII 'E'
        CMP Ra, Rb                              ; if char == 'E'
        JZ [#.exponentSign-start]               ; go to next state
        MOV Rb, #0x65                           ; ASCII 'e'
        CMP Ra, Rb                              ; if char == 'e'
        JZ [#.exponentSign-start]               ; go to next state
        MOV PC, #.parserEnd-start               ; else exit
    .exponentSign:
        ;DEBUG
        MOV Rd, #0x25
        CALL [#mdebug-start]
        ;DEBUG
        MOV Rd, Ra
        CALL [#mdebug-start]
        LOD Ra, [Si]                            ; load next char
        INC Si                                  ; increase pointer
        MOV Rb, #0x2B                           ; ASCII '+''
        CMP Ra, Rb                              ; if char == +
        JZ [#.isPlus_s7-start]
        MOV Rb, #0x2D                           ; ASCII '-'
        CMP Ra, Rb                              ; else if char == -
        JZ [#.isMinus_s7-start]
        MOV PC, #.parserEnd-start               ; else exit
        .isMinus_s7:
        MOV Rb, #0x01                           ; set explicitExponent sign to -
        STO [#rv+51], Rb
        .isPlus_s7:
        ;continue
    .exponentLeadingZeros:
        MOV Rb, #0x30                           ; ASCII '0'
        .getC_s8:
        LOD Ra, [Si]                            ; load next char
        INC Si                                  ; increase pointer
        CMP Ra, Rb                              ; if char == '0'
        JZ [#.getC_s8-start]                    ; then keep reading else continue
    .exponent:
        ;DEBUG
        MOV Rd, #0x26
        CALL [#mdebug-start]
        .loop_s9:
        CALL [#isDigit-start]                   ; if char == digit then add  exponent digit
        MOV Rb, #0x01                           ; check if true
        CMP Rb, Rc                              ; Rc is bool returned
        JNZ [#.continue_s8-start]               ; if not a digit continue
        ;DEBUG
        MOV Rd, Ra
        CALL [#mdebug-start]
        MOV Rb, #0x30
        SUB Ra, Rb                              ; Ra = c - '0'
        PUSH Ra                                 ; save for later
        LOD Rb, [#rv+40]                        ; load previous eExplicit
        PUSH Rb                                 ; save for later
        MOV Rc, #0x03                           ; multiply by 8
        .multiply_s9:
        LSL Rb                                  ; logical shift left three times
        JN [#.eExpOverflow-start]               ; if negative, exit with carry
        DEC Rc                                  ; shift counter
        JNZ [#.multiply_s9-start]               ; keep shifting left (*2)
        POP Rc                                  ; get unmodified previous eExplicit in Rc
        LSL Rc                                  ; multiply by 2
        ADD Rb, Rc                              ; prevResult*8 + prevResult*2 = prevResult*10
        JN [#.eExpOverflow2-start]              ; if negative, exit with carry
        POP Rc                                  ; get c - '0'
        ADD Rb, Rc                              ; result = prevResult*10 + str
        JN [#.eExpOverflow3-start]              ; if negative, exit with carry
        STO [#rv+40], Rb                        ; Store result
        LOD Ra, [Si]                            ; load next char
        INC Si                                  ; increase pointer
        MOV PC, #.loop_s9-start                 ; and check next char
        .eExpOverflow:
        POP Ra
        .eExpOverflow2:
        POP Ra
        .eExpOverflow3:
        MOV Ra, #0x02                           ; parserState = 2 (overflow)
        STO [#rv+43], Ra
        MOV PC, #.parserEnd-start               ; exit with overflow
        .continue_s8:
        LOD Rb, [#rv+51]                        ; load eExplicit sign
        MOV Rc, #0x01
        CMP Rb, Rc                              ; if eExplicitSign = -
        JNZ [#.parserEnd-start]                 ; invert it else exit
        LOD Rb, [#rv+40]                        ; load previous eExplicit
        NOT Rb                                  ; eExplicitSign = -eExplicitSign
        INC Rb
        STO [#rv+40], Rb                        ; Store result

    .parserEnd:
    DEC Si                                      ; decrease char pointer
    STX [#rv+21], Si                            ; store nextWord
    LOD Rb, [#rv+43]                            ; load parserState
    .pstateNAN:
    MOV Ra, #0x00
    CMP Ra, Rb                                  ; if case != NaN
    JNZ [#.pstateOverflow-start]                ; check next case else continue
    MOV Ra, #0xFF
    STO [#rv+53], Ra                            ; set final exponent to special case
    STO [#rv+38], Ra                            ; significand != 0 to signal NaN
    ;DEBUG
    MOV Rd, #0x4E
    CALL [#mdebug-start]
    MOV PC, #.exit-start                        ; return NaN
    .pstateOverflow:
    MOV Ra, #0x02
    CMP Ra, Rb                                  ; if case != overflow
    JNZ [#.pstateFloat-start]                   ; check next case else continue
    MOV Ra, #0xFF
    STO [#rv+53], Ra                            ; set final exponent to special case
    MOV Ra, #0x00                               ; reset mantissa
    MOV Rb, #0x06                               ; copy counter
    MOV Di, #rv+38                              ; Di points to x0 (mantissa low)
    .resetMantissa:
    STO [Di], Ra                                ; store 0
    DEC Di                                      ; decrease pointer
    DEC Rb                                      ; decrease copy counter
    JNZ [#.resetMantissa-start]                 ; reset all 6 bytes
    ;DEBUG
    MOV Rd, #0x56
    CALL [#mdebug-start]
    MOV PC, #.exit-start                        ; return +-infinity
    .pstateFloat:
    LOD Ra, [#rv+39]                            ; load e
    LOD Rb, [#rv+40]                            ; load eExplicit
    ADD Ra, Rb                                  ; e += eExplicit
    STO [#rv+39], Ra                            ; store final power of ten exponent
    ;DEBUG
    MOV Rd, #0x46
    CALL [#mdebug-start]

    ; converter
    ; from v = x * 10^e  to  v = x' * 2^y
    ; If exponent e > 0 then a exponent reduction subroutine will occur
    ; each e-- will compensate with x*=10 and with the necessary logical
    ; shift rights to avoid overflow and reduce rounding errors
    ; If exponent < 0, a special integer*float subroutine will be executed
    ; in which the float factors will be predefined in ROM and are the
    ; negative powers of ten: 0.1 0.01 0.001 etc
    ; result will have IEEE-754 float format


    .exit:
    LOD Ra, [#rv+38]                            ;DEBUG
    MOV SND, Ra
    POP Di
    POP Si
    POP Rd
    POP Rc
    POP Rb
    POP Ra
    POP PC
endStrToFloat:

mdebug:
    PUSH Rd
    PUSH Rc

    STO [#rv+7], Rd         ; else call writeChar(char c)
    CALL [#writeChar-start]
    LOD Rd, [#rv+0]         ; load cursor X
    MOV Rc, #0x06
    ADD Rd, Rc              ; set next cursor position
    STO [#rv+0], Rd         ; and store it
    
    POP Rc
    POP Rd
    POP PC                                  ; return
endmdebug:

newLine:
    PUSH Rb
    PUSH Rd

    MOV Rb, #0x24+2                         ; reset x cursor
    STO [#rv+0], Rb                         ; and store it
    LOD Rb, [#rv+1]                         ; load y cursor
    MOV Rd, #0x09                           ; Increase y cursor to next line
    ADD Rb, Rd
    STO [#rv+1], Rb                         ; and store it

    ; Pending: Add \n to screen buffer

    POP Rd
    POP Rb
    POP PC
endNewLine:

printCMD:
    PUSH Ra
    PUSH Si

    CALL [#newLine-start]                   ; print \n
    LDX Si, [#rv+21]                        ; load *nextWord
    STX [#rv+8], Si                         ; and store in writeString argument
    MOV Ra, #0x00                           ; EOT char=\0
    STO [#rv+13], Ra
    MOV Ra, #0x01                           ; device = 1 (RAM)
    STO [#rv+14], Ra
    CALL [#writeString-start]               ; print command argument string

    POP Si
    POP Ra
    POP PC
endprintCMD:

mathCMD:
    PUSH Ra
    PUSH Rb
    PUSH Rc
    PUSH Rd
    PUSH Si

    CALL [#newLine-start]                       ; print \n
    LDX Si, [#rv+21]                            ; load nextWord
    STX [#rv+41], Si                            ; atof argument
    CALL [#strToFloat-start]                    ; atof

    .exit:
    POP Si
    POP Rd
    POP Rc
    POP Rb
    POP Ra
    POP PC
endMathCMD:

peekCMD:
    PUSH Ra
    PUSH Rb
    PUSH Rc
    PUSH Rd
    PUSH Si

    CALL [#newLine-start]                   ; print \n
    CALL [#strToUint-start]                 ; convert input data to uint
    LOD Ra, [#rv+25]                        ; load bool carry
    MOV Rb, #0x01                           ; check if carry == true
    CMP Ra, Rb                              ; if true then print error
    JZ [#.syntaxError-start]                ; else continue
    LDX Si, [#rv+23]                        ; load Si with uint returned by strToUint
    MOV Rc, #0x00                           ; Get data from user input address
    LOD Rd, [Si]
    STO [#rv+26], Rc                        ; set uintToStr parameters
    STO [#rv+27], Rd 
    CALL [#uintToStr-start]
    MOV Si, #rv+28                          ; Set Si to *str returned by uintToStr
    STX [#rv+8], Si                         ; and store in writeString argument
    MOV Ra, #0x00                           ; EOT char=\0
    STO [#rv+13], Ra
    MOV Ra, #0x01                           ; device = 1 (RAM)
    STO [#rv+14], Ra
    CALL [#writeString-start]               ; print converted integer string
    MOV PC, #.exit-start                    ; exit

    .syntaxError:
    MOV Si, #error2                         ; load error2 string
    STX [#rv+8], Si                         ; and store in writeString argument
    MOV Ra, #0x0A                           ; EOT char=\n
    STO [#rv+13], Ra
    MOV Ra, #0x00                           ; device = 0 (ROM)
    STO [#rv+14], Ra
    CALL [#writeString-start]               ; print error string

    .exit:
    POP Si
    POP Rd
    POP Rc
    POP Rb
    POP Ra
    POP PC
endPeekCMD:

pokeCMD:
    PUSH Ra
    PUSH Rb
    PUSH Rc
    PUSH Rd
    PUSH Si

    CALL [#strToUint-start]                 ; convert input data to uint
    LOD Ra, [#rv+25]                        ; load bool carry
    MOV Rb, #0x01                           ; check if carry == true
    CMP Ra, Rb                              ; if true then print error
    JZ [#.syntaxError-start]                ; else continue
    LDX Si, [#rv+21]                        ; load *nextWord
    LOD Ra, [Si]                            ; check contents of *nextWord
    INC Si                                  ; increment pointer
    MOV Rb, #0x2C                           ; Ra = ','
    CMP Ra, Rb                              ; if nextWord = ','
    JNZ [#.syntaxError-start]               ; then continue else exit with error
    LOD Ra, [Si]                            ; check contents of *nextWord
    INC Si                                  ; increment pointer
    MOV Rb, #0x20                           ; Ra = ' '
    CMP Ra, Rb                              ; if nextWord = ' '
    JNZ [#.syntaxError-start]               ; then continue else exit with error
    STX [#rv+21], Si                        ; store *nextWord
    LDX Si, [#rv+23]                        ; load Si with uint returned by strToUint from before
    CALL [#strToUint-start]                 ; convert input data to uint
    LOD Ra, [#rv+25]                        ; load bool carry
    MOV Rb, #0x01                           ; check if carry == true
    CMP Ra, Rb                              ; if true then print error
    JZ [#.syntaxError-start]                ; else continue
    LOD Ra, [#rv+23]                        ; Load Ra with uint HIGH returned by strToUint
    MOV Rb, #0x00
    CMP Ra, Rb                              ; if uintHIGH == 0
    JNZ [#.syntaxError-start]               ; then continue else exit with error
    LOD Rb, [#rv+24]                        ; load Rb with uint LOW returned by strToUint
    STO [Si], Rb                            ; Load in input1 the contents of input2
    MOV PC, #.exit-start                    ; exit

    .syntaxError:
    CALL [#newLine-start]                   ; print \n
    MOV Si, #error2                         ; load error2 string
    STX [#rv+8], Si                         ; and store in writeString argument
    MOV Ra, #0x0A                           ; EOT char=\n
    STO [#rv+13], Ra
    MOV Ra, #0x00                           ; device = 0 (ROM)
    STO [#rv+14], Ra
    CALL [#writeString-start]               ; print error string

    .exit:
    POP Si
    POP Rd
    POP Rc
    POP Rb
    POP Ra
    POP PC
endpokeCMD:

clearCMD:
    PUSH Ra
    PUSH Rb
    
    MOV Ra, CTL                             ; CTL ^= 0x01
    MOV Rb, #0x01
    XOR Ra, Rb
    MOV CTL, Ra                             ; writing to and reading from diff VRAMs
    CALL [#fillScreen-start]                ; Set screen black
    ; Pending: Reset screen buffer pointer
    MOV Rb, #0x09-0x09                      ; reset y cursor to one line above from screen
    STO [#rv+1], Rb                         ; and store it
    MOV Ra, CTL                             ; CTL ^= 0x02
    MOV Rb, #0x02
    XOR Ra, Rb
    MOV CTL, Ra                             ; writing to and reading from same VRAMs

    POP Rb
    POP Ra
    POP PC

endClearCMD:


processCMD:
    PUSH Ra
    PUSH Rb
    PUSH Rc
    PUSH Rd
    PUSH Si

    MOV Ra, #0x20                           ; escape char to cmp ' '
    STO [#rv+15], Ra

    .casePRINT:
    MOV Si, #print_cmd
    STX [#rv+18], Si                        ; compare "print "
    CALL [#cmpStr-start]                    ; with input buffer
    LOD Ra, [#rv+20]                        ; see bool equal returned
    MOV Rb, #0x01
    CMP Ra, Rb                              ; compare
    JNZ[#.caseMATH-start]                   ; if false, check next command
    CALL[#printCMD-start]                   ; else execute command
    MOV PC, #.exit-start

    .caseMATH:
    MOV Si, #math_cmd
    STX [#rv+18], Si                        ; compare "math "
    CALL [#cmpStr-start]                    ; with input buffer
    LOD Ra, [#rv+20]                        ; see bool equal returned
    MOV Rb, #0x01
    CMP Ra, Rb                              ; compare
    JNZ[#.casePEEK-start]                   ; if false, check next command
    CALL [#mathCMD-start]                   ; else execute command
    MOV PC, #.exit-start

    .casePEEK:
    MOV Si, #peek_cmd
    STX [#rv+18], Si                        ; compare "peek "
    CALL [#cmpStr-start]                    ; with input buffer
    LOD Ra, [#rv+20]                        ; see bool equal returned
    MOV Rb, #0x01
    CMP Ra, Rb                              ; compare
    JNZ[#.casePOKE-start]                    ; if false, check next command
    CALL [#peekCMD-start]                   ; else execute command
    MOV PC, #.exit-start

    .casePOKE:
    MOV Si, #poke_cmd
    STX [#rv+18], Si                        ; compare "poke "
    CALL [#cmpStr-start]                    ; with input buffer
    LOD Ra, [#rv+20]                        ; see bool equal returned
    MOV Rb, #0x01
    CMP Ra, Rb                              ; compare
    JNZ[#.caseCLEAR-start]                    ; if false, check next command
    CALL [#pokeCMD-start]                   ; else execute command
    MOV PC, #.exit-start

    ; FROM HERE escapeChar = \0
    
    .caseCLEAR:
    MOV Ra, #0x00                           ; escape char to cmp \0
    STO [#rv+15], Ra
    MOV Si, #clear_cmd
    STX [#rv+18], Si                        ; compare "clear"
    CALL [#cmpStr-start]                    ; with input buffer
    LOD Ra, [#rv+20]                        ; see bool equal returned
    MOV Rb, #0x01
    CMP Ra, Rb                              ; compare
    JNZ[#.caseDISPLAY-start]                ; if false, check next command
    CALL [#clearCMD-start]                  ; else execute command
    MOV PC, #.exit-start

    .caseDISPLAY:
    MOV Si, #display_cmd
    STX [#rv+18], Si                        ; compare "display"
    CALL [#cmpStr-start]                    ; with input buffer
    LOD Ra, [#rv+20]                        ; see bool equal returned
    MOV Rb, #0x01
    CMP Ra, Rb                              ; compare
    JNZ [#.default-start]                   ; if false, check next command
    MOV Ra, #0xC3                           ; else execute command
    MOV SND, Ra                             
    MOV PC, #.exit-start

    .default:
    CALL [#newLine-start]                   ; print \n
    MOV Si, #notFound                       ; string pointer to print
    STX [#rv+8], Si
    MOV Ra, #0x0A                           ; EOT char=\n
    STO [#rv+13], Ra
    MOV Ra, #0x00                           ; device = 0 (ROM)
    STO [#rv+14], Ra
    CALL [#writeString-start]               ; print notFound string and exit


    .exit:
    POP Si
    POP Rd
    POP Rc
    POP Rb
    POP Ra
    POP PC                                  ; return
endprocessCMD:

end:


kbHandler:  ; ISR(vector keyboard)		Starts in ram at 0xFEFE
    PUSH Ra
    PUSH Rb
    PUSH Rc
	PUSH Rd
    IN Rd										; Get kb data into Rd
    PUSH Di
    MOV Ra, STT                                 ; PUSH STT
    PUSH Ra

    ; keyboardDecode()
	LOD Ra, [#rv+6]								; load released
	MOV Rb, #0x01								; check if released
	CMP Ra, Rb
	JNZ [#.pressed-kbHandler+0x0FEFE]			; if not, go to pressed case

	.released:									; last key was a break code
		DEC Rb									; Rb now holds 0x00 (false)
		.case0x59_rel:
		MOV Rc, #0x59							; check R_SHIFT
		CMP Rc, Rd
		JNZ [#.case0x12_rel-kbHandler+0x0FEFE]	; check next case
		STO [#rv+5], Rb							; shifted = 0
		MOV PC, #.break1-kbHandler+0x0FEFE		; break

		.case0x12_rel:
		MOV Rc, #0x12							; check L_SHIFT
		CMP Rc, Rd
		JNZ [#.default1-kbHandler+0x0FEFE]		; check next case (default)
		STO [#rv+5], Rb							; shifted = 0
												; break

		.default1:								; do nothing (break), written for legibility
		.break1:
		STO [#rv+6], Rb							; released = 0
		MOV PC, #.continue1-kbHandler+0x0FEFE	; if released, don't execute the pressed condition

	.pressed:									; input is make code
												; Rb holds 0x01 (true)
		.case0x59_prs:
		MOV Rc, #0x59							; check R_SHIFT
		CMP Rc, Rd
		JNZ [#.case0x12_prs-kbHandler+0x0FEFE]	; check next case
		STO [#rv+5], Rb							; shifted = 1
		MOV PC, #.break2-kbHandler+0x0FEFE		; break

		.case0x12_prs:
		MOV Rc, #0x12							; check L_SHIFT
		CMP Rc, Rd
		JNZ [#.case0xF0_prs-kbHandler+0x0FEFE]	; check next case
		STO [#rv+5], Rb							; shifted = 1
		MOV PC, #.break2-kbHandler+0x0FEFE		; break

		.case0xF0_prs:
		MOV Rc, #0xF0							; check break code
		CMP Rc, Rd
		JNZ [#.default2-kbHandler+0x0FEFE]		; check next case (default)
		STO [#rv+6], Rb							; released = 1
		MOV PC, #.break2-kbHandler+0x0FEFE		; break

		.default2:                              ; getASCII()
        ; Rb holds 0x01
        LOD Ra, [#rv+5]                         ; load shifted
        CMP Ra, Rb                              ; if shifted == true
        MOV Rb, #0x00                           ; default offset = 0
        JNZ [#.continue2-kbHandler+0x0FEFE]     ; then set offset else continue

        ; RaRb will now be treated as a 16bit register to calculate the 
        ; address to load the ASCII code

        .setOffset:
            MOV Rb, #0x80                       ; offset to reference the shifted table
        .continue2:
        MOV Ra, #makeCodes[15:8]                ; Ra now holds makeCodes table MSB byte start address
        ADD Rb, Rd                              ; Rb = offset + makeCode
        ; 0x00<makeCode<0X7F ==> No need to do ADC if makeCodes[7:0] == 0x00
        MOV Di, RaRb                            ; Set Di to address the ASCII code
        LDD Rc, [Di]                            ; load ASCII code from ROM


        .caseBKSP:
        MOV Rd, #0x08							; check if  c == BACKSPACE
		CMP Rc, Rd
		JNZ [#.caseENTER-kbHandler+0x0FEFE]	    ; check next case
        MOV Rb, #0x20                           ; write ' ' in case cursor was on
        STO [#rv+7], Rb
        CALL [#writeChar-start]
		LOD Rb, [#rv+0]                         ; load cursor X
        MOV Rd, #0x06
        SUB Rb, Rd                              ; set previous cursor position
        STO [#rv+0], Rb                         ; and store it
        MOV Rb, #0x20                           ; print ' ' without updating cursor
        STO [#rv+7], Rb                         ; store in char c
        CALL [#writeChar-start]                 ; write char on screen
        LDX Di, [#rv+11]                        ; load *endInBuffer
        DEC Di                                  ; decrease pointer
        STX [#rv+11], Di                        ; store pointer
		MOV PC, #.continue1-kbHandler+0x0FEFE   ; break

        .caseENTER:
        MOV Rd, #0x0D							; check if  c == ENTER
		CMP Rc, Rd
		JNZ [#.caseTAB-kbHandler+0x0FEFE]	    ; check next case
        LDX Di, [#rv+11]                        ; load *endInBuffer
        MOV Ra, #0x00                           ; write EOT char
        STO [Di], Ra                          
        STO [#rv+7], Ra                         ; write ' ' in case cursor was on
        CALL [#writeChar-start]
        CALL [#processCMD-start]                ; process command
        CALL [#newLine-start]                   ; print \n
        MOV Rc, #0x3E                           ; print '>'
        STO [#rv+7], Rc
        CALL [#writeChar-start]
        MOV Ra, #0x24+8                         ; cursorX = 0x24+8
        STO [#rv+0], Ra                          
        MOV Di, #inputBuffer                    ; reset *endinBuffer
        STX [#rv+11], Di        
		MOV PC, #.continue1-kbHandler+0x0FEFE   ; break

        .caseTAB:
        MOV Rd, #0x09							; check if  c == TAB
		CMP Rc, Rd
		JNZ [#.caseCHAR-kbHandler+0x0FEFE]	    ; check next case  
        MOV Ra, #0x20							; write ' ' in case cursor was on             
        STO [#rv+7], Ra                         
        CALL [#writeChar-start]
        MOV Rb, #0x24+2                         ; reset x cursor
        STO [#rv+0], Rb                         ; and store it
        LOD Rb, [#rv+1]                         ; load y cursor
        MOV Rd, #0x09                           ; Increase y cursor to next line
        ADD Rb, Rd
        STO [#rv+1], Rb                         ; and store it                          
		MOV PC, #.continue1-kbHandler+0x0FEFE   ; break

        .caseCHAR:
        STO [#rv+7], Rc                         ; store result
        CALL [#writeChar-start]                 ; write char on screen
        LDX Di, [#rv+11]                        ; load *endInBuffer
        STO [Di], Rc                            ; save input character
        INC Di                                  ; increase pointer
        STX [#rv+11], Di                        ; store pointer
        LOD Rc, [#rv+0]                         ; load cursor X
        MOV Rd, #0x06
        ADD Rc, Rd                              ; set next cursor position
        STO [#rv+0], Rc                         ; and store it
											    ; break

		.break2:

	.continue1:

    POP Ra                                      ; POP STT
    MOV STT, Ra
    POP Di
    POP Rd
    POP Rc
    POP Rb
    POP Ra
    POP PC                                      ; return
kbEnd:

#addr 0x3000
string:
    #str ">Console v0.56\n"
notFound:
    #str "Command not found\n"
error1:
    #str "Uint overflow\n"
error2:
    #str "Invalid syntax\n"
display_cmd:
    #str "display\0"
print_cmd:
    #str "print "
math_cmd:
    #str "math "
peek_cmd:
    #str "peek "
poke_cmd:
    #str "poke "
clear_cmd:
    #str "clear\0"
offsetChars:
        ;'p'    'g'      'q'     'y'
    #d8 0x70,  0x67,    0x71,    0x79 

font = 0x4000           ; font start address
#addr font              ; font
    #d8 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  ; 0x20, Space
    #d8 0x04, 0x04, 0x04, 0x04, 0x04, 0x00, 0x04  ; 0x21, !
    #d8 0x09, 0x09, 0x12, 0x00, 0x00, 0x00, 0x00  ; 0x22, "
    #d8 0x0a, 0x0a, 0x1f, 0x0a, 0x1f, 0x0a, 0x0a  ; 0x23, #
    #d8 0x04, 0x0f, 0x14, 0x0e, 0x05, 0x1e, 0x04  ; 0x24, $
    #d8 0x19, 0x19, 0x02, 0x04, 0x08, 0x13, 0x13  ; 0x25, %
    #d8 0x04, 0x0a, 0x0a, 0x0a, 0x15, 0x12, 0x0d  ; 0x26, &
    #d8 0x04, 0x04, 0x08, 0x00, 0x00, 0x00, 0x00  ; 0x27, '
    #d8 0x02, 0x04, 0x08, 0x08, 0x08, 0x04, 0x02  ; 0x28, (
    #d8 0x08, 0x04, 0x02, 0x02, 0x02, 0x04, 0x08  ; 0x29, )
    #d8 0x04, 0x15, 0x0e, 0x1f, 0x0e, 0x15, 0x04  ; 0x2a, *
    #d8 0x00, 0x04, 0x04, 0x1f, 0x04, 0x04, 0x00  ; 0x2b, +
    #d8 0x00, 0x00, 0x00, 0x00, 0x04, 0x04, 0x08  ; 0x2c, ,
    #d8 0x00, 0x00, 0x00, 0x1f, 0x00, 0x00, 0x00  ; 0x2d, -
    #d8 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x0c  ; 0x2e, .
    #d8 0x01, 0x01, 0x02, 0x04, 0x08, 0x10, 0x10  ; 0x2f, /
    #d8 0x0e, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0e  ; 0x30, 0
    #d8 0x04, 0x0c, 0x04, 0x04, 0x04, 0x04, 0x0e  ; 0x31, 1
    #d8 0x0e, 0x11, 0x01, 0x02, 0x04, 0x08, 0x1f  ; 0x32, 2
    #d8 0x0e, 0x11, 0x01, 0x06, 0x01, 0x11, 0x0e  ; 0x33, 3
    #d8 0x02, 0x06, 0x0a, 0x12, 0x1f, 0x02, 0x02  ; 0x34, 4
    #d8 0x1f, 0x10, 0x1e, 0x01, 0x01, 0x11, 0x0e  ; 0x35, 5
    #d8 0x06, 0x08, 0x10, 0x1e, 0x11, 0x11, 0x0e  ; 0x36, 6
    #d8 0x1f, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08  ; 0x37, 7
    #d8 0x0e, 0x11, 0x11, 0x0e, 0x11, 0x11, 0x0e  ; 0x38, 8
    #d8 0x0e, 0x11, 0x11, 0x0f, 0x01, 0x02, 0x0c  ; 0x39, 9
    #d8 0x00, 0x0c, 0x0c, 0x00, 0x0c, 0x0c, 0x00  ; 0x3a, :
    #d8 0x00, 0x0c, 0x0c, 0x00, 0x0c, 0x04, 0x08  ; 0x3b, ;
    #d8 0x02, 0x04, 0x08, 0x10, 0x08, 0x04, 0x02  ; 0x3c, <
    #d8 0x00, 0x00, 0x1f, 0x00, 0x1f, 0x00, 0x00  ; 0x3d, =
    #d8 0x08, 0x04, 0x02, 0x01, 0x02, 0x04, 0x08  ; 0x3e, >
    #d8 0x0e, 0x11, 0x01, 0x02, 0x04, 0x00, 0x04  ; 0x3f, ?

    #d8 0x0e, 0x11, 0x17, 0x15, 0x17, 0x10, 0x0f  ; 0x40, @
    #d8 0x04, 0x0a, 0x11, 0x11, 0x1f, 0x11, 0x11  ; 0x41, A
    #d8 0x1e, 0x11, 0x11, 0x1e, 0x11, 0x11, 0x1e  ; 0x42, B
    #d8 0x0e, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0e  ; 0x43, C
    #d8 0x1e, 0x09, 0x09, 0x09, 0x09, 0x09, 0x1e  ; 0x44, D
    #d8 0x1f, 0x10, 0x10, 0x1c, 0x10, 0x10, 0x1f  ; 0x45, E
    #d8 0x1f, 0x10, 0x10, 0x1f, 0x10, 0x10, 0x10  ; 0x46, F
    #d8 0x0e, 0x11, 0x10, 0x10, 0x13, 0x11, 0x0f  ; 0x37, G
    #d8 0x11, 0x11, 0x11, 0x1f, 0x11, 0x11, 0x11  ; 0x48, H
    #d8 0x0e, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0e  ; 0x49, I
    #d8 0x1f, 0x02, 0x02, 0x02, 0x02, 0x12, 0x0c  ; 0x4a, J
    #d8 0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11  ; 0x4b, K
    #d8 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1f  ; 0x4c, L
    #d8 0x11, 0x1b, 0x15, 0x11, 0x11, 0x11, 0x11  ; 0x4d, M
    #d8 0x11, 0x11, 0x19, 0x15, 0x13, 0x11, 0x11  ; 0x4e, N
    #d8 0x0e, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0e  ; 0x4f, O
    #d8 0x1e, 0x11, 0x11, 0x1e, 0x10, 0x10, 0x10  ; 0x50, P
    #d8 0x0e, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0d  ; 0x51, Q
    #d8 0x1e, 0x11, 0x11, 0x1e, 0x14, 0x12, 0x11  ; 0x52, R
    #d8 0x0e, 0x11, 0x10, 0x0e, 0x01, 0x11, 0x0e  ; 0x53, S
    #d8 0x1f, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04  ; 0x54, T
    #d8 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0e  ; 0x55, U
    #d8 0x11, 0x11, 0x11, 0x11, 0x11, 0x0a, 0x04  ; 0x56, V
    #d8 0x11, 0x11, 0x11, 0x15, 0x15, 0x1b, 0x11  ; 0x57, W
    #d8 0x11, 0x11, 0x0a, 0x04, 0x0a, 0x11, 0x11  ; 0x58, X
    #d8 0x11, 0x11, 0x0a, 0x04, 0x04, 0x04, 0x04  ; 0x59, Y
    #d8 0x1f, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1f  ; 0x5a, Z
    #d8 0x0e, 0x08, 0x08, 0x08, 0x08, 0x08, 0x0e  ; 0x5b, [
    #d8 0x10, 0x10, 0x08, 0x04, 0x02, 0x01, 0x01  ; 0x5c, \
    #d8 0x0e, 0x02, 0x02, 0x02, 0x02, 0x02, 0x0e  ; 0x5d, ]
    #d8 0x04, 0x0a, 0x11, 0x00, 0x00, 0x00, 0x00  ; 0x5e, ^
    #d8 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f  ; 0x5f, _

    #d8 0x04, 0x04, 0x02, 0x00, 0x00, 0x00, 0x00  ; 0x60, `
    #d8 0x00, 0x00, 0x0e, 0x01, 0x0d, 0x13, 0x0d  ; 0x61, a
    #d8 0x10, 0x10, 0x10, 0x1c, 0x12, 0x12, 0x1c  ; 0x62, b
    #d8 0x00, 0x00, 0x0e, 0x10, 0x10, 0x10, 0x0e  ; 0x63, c
    #d8 0x01, 0x01, 0x01, 0x07, 0x09, 0x09, 0x07  ; 0x64, d
    #d8 0x00, 0x00, 0x0e, 0x11, 0x1f, 0x10, 0x0f  ; 0x65, e
    #d8 0x06, 0x09, 0x08, 0x1c, 0x08, 0x08, 0x08  ; 0x66, f
    #d8 0x00, 0x0e, 0x11, 0x13, 0x0d, 0x01, 0x0e  ; 0x67, g
    #d8 0x10, 0x10, 0x10, 0x16, 0x19, 0x11, 0x11  ; 0x68, h
    #d8 0x00, 0x04, 0x00, 0x0c, 0x04, 0x04, 0x0e  ; 0x69, i
    #d8 0x02, 0x00, 0x06, 0x02, 0x02, 0x12, 0x0c  ; 0x6a, j
    #d8 0x10, 0x10, 0x12, 0x14, 0x18, 0x14, 0x12  ; 0x6b, k
    #d8 0x0c, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04  ; 0x6c, l
    #d8 0x00, 0x00, 0x0a, 0x15, 0x15, 0x11, 0x11  ; 0x6d, m
    #d8 0x00, 0x00, 0x16, 0x19, 0x11, 0x11, 0x11  ; 0x6e, n
    #d8 0x00, 0x00, 0x0e, 0x11, 0x11, 0x11, 0x0e  ; 0x6f, o
    #d8 0x00, 0x1c, 0x12, 0x12, 0x1c, 0x10, 0x10  ; 0x70, p
    #d8 0x00, 0x07, 0x09, 0x09, 0x07, 0x01, 0x01  ; 0x71, q
    #d8 0x00, 0x00, 0x16, 0x19, 0x10, 0x10, 0x10  ; 0x72, r
    #d8 0x00, 0x00, 0x0f, 0x10, 0x0e, 0x01, 0x1e  ; 0x73, s
    #d8 0x08, 0x08, 0x1c, 0x08, 0x08, 0x09, 0x06  ; 0x74, t
    #d8 0x00, 0x00, 0x11, 0x11, 0x11, 0x13, 0x0d  ; 0x75, u
    #d8 0x00, 0x00, 0x11, 0x11, 0x11, 0x0a, 0x04  ; 0x76, v
    #d8 0x00, 0x00, 0x11, 0x11, 0x15, 0x15, 0x0a  ; 0x77, w
    #d8 0x00, 0x00, 0x11, 0x0a, 0x04, 0x0a, 0x11  ; 0x78, x
    #d8 0x00, 0x11, 0x11, 0x0f, 0x01, 0x11, 0x0e  ; 0x79, y
    #d8 0x00, 0x00, 0x1f, 0x02, 0x04, 0x08, 0x1f  ; 0x7a, z
    #d8 0x06, 0x08, 0x08, 0x10, 0x08, 0x08, 0x06  ; 0x7b, {
    #d8 0x04, 0x04, 0x04, 0x00, 0x04, 0x04, 0x04  ; 0x7c, |
    #d8 0x0c, 0x02, 0x02, 0x01, 0x02, 0x02, 0x0c  ; 0x7d, }
    #d8 0x08, 0x15, 0x02, 0x00, 0x00, 0x00, 0x00  ; 0x7e, ~
    #d8 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f  ; 0x7f, DEL


makeCodes = 0x5000      ; make code to ascii table start address
#addr makeCodes
    ;      0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
    #d8 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0x7E, 0x00
    #d8 0x00, 0x00, 0x00, 0x00, 0x00, 0x71, 0x31, 0x00, 0x00, 0x00, 0x7a, 0x73, 0x61, 0x77, 0x32, 0x00
    #d8 0x00, 0x63, 0x78, 0x64, 0x65, 0x34, 0x33, 0x00, 0x20, 0x20, 0x76, 0x66, 0x74, 0x72, 0x35, 0x00
    #d8 0x00, 0x6e, 0x62, 0x68, 0x67, 0x79, 0x36, 0x00, 0x00, 0x00, 0x6d, 0x6a, 0x75, 0x37, 0x38, 0x00
    #d8 0x00, 0x2c, 0x6b, 0x69, 0x6f, 0x30, 0x39, 0x00, 0x00, 0x2e, 0x2d, 0x6c, 0x3b, 0x70, 0x27, 0x00
    #d8 0x00, 0x00, 0x27, 0x00, 0x00, 0x3d, 0x00, 0x00, 0x00, 0x00, 0x0D, 0x2B, 0x00, 0x7c, 0x00, 0x00
    #d8 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    #d8 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ;Shifted
    #d8 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0x5C, 0x00
    #d8 0x00, 0x00, 0x00, 0x00, 0x00, 0x51, 0x21, 0x00, 0x00, 0x00, 0x5a, 0x53, 0x41, 0x57, 0x22, 0x00
    #d8 0x00, 0x43, 0x58, 0x44, 0x45, 0x24, 0x23, 0x00, 0x20, 0x20, 0x56, 0x46, 0x54, 0x52, 0x25, 0x00
    #d8 0x00, 0x4e, 0x42, 0x48, 0x47, 0x59, 0x26, 0x00, 0x00, 0x00, 0x4d, 0x4a, 0x55, 0x2F, 0x28, 0x00
    #d8 0x00, 0x3b, 0x4b, 0x49, 0x4f, 0x3D, 0x29, 0x00, 0x00, 0x3a, 0x5f, 0x4c, 0x3b, 0x50, 0x3F, 0x00
    #d8 0x00, 0x00, 0x27, 0x00, 0x5E, 0x3d, 0x00, 0x00, 0x00, 0x00, 0x0D, 0x2A, 0x00, 0x5c, 0x00, 0x00
    #d8 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    #d8 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

#addr 0x0FFFF
memswitch:
    MOV STT, Ra   ; Reset boot flag, next instruction will be
                  ; fetched from RAM

#addr 0x1FFFF     ; for the EEPROM programmer
#d8 0xFF