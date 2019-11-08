#include "cpudef.asm"

;String to lcd screen

start:
  MOV Ra, #0x00     ; Init LCD, ensure IS==0
  MOV CTL, Ra
  MOV Ra, #0x3F     ;Function set: 8bit, 2 lines
  MOV SND, Ra
  MOV Ra, #0x0F     ; Display on, blinking cursor
  MOV SND, Ra
  MOV Rb, #0x0A     ;next line character to test

init:
  MOV Ra, #0x00     ; ensure IS==0
  MOV CTL, Ra
  MOV Ra, #0x01     ;Clear display
  MOV SND, Ra
  MOV Ra, #0x04     ; RS==1
  MOV CTL, Ra
  MOV Si, #string   ; string pointer

print:
  LOD Ra, [Si]      ; load character
  INC Si            ; increase pointer
  CMP Ra, Rb        ; check EOT
  JZ  [#init]       ; start over
  MOV SND, Ra       ; print char
  MOV PC, #print

string:
  #str "ayy lmao\n"



#addr 0x1FFFF
#d8 0xFF
