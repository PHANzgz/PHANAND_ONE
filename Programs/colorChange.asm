#include "cpudef.asm"

;VRAM test

;Addressable video
; X from 0x24 to 0xC4
; Y from 0x09 to 0x81

bootload:
  #addr 0x00
  MOV Ra, #0x00     ; Init LCD, ensure IS==0
  MOV CTL, Ra
  MOV Ra, #0x3F     ;Function set: 8bit, 2 lines
  MOV SND, Ra
  MOV Ra, #0x0F     ; Display on, blinking cursor
  MOV SND, Ra
  MOV Ra, #0x01     ;Clear display
  MOV SND, Ra
  MOV Ra, #0x04     ; RS==1
  MOV CTL, Ra
  MOV Ra, #0x41     ;Print 'A'
  MOV SND, Ra



  MOV Si, #0x00     ; RAM program start address to be copied to
  MOV Di, #start    ; ROM address to start copying from
  MOV Rd, #(end - start)[7:0]     ; RAM program length (LSB)
  MOV Rc, #(end - start)[15:8]    ; RAM program length (MSB)

  MOV Ra, #0x42     ;Print 'B'
  MOV SND, Ra

copyseq:
  CPY [Si], [Di]    ;Copy from ROM to RAM at desired locations(auto increment)
  DEC Rd
  JNZ [#copyseq]    ; If finished copying continue

  MOV Ra, #0x43     ;Print 'C'
  MOV SND, Ra

  MOV Ra, STT       ; STT |= 0x40
  MOV Rb, #0x40
  OR  Ra, Rb
  MOV PC, #memswitch ; Next instruction will change instruction fetch
                     ; memory device


start:
  NOP
  MOV Ra, #0x44     ;Print 'D'
  MOV SND, Ra
  MOV Ra, #0x03   ; starting color is red
  MOV Si, #0xFF00
  STO [Si], Ra

colorChange:
  MOV Ra, #0x03   ; CTL ^= 0x03
  MOV Rb, CTL
  XOR Rb, Ra
  MOV CTL, Rb

  LOD Rc, [Si]    ; load color
  MOV Rd, #0xC0   ; unused color bits
  OR Rc, Rd
  INC Rc          ; nextColor
  STO [Si], Rc


init:
  MOV Ra, #0x24   ; x starting address
  MOV Rb, #0x09   ; y starting address

writeP:
  MOV AVR, Rb     ; set y
  MOV AVR, Ra     ; set x

  LOD Rc, [Si]    ; load color
  MOV VRAM, Rc

  MOV Rd, #0xC4           ; x end address
  CMP Ra, Rd              ; if reached the end
  JZ [#nextLine-start]    ; go to next line
  INC Ra                  ; else increase x
  MOV PC, #writeP-start   ; and write next pixel

nextLine:
  MOV Ra, #0x24           ; reset X address
  MOV Rd, #0x81           ; y end address
  CMP Rb, Rd              ; if reached the end
  JZ [#colorChange-start] ; finished writing
  INC Rb                  ; else increase Y

  LOD Rc, [Si]    ; load color
  MOV Rd, #0xC0   ; unused color bits
  OR Rc, Rd
  MOV Rd, #0x03
  ADD Rc, Rd      ; changeColor
  STO [Si], Rc

  MOV PC, #writeP-start   ; and write nextLine
  NOP

end:


#addr 0x0FFFF
memswitch:
  MOV STT, Ra   ; Reset boot flag, next instruction will be
                ; fetched from RAM

#addr 0x1FFFF
#d8 0xFF
