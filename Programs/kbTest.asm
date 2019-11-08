#include "cpudef.asm"

;kbTest

bootload:
  #addr 0x00
  MOV Ra, #0x00     ; Init LCD, ensure IS==0
  MOV CTL, Ra
  MOV Ra, #0x3F     ;Function set: 8bit, 2 lines
  MOV SND, Ra
  MOV Ra, #0x0F     ; Display on, blinking cursor
  MOV SND, Ra
  MOV Ra, #0x01     ; Clear display
  MOV SND, Ra
  MOV Ra, #0x04     ; RS==1
  MOV CTL, Ra

  MOV Si, #0x00     ; RAM program start address to be copied to
  MOV Di, #start    ; ROM address to start copying from
  MOV Rd, #(end - start+1)[7:0]     ; RAM program length (LSB)
  MOV Rc, #(end - start+1)[15:8]    ; RAM program length (MSB)

copyseq:
  CPY [Si], [Di]    ;Copy from ROM to RAM at desired locations(auto increment)
  DEC Rd
  JNZ [#copyseq]    ; If finished copying continue


  MOV Si, #0xFEFE   ; copy keyboard handler
  MOV Di, #kbHandler
  MOV Rd, #(kbEnd - kbHandler)[7:0]     ; handler length (LSB)

copyHan:
  CPY [Si], [Di]
  DEC Rd
  JNZ [#copyHan]    ; If finished copying continue

  MOV Ra, STT       ; STT |= 0x40
  MOV Rb, #0x40
  OR  Ra, Rb
  MOV PC, #memswitch ; Next instruction will change instruction fetch
                     ; memory device



start:
  NOP
  NOP
  MOV SP, #0x02FF   ; initialize stack
  MOV Si, #0x00FF   ; bool lastChar==breakByte
  MOV Ra, #0x00
  STO [Si], Ra      ; intialize to false
  MOV Ra, #0x00     ; IS==0
  MOV CTL, Ra
  MOV Ra, #0x00     ; short writtenChars = 0
  STO [#0x0100], Ra


init:
  MOV Rb, #0x40     ; Enable interrupts
  MOV STT, Rb
  LOD Rb, [#0x0100] ;

loop:               ; lose time when not busy
  MOV Ra, #0x80
shift:
  LSR Ra
  JC [#init-start]
  MOV PC, #shift-start
  NOP


end:

kbHandler:
  PUSH Ra
  IN Rd               ; Input kb data to Rd

  LOD Ra, [Si]        ; load lastChar==breakByte
  MOV Rb, #0x01
  CMP Ra, Rb          ; check if true
  JNZ [#checkBreakCode-kbHandler+0x0FEFE]
  MOV Ra, #0x00           ; set to false
  STO [Si], Ra            ; store bool
  MOV PC, #return-kbHandler+0x0FEFE  ;exit

checkBreakCode:
  MOV Ra, #0x00           ; default bool value
  MOV Rb, #0xF0           ; break code
  CMP Rb, Rd              ; if input is break code
  JNZ [#continue1-kbHandler+0x0FEFE]
  MOV Ra, #0x01           ; set to true
  STO [Si], Ra            ; store bool
  MOV PC, #return-kbHandler+0x0FEFE   ; exit

continue1:
  STO [Si], Ra        ; store bool

checkEOL:
  LOD Ra, [#0x0100]    ; load writtenChars

endL2:
  MOV Rb, #0x20
  CMP Ra, Rb           ; if reached EOL2 (>=)
  JN [#endL1-kbHandler+0x0FEFE]
  MOV Ra, #0xFF         ;reset writtenChars
  MOV Rb, #0x01         ; clear screen
  MOV SND, Rb
  MOV PC, #continue2-kbHandler+0x0FEFE

endL1:
  MOV Rb, #0x10        ; if reached EOL1
  CMP Ra, Rb
  JNZ [#continue2-kbHandler+0x0FEFE]
  MOV Rb, #0xC0        ; go to next line
  MOV SND, Rb

continue2:
  INC Ra
  STO [#0x0100], Ra


  MOV Rb, #0x1F        ; ' ' - 1
  MOV Di, #0xFF00      ; ROM make code array pointer
  MOV Ra, #0x00        ; end of array

checkChar:
  INC Rb                  ; char++
  LDD Rc, [Di]            ; load make code from ROM (auto increment)
  CMP Ra, Rc              ; if reached the end
  JZ [#return-kbHandler+0x0FEFE]      ; exit(error)
  CMP Rd, Rc              ; if not found
  JNZ [#checkChar-kbHandler+0x0FEFE]  ; check next code

  MOV Ra, #0x04     ; IS==1
  MOV CTL, Ra
  MOV SND, Rb       ; print char
  MOV Ra, #0x00     ; IS==0
  MOV CTL, Ra

return:
  POP Ra
  POP PC    ;return
  NOP


kbEnd:


#addr 0xFF00    ; make codes from ' ' to ']'
#d8 0x29, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x52, 0xFF, 0xFF, 0xFF, 0xFF
#d8 0x41, 0x4E, 0x49, 0x4A, 0x45, 0x16, 0x1E, 0x26, 0x25, 0x2E, 0x36, 0x3D
#d8 0x3E, 0x46, 0xFF, 0x4C, 0xFF, 0x55, 0xFF, 0xFF, 0xFF, 0x1C, 0x32, 0x21
#d8 0x23, 0x24, 0x2B, 0x34, 0x33, 0x43, 0x3B, 0x42, 0x4B, 0x3A, 0x31, 0x44
#d8 0x4D, 0x15, 0x2D, 0x1B, 0x2C, 0x3C, 0x2A, 0x1D, 0x22, 0x35, 0x1A, 0x54
#d8 0xFF, 0x5B


#addr 0x0FFFF
memswitch:
MOV STT, Ra   ; Reset boot flag, next instruction will be
              ; fetched from RAM

#addr 0x1FFFF
#d8 0xFF
