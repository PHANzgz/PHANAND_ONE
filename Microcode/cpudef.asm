#cpudef
{
	#bits 8
	MOV Ra, Rb		-> 0x00
	MOV Ra, Rc		-> 0x01
	MOV Ra, Rd		-> 0x02
	MOV Rb, Ra		-> 0x03
	MOV Rb, Rc		-> 0x04
	MOV Rb, Rd		-> 0x05
	MOV Rc, Ra		-> 0x06
	MOV Rc, Rb		-> 0x07
	MOV Rc, Rd		-> 0x08
	MOV Rd, Ra		-> 0x09
	MOV Rd, Rb		-> 0x0A
	MOV Rd, Rc		-> 0x0B
	MOV PC, SP		-> 0x0C
	MOV PC, Si		-> 0x0D
	MOV PC, Di		-> 0x0E
	MOV SP, PC		-> 0x0F
	MOV SP, Si		-> 0x10
	MOV SP, Di		-> 0x11
	MOV Si, PC		-> 0x12
	MOV Si, SP		-> 0x13
	MOV Si, Di		-> 0x14
	MOV Di, PC		-> 0x15
	MOV Di, SP		-> 0x16
	MOV Di, Si		-> 0x17
	MOV PC, RaRb		-> 0x18
	MOV PC, RcRd		-> 0x19
	MOV SP, RaRb		-> 0x1A
	MOV SP, RcRd		-> 0x1B
	MOV Si, RaRb		-> 0x1C
	MOV Si, RcRd		-> 0x1D
	MOV Di, RaRb		-> 0x1E
	MOV Di, RcRd		-> 0x1F
	MOV RaRb, PC		-> 0x20
	MOV RaRb, SP		-> 0x21
	MOV RaRb, Si		-> 0x22
	MOV RaRb, Di		-> 0x23
	MOV RcRd, PC		-> 0x24
	MOV RcRd, SP		-> 0x25
	MOV RcRd, Si		-> 0x26
	MOV RcRd, Di		-> 0x27
	MOV Ra, #{imm}		-> 0x28 @ imm[7:0]
	MOV Rb, #{imm}		-> 0x29 @ imm[7:0]
	MOV Rc, #{imm}		-> 0x2A @ imm[7:0]
	MOV Rd, #{imm}		-> 0x2B @ imm[7:0]
	MOV PC, #{imm}		-> 0x2C @ imm[15:0]
	MOV SP, #{imm}		-> 0x2D @ imm[15:0]
	MOV Si, #{imm}		-> 0x2E @ imm[15:0]
	MOV Di, #{imm}		-> 0x2F @ imm[15:0]
	MOV STT, Ra		-> 0x30
	MOV STT, Rb		-> 0x31
	MOV STT, Rc		-> 0x32
	MOV STT, Rd		-> 0x33
	MOV CTL, Ra		-> 0x34
	MOV CTL, Rb		-> 0x35
	MOV CTL, Rc		-> 0x36
	MOV CTL, Rd		-> 0x37
	MOV VRAM, Ra		-> 0x38
	MOV VRAM, Rb		-> 0x39
	MOV VRAM, Rc		-> 0x3A
	MOV VRAM, Rd		-> 0x3B
	MOV AVR, Ra		-> 0x3C
	MOV AVR, Rb		-> 0x3D
	MOV AVR, Rc		-> 0x3E
	MOV AVR, Rd		-> 0x3F
	MOV IN, Ra		-> 0x40
	MOV IN, Rb		-> 0x41
	MOV IN, Rc		-> 0x42
	MOV IN, Rd		-> 0x43
	MOV SND, Ra		-> 0x44
	MOV SND, Rb		-> 0x45
	MOV SND, Rc		-> 0x46
	MOV SND, Rd		-> 0x47
	MOV Ra, STT		-> 0x48
	MOV Ra, CTL		-> 0x49
	MOV Ra, IN		-> 0x4A
	MOV Rb, STT		-> 0x4B
	MOV Rb, CTL		-> 0x4C
	MOV Rb, IN		-> 0x4D
	MOV Rc, STT		-> 0x4E
	MOV Rc, CTL		-> 0x4F
	MOV Rc, IN		-> 0x50
	LOD Ra, [#{imm}]	-> 0x51 @ imm[15:0]
	LOD Rb, [#{imm}]	-> 0x52 @ imm[15:0]
	LOD Rc, [#{imm}]	-> 0x53 @ imm[15:0]
	LOD Rd, [#{imm}]	-> 0x54 @ imm[15:0]
	LOD Ra, [Si]		-> 0x55
	LOD Ra, [Di]		-> 0x56
	LOD Rb, [Si]		-> 0x57
	LOD Rb, [Di]		-> 0x58
	LOD Rc, [Si]		-> 0x59
	LOD Rc, [Di]		-> 0x5A
	LOD Rd, [Si]		-> 0x5B
	LOD Rd, [Di]		-> 0x5C
	STO [#{imm}], Ra	-> 0x5D @ imm[15:0]
	STO [#{imm}], Rb	-> 0x5E @ imm[15:0]
	STO [#{imm}], Rc	-> 0x5F @ imm[15:0]
	STO [#{imm}], Rd	-> 0x60 @ imm[15:0]
	STO [Si], Ra		-> 0x61
	STO [Si], Rb		-> 0x62
	STO [Si], Rc		-> 0x63
	STO [Si], Rd		-> 0x64
	STO [Di], Ra		-> 0x65
	STO [Di], Rb		-> 0x66
	STO [Di], Rc		-> 0x67
	STO [Di], Rd		-> 0x68
	LDX PC, [#{imm}]	-> 0x69 @ imm[15:0]
	LDX SP, [#{imm}]	-> 0x6A @ imm[15:0]
	LDX Si, [#{imm}]	-> 0x6B @ imm[15:0]
	LDX Di, [#{imm}]	-> 0x6C @ imm[15:0]
	LDX Si, [Di]		-> 0x6D
	LDX Di, [Si]		-> 0x6E
	STX [#{imm}], PC	-> 0x6F @ imm[15:0]
	STX [#{imm}], SP	-> 0x70 @ imm[15:0]
	STX [#{imm}], Si	-> 0x71 @ imm[15:0]
	STX [#{imm}], Di	-> 0x72 @ imm[15:0]
	STX [Si], Di		-> 0x73
	STX [Di], Si		-> 0x74
	PUSH Ra			-> 0x75
	PUSH Rb			-> 0x76
	PUSH Rc			-> 0x77
	PUSH Rd			-> 0x78
	POP Ra			-> 0x79
	POP Rb			-> 0x7A
	POP Rc			-> 0x7B
	POP Rd			-> 0x7C
	PUSH PC			-> 0x7D
	PUSH SP			-> 0x7E
	PUSH Si			-> 0x7F
	PUSH Di			-> 0x80
	POP PC			-> 0x81
	POP SP			-> 0x82
	POP Si			-> 0x83
	POP Di			-> 0x84
	CALL [#{imm}]		-> 0x85 @ imm[15:0]
	JC [#{imm}]		-> 0x86 @ imm[15:0]
	JNC [#{imm}]		-> 0x87 @ imm[15:0]
	JZ [#{imm}]		-> 0x88 @ imm[15:0]
	JNZ [#{imm}]		-> 0x89 @ imm[15:0]
	JN [#{imm}]		-> 0x8A @ imm[15:0]
	JP [#{imm}]		-> 0x8B @ imm[15:0]
	JV [#{imm}]		-> 0x8C @ imm[15:0]
	JNV [#{imm}]		-> 0x8D @ imm[15:0]
	ADD Ra, Rb		-> 0x8E
	ADD Ra, Rc		-> 0x8F
	ADD Ra, Rd		-> 0x90
	ADD Rb, Ra		-> 0x91
	ADD Rb, Rc		-> 0x92
	ADD Rb, Rd		-> 0x93
	ADD Rc, Ra		-> 0x94
	ADD Rc, Rb		-> 0x95
	ADD Rc, Rd		-> 0x96
	ADD Rd, Ra		-> 0x97
	ADD Rd, Rb		-> 0x98
	ADD Rd, Rc		-> 0x99
	SUB Ra, Rb		-> 0x9A
	SUB Ra, Rc		-> 0x9B
	SUB Ra, Rd		-> 0x9C
	SUB Rb, Ra		-> 0x9D
	SUB Rb, Rc		-> 0x9E
	SUB Rb, Rd		-> 0x9F
	SUB Rc, Ra		-> 0xA0
	SUB Rc, Rb		-> 0xA1
	SUB Rc, Rd		-> 0xA2
	SUB Rd, Ra		-> 0xA3
	SUB Rd, Rb		-> 0xA4
	SUB Rd, Rc		-> 0xA5
	AND Ra, Rb		-> 0xA6
	AND Ra, Rc		-> 0xA7
	AND Ra, Rd		-> 0xA8
	AND Rb, Ra		-> 0xA9
	AND Rb, Rc		-> 0xAA
	AND Rb, Rd		-> 0xAB
	AND Rc, Ra		-> 0xAC
	AND Rc, Rb		-> 0xAD
	AND Rc, Rd		-> 0xAE
	AND Rd, Ra		-> 0xAF
	AND Rd, Rb		-> 0xB0
	AND Rd, Rc		-> 0xB1
	OR Ra, Rb		-> 0xB2
	OR Ra, Rc		-> 0xB3
	OR Ra, Rd		-> 0xB4
	OR Rb, Ra		-> 0xB5
	OR Rb, Rc		-> 0xB6
	OR Rb, Rd		-> 0xB7
	OR Rc, Ra		-> 0xB8
	OR Rc, Rb		-> 0xB9
	OR Rc, Rd		-> 0xBA
	OR Rd, Ra		-> 0xBB
	OR Rd, Rb		-> 0xBC
	OR Rd, Rc		-> 0xBD
	XOR Ra, Rb		-> 0xBE
	XOR Ra, Rc		-> 0xBF
	XOR Ra, Rd		-> 0xC0
	XOR Rb, Ra		-> 0xC1
	XOR Rb, Rc		-> 0xC2
	XOR Rb, Rd		-> 0xC3
	XOR Rc, Ra		-> 0xC4
	XOR Rc, Rb		-> 0xC5
	XOR Rc, Rd		-> 0xC6
	XOR Rd, Ra		-> 0xC7
	XOR Rd, Rb		-> 0xC8
	XOR Rd, Rc		-> 0xC9
	NOT Ra			-> 0xCA
	NOT Rb			-> 0xCB
	NOT Rc			-> 0xCC
	NOT Rd			-> 0xCD
	LSR Ra			-> 0xCE
	LSR Rb			-> 0xCF
	LSR Rc			-> 0xD0
	LSR Rd			-> 0xD1
	LSL Ra			-> 0xD2
	LSL Rb			-> 0xD3
	LSL Rc			-> 0xD4
	LSL Rd			-> 0xD5
	INC Ra			-> 0xD6
	INC Rb			-> 0xD7
	INC Rc			-> 0xD8
	INC Rd			-> 0xD9
	DEC Ra			-> 0xDA
	DEC Rb			-> 0xDB
	DEC Rc			-> 0xDC
	DEC Rd			-> 0xDD
	INC Si			-> 0xDE
	INC Di			-> 0xDF
	DEC Si			-> 0xE0
	DEC Di			-> 0xE1
	ADC Ra, Rc		-> 0xE2
	ADC Rc, Ra		-> 0xE3
	SBB Ra, Rc		-> 0xE4
	SBB Rc, Ra		-> 0xE5
	CSR Ra			-> 0xE6
	CSR Rb			-> 0xE7
	CSR Rc			-> 0xE8
	CSR Rd			-> 0xE9
	CSL Ra			-> 0xEA
	CSL Rb			-> 0xEB
	CSL Rc			-> 0xEC
	CSL Rd			-> 0xED
	CMP Ra, Rb		-> 0xEE
	CMP Ra, Rc		-> 0xEF
	CMP Ra, Rd		-> 0xF0
	CMP Rb, Ra		-> 0xF1
	CMP Rb, Rc		-> 0xF2
	CMP Rb, Rd		-> 0xF3
	CMP Rc, Ra		-> 0xF4
	CMP Rc, Rb		-> 0xF5
	CMP Rc, Rd		-> 0xF6
	CMP Rd, Ra		-> 0xF7
	CMP Rd, Rb		-> 0xF8
	CMP Rd, Rc		-> 0xF9
	CPY [Si], [Di]		-> 0xFA
	LDD Rc, [Di]		-> 0xFB
	LDD Rd, [Di]		-> 0xFC
	LDD VRAM, [Di]		-> 0xFD
	IN Rd 			-> 0xFE
	NOP 			-> 0xFF
}