#include <stdio.h>
#include <inttypes.h>

#define SOS (uint64_t)1 << 29
#define CN  (uint64_t)1 << 30
#define FO  (uint64_t)1 << 31
#define RT  (uint64_t)1 << 32
#define RI  (uint64_t)1 << 33

#define Ra 1
#define PC 1
#define Rb 2
#define SP 2
#define Rc 3
#define Si 3
#define Rd 4
#define Di 4
#define RAM 5
#define XLX 5
#define RA 5
#define STAT 6
#define Xfer 6
#define CTL 7
#define XLD 8
#define XH 9
#define INS 10
#define ROM 10
#define VRAM 11
#define AVRAM 12
#define ALU 13
#define IN 14
#define SND 15
#define IHAE 15



/*
Control lines
			D7		D6		D5		D5		D3		D2		D1		D0

Byte 4		-		-		-		-		-		-		RI		RT

Byte 3		FO		CN		SOS		ES2		ES1		ES0		XA2		XA1

Byte 2		XA0		XL2		XL1		XL0		DA3		DA2		DA1		DA0

Byte 1		DL3		DL2		DL1		DL0		DS2		DS1		DS0		IS2

Byte 0		IS1		IS0		AA2		AA1		AA0		AL2		AL1		AL0


Register indexes
			0		1		2		3		4		5		6		7		8		9		10		11		12		13		14		15
DataLoad	idle	Ra		Rb		Rc		Rd		RAM		Stts	Ctl		XL		XH		INS		VRAM	AVRAM	ALU		IN		SND
DataAssert	idle	Ra		Rb		Rc		Rd		RAM		Stts	Ctl		XL		XH		ROM		-		-		ALU		IN		IHAE
AuxLoad		idle	Ra		Rb		Rc		Rd		XL		-
AuxAssert	idle	Ra		Rb		Rc		Rd		XL		-
AddLoad		idle	PC		SP		Si		Di		RA		Xfer	-
AddAssert	idle	PC		SP		Si		Di		RA		Xfer	-
AddInc		idle	PC		SP		Si		Di		RA		-
AddDec		idle	PC		SP		Si		Di		RA		-


ALU Ops
	F0		F1		F2		F3		F4		F5		F6		F7
	A+B		A+~B	A&B		A|B		A^B		~A		A>>1	A<<1


Control Inputs
	16		15		14		13		12		11		10		9		8		7		6		5		4		3		2		1		0
	INT		LF		VF		NF		ZF		CF		I7		I6		I5		I4		I3		I2		I1		I0		T2		T1		T0

*/



//typedef unsigned long long uint64_t;

FILE* byte0;
//unsigned char rom[131072];
uint64_t ctlWord[131072] = { 0 };
uint64_t ucode[32][256 * 8] = { 0 };


uint64_t AL(uint64_t index) {
	return index << 0;
}
uint64_t AA(uint64_t index) {
	return index << 3;
}
uint64_t IS(uint64_t index) {
	return index << 6;
}
uint64_t DS(uint64_t index) {
	return index << 9;
}
uint64_t DL(uint64_t index) {
	return index << 12;
}
uint64_t DA(uint64_t index) {
	return index << 16;
}
uint64_t XL(uint64_t index) {
	return index << 20;
}
uint64_t XA(uint64_t index) {
	return index << 23;
}
uint64_t ES(uint64_t index) {
	return index << 26;
}

void programSet(char flags) {

	int instruction = 0;
	int offset = flags << 11;

	//MOV Rx, Ry (12)
	for (char i = Ra; i <= Rd; i++) {
		for (char j = Ra; j <= Rd; j++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.Ra_DL | Rb_DA | RT
				uint64_t inst[8] = { AA(PC)|DA(RAM)|DL(INS)|IS(PC), DL(i)|DA(j)|RT, 0, 0, 0, 0, 0, 0};
				if (i != j) ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			if (i != j) instruction++;
		}
	}

	//MOV RA, RB (12)
	for (char i = PC; i <= Di; i++) {
		for (char j = PC; j <= Di; j++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.RA_AL | RB_AA | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC), AL(i) | AA(j) | RT, 0, 0, 0, 0, 0, 0 };
				if (i != j) ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			if (i != j) instruction++;
		}
	}

	//MOV RA, RxRy (8)
	for (char i = PC; i <= Di; i++) {
		for (char j = Ra; j <= Rc; j+=2) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.Ra_DA | Rb_XA | XH_DL | XL_XL		2.RA_AL | X_AA | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 DL(XH) | XL(XLX) | DA(j) | XA((uint64_t)j+1),	 AL(i) | AA(Xfer) | RT, 0, 0, 0, 0, 0 };
				ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			instruction++;
		}
	}

	//MOV RxRy, RA (8)
	for (char i = Ra; i <= Rc; i += 2) {
		for (char j = PC; j <= Di; j++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.RA_AA | X_AL	 	2.Ra_DL | Rb_XL | XH_DA | XL_XA
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AL(Xfer) | AA(j) ,	 DA(XH) | XA(XLX) | DL(i) | XL((uint64_t)i + 1) | RT, 0, 0, 0, 0, 0 };
				ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			instruction++;
		}
	}

	//MOV Rx, #imm (4)
	for (char i = Ra; i <= Rd; i ++) {
		for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.PC_AA | RAM_DA | Ra_DL | PC_inc
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(PC) | DA(RAM) | DL(i) | IS(PC) | RT , 0, 0, 0, 0, 0, 0 };
				ucode[flags][(instruction << 3) + tstep] = inst[tstep];
		}
			instruction++;
	}

	//MOV RA, #imm (4)
	for (char i = PC; i <= Di; i++) {
		for (char tstep = 0; tstep <= 7; tstep++) {
			// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.PC_AA | RAM_DA | XH_DL | PC_inc	2. PC_AA | RAM_DA | XL_DL | PC_inc	3. X_AA | RA_AL | RT
			uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(PC) | DA(RAM) | DL(XH) | IS(PC),	AA(PC) | DA(RAM) | DL(XLD) | IS(PC),
								AA(Xfer) | AL(i) | RT, 0, 0, 0, 0 };
			ucode[flags][(instruction << 3) + tstep] = inst[tstep];
		}
		instruction++;
	}
	
	//MOV Rs, Rx (24)
	for (char j = 0; j <= 5; j++) {
		char Rs[6] = { STAT, CTL, VRAM, AVRAM, IN, SND };
		for (char i = Ra; i <= Rd; i++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.Rs_DL | Ra_DA | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC), DL(Rs[j]) | DA(i) | RT, 0, 0, 0, 0, 0, 0 };
				ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			instruction++;
		}
	}
	
	//MOV Rx, Rs (9) 
	for (char i = Ra; i <= Rc; i++) {
		char Rs[3] = { STAT, CTL, IN };
		for (char j = 0; j <= 2; j++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.Ra_DL | Rs_DA | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC), DL(i) | DA(Rs[j]) | RT, 0, 0, 0, 0, 0, 0 };
				ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			instruction++;
		}
	}

	//LOD Rx, [#imm] (4)
	for (char i = Ra; i <= Rd; i++) {
		for (char tstep = 0; tstep <= 7; tstep++) {
			// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.PC_AA | RAM_DA | XH_DL | PC_inc	2. PC_AA | RAM_DA | XL_DL | PC_inc	3. X_AA | RAM_DA | Ra_DL | RT
			uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(PC) | DA(RAM) | DL(XH) | IS(PC),	AA(PC) | DA(RAM) | DL(XLD) | IS(PC),
								AA(Xfer) | DA(RAM) | DL(i) | RT, 0, 0, 0, 0 };
			ucode[flags][(instruction << 3) + tstep] = inst[tstep];
		}
		instruction++;
	}

	//LOD Rx, [RA] (8)
	for (char i = Ra; i <= Rd; i++) {
		for (char j = Si; j <= Di; j++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.RA_AA | RAM_DA | Ra_DL | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(j) | DA(RAM) | DL(i) | RT,	 0, 0, 0, 0, 0, 0 };
				ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			instruction++;
		}
	}

	//STO [#imm], Rx (4)
	for (char i = Ra; i <= Rd; i++) {
		for (char tstep = 0; tstep <= 7; tstep++) {
			// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.PC_AA | RAM_DA | XH_DL | PC_inc	2. PC_AA | RAM_DA | XL_DL | PC_inc	3. X_AA | RAM_DL | Ra_DA | RT
			uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(PC) | DA(RAM) | DL(XH) | IS(PC),	AA(PC) | DA(RAM) | DL(XLD) | IS(PC),
								AA(Xfer) | DL(RAM) | DA(i) | RT, 0, 0, 0, 0 };
			ucode[flags][(instruction << 3) + tstep] = inst[tstep];
		}
		instruction++;
	}

	//STO [RA], Rx (8)
	for (char j = Si; j <= Di; j++) {
		for (char i = Ra; i <= Rd; i++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.RA_AA | RAM_DL | Ra_DA | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(j) | DL(RAM) | DA(i) | RT,	 0, 0, 0, 0, 0, 0 };
				ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			instruction++;
		}
	}

	//LDX RA, [#imm] (4)
	for (char i = PC; i <= Di; i++) {
		for (char tstep = 0; tstep <= 7; tstep++) {
			// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.PC_AA | RAM_DA | XH_DL | PC_inc	2. PC_AA | RAM_DA | XL_DL | PC_inc	3. X_AA | RAD_AL
			// 4.RAD_AA | RAD_inc | RAM_DA | XH_DL		5.RAD_AA | RAM_DA | XL_DL			6. X_AA | RA_AL | RT
			uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(PC) | DA(RAM) | DL(XH) | IS(PC),	AA(PC) | DA(RAM) | DL(XLD) | IS(PC),
								AA(Xfer) | AL(RA),		AA(RA) | IS(RA) | DA(RAM) | DL(XH),	 AA(RA) | DA(RAM) | DL(XLD), AA(Xfer) | AL(i) | RT, 0 };
			ucode[flags][(instruction << 3) + tstep] = inst[tstep];
		}
		instruction++;
	}

	//LDX RA, [RB] (2)
	for (char i = Si; i <= Di; i++) {
		for (char j = Si; j <= Di; j++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.RB_AA | RAM_DA | XH_DL | RB_INC	 2.RB_AA | RAM_DA | XL_DL | RB_DEC	3. X_AA | RA_AL | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(j) | IS(j) | DA(RAM) | DL(XH),	 AA(j) | DS(j) | DA(RAM) | DL(XLD), 
									AA(Xfer) | AL(i) | RT, 0, 0, 0, 0 };
				if (i != j) ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			if (i != j) instruction++;
		}
	}

	//STX [#imm], RA (4)
	for (char i = PC; i <= Di; i++) {
		for (char tstep = 0; tstep <= 7; tstep++) {
			// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.PC_AA | RAM_DA | XH_DL | PC_inc	2. PC_AA | RAM_DA | XL_DL | PC_inc	3. X_AA | RAD_AL
			// 4.RA_AA | X_AL		5. RAD_AA | XH_DA | RAM_DL | RAD_inc					6. RAD_AA | XL_DA | RAM_DL | RT
			uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(PC) | DA(RAM) | DL(XH) | IS(PC),	AA(PC) | DA(RAM) | DL(XLD) | IS(PC),
								AA(Xfer) | AL(RA),		AA(i) | AL(Xfer),	 AA(RA) | DA(XH) | DL(RAM) | IS(RA),	 AA(RA) | DA(XLD) | DL(RAM) | RT, 0 };
			ucode[flags][(instruction << 3) + tstep] = inst[tstep];
		}
		instruction++;
	}

	//STX RA, [RB] (2)
	for (char i = Si; i <= Di; i++) {
		for (char j = Si; j <= Di; j++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.RA_AA | X_AL	 2.RB_AA | RAM_DL | XH_DA | RB_INC	3. RB_AA | RAM_DL | XL_DA | RB_DEC | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(i) | AL(Xfer),	 AA(j) | IS(j) | DA(XH) | DL(RAM),
									AA(j) | DS(j) | DA(XLD) | DL(RAM) | RT, 0, 0, 0, 0 };
				if (i != j) ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			if (i != j) instruction++;
		}
	}

	//PUSH Rx
	for (char i = Ra; i <= Rd; i++) {
		for (char tstep = 0; tstep <= 7; tstep++) {
			// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.SP_DEC	2.SP_AA | RAM_DL | Ra_DA | RT
			uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 DS(SP),	AA(SP) | DL(RAM) | DA(i) | RT, 0, 0, 0, 0, 0 };
			ucode[flags][(instruction << 3) + tstep] = inst[tstep];
		}
		instruction++;
	}

	//POP Rx
	for (char i = Ra; i <= Rd; i++) {
		for (char tstep = 0; tstep <= 7; tstep++) {
			// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.SP_AA | RAM_DA | Ra_DL	2.SP_INC | RT
			uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(SP) | DA(RAM) | DL(i),		IS(SP) | RT, 0, 0, 0, 0, 0 };
			ucode[flags][(instruction << 3) + tstep] = inst[tstep];
		}
		instruction++;
	}

	//PUSH RA
	for (char i = PC; i <= Di; i++) {
		for (char tstep = 0; tstep <= 7; tstep++) {
			// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.SP_DEC | RA_AA | X_AL 	2.SP_AA | RAM_DL | XL_DA | SP_DEC	3.SP_AA | RAM_DL | XH_DA | RT
			uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 DS(SP) | AA(i) | AL(Xfer),		AA(SP) | DS(SP) | DL(RAM) | DA(XLD), 
								AA(SP) | DL(RAM) | DA(XH) | RT, 0, 0, 0, 0 };
			ucode[flags][(instruction << 3) + tstep] = inst[tstep];
		}
		instruction++;
	}

	//POP RA
	for (char i = PC; i <= Di; i++) {
		for (char tstep = 0; tstep <= 7; tstep++) {
			// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.SP_AA | SP_INC | RAM_DA | XH_DL 	2.SP_AA | SP_INC | RAM_DA | XL_DL	3.RA_AL | X_AA | RT
			uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(SP) | DA(RAM) | DL(XH) | IS(SP),	AA(SP) | DA(RAM) | DL(XLD) | IS(SP),
								AA(Xfer) | AL(i) | RT, 0, 0, 0, 0 };
			ucode[flags][(instruction << 3) + tstep] = inst[tstep];
		}
		instruction++;
	}

	//CALL [#imm]
	for (char tstep = 0; tstep <= 7; tstep++) {
		// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.PC_AA | RAM_DA | XH_LD | PC_INC 	2.PC_AA | RAM_DA | XL_LD | RA_LD	3. RA_INC | X_AA | PC_AL
		// 4.RA_AA | X_AL | SP_DEC		5. SP_AA | RAM_DL | DA_XL | SP_DEC		6.SP_AA | RAM_DL | XH_DA | RT
		uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(PC) | IS(PC) | DA(RAM) | DL(XH),	AA(PC) | AL(RA) | DA(RAM) | DL(XLD),
							IS(RA) | AA(Xfer) |AL(PC),		AL(Xfer) | AA(RA) | DS(SP),		AA(SP) | DA(XLD) | DL(RAM) | DS(SP),		
							AA(SP) | DA(XH) | DL(RAM) | RT, 0 };
		ucode[flags][(instruction << 3) + tstep] = inst[tstep];
	}
	instruction++;
	
	//Conditional jumps: JC, JNC, JZ, JNZ, JN, JP, JV, JNV
	for (char condJumps = 1; condJumps <= 8; condJumps++) {
		char nf = flags >> ((condJumps-1)/2);
		nf |= (condJumps<=2 ? flags >> 4: 0);  //Support for logical carry flag in JC and JNC
		if ((nf & 1) == 1) {
			if (condJumps % 2 != 0) {
				for (char tstep = 0; tstep <= 7; tstep++) {
					// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.PC_AA | RAM_DA | XH_DL | PC_inc	2. PC_AA | RAM_DA | XL_DL | PC_inc	3. X_AA | PC_AL | RT
					uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(PC) | DA(RAM) | DL(XH) | IS(PC),	AA(PC) | DA(RAM) | DL(XLD) | IS(PC),
									AA(Xfer) | AL(PC) | RT, 0, 0, 0, 0 };
					ucode[flags][(instruction << 3) + tstep] = inst[tstep];
				}
			}
			else {
				for (char tstep = 0; tstep <= 7; tstep++) {
					uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC), IS(PC), IS(PC) | RT, 0, 0, 0, 0, 0 };
					ucode[flags][(instruction << 3) + tstep] = inst[tstep];
				}
			}
			
		}
		else {
			if (condJumps % 2 == 0) {
				for (char tstep = 0; tstep <= 7; tstep++) {
					// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.PC_AA | RAM_DA | XH_DL | PC_inc	2. PC_AA | RAM_DA | XL_DL | PC_inc	3. X_AA | PC_AL | RT
					uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 AA(PC) | DA(RAM) | DL(XH) | IS(PC),	AA(PC) | DA(RAM) | DL(XLD) | IS(PC),
									AA(Xfer) | AL(PC) | RT, 0, 0, 0, 0 };
					ucode[flags][(instruction << 3) + tstep] = inst[tstep];
				}
			}
			else {
				for (char tstep = 0; tstep <= 7; tstep++) {
					uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC), IS(PC), IS(PC) | RT, 0, 0, 0, 0, 0 };
					ucode[flags][(instruction << 3) + tstep] = inst[tstep];
				}
			}
		}
		instruction++;
	} 

	//ADD/SUB/AND/OR/XOR Rx, Ry (60)
	for (char aluOP=0; aluOP<=4; aluOP++){
		uint64_t C = (aluOP == 1 ? CN : 0);
		for (char i = Ra; i <= Rd; i++) {
			for (char j = Ra; j <= Rd; j++) {
				for (char tstep = 0; tstep <= 7; tstep++) {
					// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.Ra_DA | Rb_XA | ALU_DL | ES(X) | SOS | (CN)	 2.Ra_DL | FO | RT
					uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	DA(i) | XA(j) | DL(ALU) | ES(aluOP) | SOS | C ,	 
										DA(ALU) | FO | DL(i) | RT, 0, 0, 0, 0, 0 };
					if (i != j) ucode[flags][(instruction << 3) + tstep] = inst[tstep];
				}
				if (i != j) instruction++;
			}
		}
	}

	//NOT/LSR/LSL Rx (12)
	for (char aluOP = 5; aluOP <= 7; aluOP++) {
		for (char i = Ra; i <= Rd; i++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.Ra_DA | ALU_DL | ES(X)	 2.Ra_DL | FO | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	DA(i) | DL(ALU) | ES(aluOP),
									DA(ALU) | FO | DL(i) | RT, 0, 0, 0, 0, 0 };
				ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			instruction++;
			
		}
	}

	//INC/DEC Rx (8)
	for (char aluOP = 0; aluOP <= 1; aluOP++) {
		uint64_t C = (aluOP == 0 ? CN : 0);
		for (char i = Ra; i <= Rd; i++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.Ra_DA | ALU_DL | ES(X) | C	 2.Ra_DL | FO | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	DA(i) | DL(ALU) | ES(aluOP) | C,
									DA(ALU) | FO | DL(i) | RT, 0, 0, 0, 0, 0 };
				ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			instruction++;

		}
	}

	//INC/DEC RA (4)
	for (char OP = 0; OP <= 1; OP++) {
		for (char i = Si; i <= Di; i++) {
			uint64_t INCorDEC = (OP == 0 ? IS(i) : DS(i));
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.RA_INCorDEC | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	INCorDEC | RT, 0, 0, 0, 0, 0, 0 };
				ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			instruction++;

		}
	}

	//ADC/SBB Rx, Ry (4)
	for (char aluOP = 0; aluOP <= 1; aluOP++) {
		uint64_t C = ((flags & 1) == 1 ? CN : 0);
		for (char i = Ra; i <= Rc; i+=2) {
			for (char j = Ra; j <= Rc; j+=2) {
				for (char tstep = 0; tstep <= 7; tstep++) {
					// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.Ra_DA | Rb_XA | ALU_DL | ES(X) | SOS | (CN)	 2.Ra_DL | FO | RT
					uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	DA(i) | XA(j) | DL(ALU) | ES(aluOP) | SOS | C ,
										DA(ALU) | FO | DL(i) | RT, 0, 0, 0, 0, 0 };
					if (i != j) ucode[flags][(instruction << 3) + tstep] = inst[tstep];
				}
				if (i != j) instruction++;
			}
		}
	}

	//CSR/CSL Rx (8)
	for (char aluOP = 6; aluOP <= 7; aluOP++) {
		uint64_t C = ( ( (flags>>4) & 1) == 1 ? CN : 0);
		for (char i = Ra; i <= Rd; i++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.Ra_DA | ALU_DL | ES(X)	 2.Ra_DL | FO | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	DA(i) | DL(ALU) | ES(aluOP) | C,
									DA(ALU) | FO | DL(i) | RT, 0, 0, 0, 0, 0 };
				ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			instruction++;
		}
	}

	//CMP Rx, Ry (12)
	for (char i = Ra; i <= Rd; i++) {
		for (char j = Ra; j <= Rd; j++) {
			for (char tstep = 0; tstep <= 7; tstep++) {
				// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.Ra_DA | Rb_XA | ALU_DL | ES(X) | SOS | (CN) | FO | RT
				uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	DA(i) | XA(j) | DL(ALU) | ES(1) | SOS | CN, FO | RT, 0, 0, 0, 0, 0 };
				if (i != j) ucode[flags][(instruction << 3) + tstep] = inst[tstep];
			}
			if (i != j) instruction++;
		}
	}

	//CPY [Si], [Di]
	for (char tstep = 0; tstep <= 7; tstep++) {
		// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.DI_AA | ROM_DA | XH_DL	2.SI_AA | RAM_DL | XH_DA | RT
		uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	AA(Di) | DA(ROM) | DL(XH) | IS(Di),	 AA(Si) | DL(RAM) | DA(XH) | IS(Si) | RT, 0, 0, 0, 0, 0 };
		ucode[flags][(instruction << 3) + tstep] = inst[tstep];
	} 
	instruction++;

	//LDD Rx, [Di]
	for (char i = Rc; i <= Rd; i++) {
		for (char tstep = 0; tstep <= 7; tstep++) {
			// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.DI_AA | ROM_DA | Ra_DL | DI_INC | RT
			uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	AA(Di) | DA(ROM) | DL(i) | IS(Di) | RT,	 0, 0, 0, 0, 0, 0 };
			ucode[flags][(instruction << 3) + tstep] = inst[tstep];
		}
		instruction++;
	}

	//LDD Rs, [Di]
	for (char tstep = 0; tstep <= 7; tstep++) {
		// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.DI_AA | ROM_DA | VRAM_DL | DI_INC | RT
		uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	AA(Di) | DA(ROM) | DL(VRAM) | IS(Di) | RT,	 0, 0, 0, 0, 0, 0 };
		ucode[flags][(instruction << 3) + tstep] = inst[tstep];
	}
	instruction++;

	//IN Rd
	for (char tstep = 0; tstep <= 7; tstep++) {
		// 0.PC_AA | RAM_DA | IR_DL | PC_inc
		uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	DL(Rd) | DA(XH) | RT, 0, 0, 0, 0, 0, 0 };
		ucode[flags][(instruction << 3) + tstep] = inst[tstep];
	}
	instruction++;

	//NOP
	for (char tstep = 0; tstep <= 7; tstep++) {
		// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1. RT
		uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	RT, 0, 0, 0, 0, 0, 0 };
		ucode[flags][(instruction << 3) + tstep] = inst[tstep];
	}
	instruction++;

}

void writeAssembler() {
	const char* DR[16];
	DR[0]="idle";	DR[1]="Ra";	DR[2]="Rb";		DR[3]="Rc";		DR[4]="Rd";		DR[5]="RAM";	DR[6]="STT";	DR[7]="CTL";
	DR[8]="XL";		DR[9]="XH";	DR[10]="INS";	DR[11]="VRAM";	DR[12]="AVR";	DR[13]="ALU";	DR[14]="IN";	DR[15]="SND"; 
	const char* XR[6];
	XR[0]="idle";	XR[1]="Ra";		XR[2]="Rb";		XR[3]="Rc";		XR[4]="Rd";		XR[5]="XL";
	const char* AR[7];
	AR[0] = "idle";		AR[1] = "PC";		AR[2] = "SP";		AR[3] = "Si";		AR[4] = "Di";		AR[5] = "RA";	 AR[6] = "XF";

	FILE* assembler = fopen("cpudef.asm", "wb");
	fprintf(assembler, "#cpudef\n{\n\t#bits 8\n");

	int instruction = 0;
	//MOV Rx, Ry (12)
	for (char i = Ra; i <= Rd; i++) {
		for (char j = Ra; j <= Rd; j++) {
			if (i != j) {
				fprintf(assembler, "\tMOV %s, %s\t\t-> 0x%.2X\n", DR[i], DR[j], instruction);
				instruction++;
			}
		}
	}
	//MOV RA, RB (12)
	for (char i = PC; i <= Di; i++) {
		for (char j = PC; j <= Di; j++) {
			if (i != j) {
				fprintf(assembler, "\tMOV %s, %s\t\t-> 0x%.2X\n", AR[i], AR[j], instruction);
				instruction++;
			}
		}
	}
	//MOV RA, RxRy (8)
	for (char i = PC; i <= Di; i++) {
		for (char j = Ra; j <= Rc; j += 2) {
			fprintf(assembler, "\tMOV %s, %s%s\t\t-> 0x%.2X\n", AR[i], DR[j], DR[j+1], instruction);
			instruction++;
		}
	}
	//MOV RxRy, RA (8)
	for (char i = Ra; i <= Rc; i += 2) {
		for (char j = PC; j <= Di; j++) {
			fprintf(assembler, "\tMOV %s%s, %s\t\t-> 0x%.2X\n", DR[i], DR[i + 1], AR[j], instruction);
			instruction++;
		}
	}
	//MOV Rx, #imm (4)
	for (char i = Ra; i <= Rd; i++) {
		fprintf(assembler, "\tMOV %s, #{imm}\t\t-> 0x%.2X @ imm[7:0]\n", DR[i], instruction);
		instruction++;
	}
	//MOV RA, #imm (4)
	for (char i = PC; i <= Di; i++) {
		fprintf(assembler, "\tMOV %s, #{imm}\t\t-> 0x%.2X @ imm[15:0]\n", AR[i], instruction);
		instruction++;
	}
	//MOV Rs, Rx (24)
	for (char j = 0; j <= 5; j++) {
		char index[6] = { STAT, CTL, VRAM, AVRAM, IN, SND };
		for (char i = Ra; i <= Rd; i++) {
			fprintf(assembler, "\tMOV %s, %s\t\t-> 0x%.2X\n", DR[index[j]], DR[i], instruction);
			instruction++;
		}
	}
	//MOV Rx, Rs (9)
	for (char i = Ra; i <= Rc; i++) {
		char index[3] = { STAT, CTL, IN };
		for (char j = 0; j <= 2; j++) {
			fprintf(assembler, "\tMOV %s, %s\t\t-> 0x%.2X\n", DR[i], DR[index[j]], instruction);
			instruction++;
		}
	}
	//LOD Rx, [#imm] (4)
	for (char i = Ra; i <= Rd; i++) {
		fprintf(assembler, "\tLOD %s, [#{imm}]\t-> 0x%.2X @ imm[15:0]\n", DR[i], instruction);
		instruction++;
	}
	//LOD Rx, [RA] (8)
	for (char i = Ra; i <= Rd; i++) {
		for (char j = Si; j <= Di; j++) {
			fprintf(assembler, "\tLOD %s, [%s]\t\t-> 0x%.2X\n", DR[i], AR[j], instruction);
			instruction++;
		}
	}
	//STO [#imm], Rx (4)
	for (char i = Ra; i <= Rd; i++) {
		fprintf(assembler, "\tSTO [#{imm}], %s\t-> 0x%.2X @ imm[15:0]\n", DR[i], instruction);
		instruction++;
	}
	//STO [RA], Rx (8)
	for (char j = Si; j <= Di; j++) {
		for (char i = Ra; i <= Rd; i++) {
			fprintf(assembler, "\tSTO [%s], %s\t\t-> 0x%.2X\n", AR[j], DR[i], instruction);
			instruction++;
		}
	}
	//LDX RA, [#imm] (4)
	for (char i = PC; i <= Di; i++) {
		fprintf(assembler, "\tLDX %s, [#{imm}]\t-> 0x%.2X @ imm[15:0]\n", AR[i], instruction);
		instruction++;
	}
	//LDX RA, [RB] (2)
	for (char i = Si; i <= Di; i++) {
		for (char j = Si; j <= Di; j++) {
			if (i != j) {
				fprintf(assembler, "\tLDX %s, [%s]\t\t-> 0x%.2X\n", AR[i], AR[j], instruction);
				instruction++;
			}
		}
	}
	//STX [#imm], RA (4)
	for (char i = PC; i <= Di; i++) {
		fprintf(assembler, "\tSTX [#{imm}], %s\t-> 0x%.2X @ imm[15:0]\n", AR[i], instruction);
		instruction++;
	}

	//STX RA, [RB] (2)
	for (char i = Si; i <= Di; i++) {
		for (char j = Si; j <= Di; j++) {
			if (i != j) {
				fprintf(assembler, "\tSTX [%s], %s\t\t-> 0x%.2X\n", AR[i], AR[j], instruction);
				instruction++;
			}
		}
	}
	//PUSH Rx
	for (char i = Ra; i <= Rd; i++) {
		fprintf(assembler, "\tPUSH %s\t\t\t-> 0x%.2X\n", DR[i], instruction);
		instruction++;
	}
	//POP Rx
	for (char i = Ra; i <= Rd; i++) {
		fprintf(assembler, "\tPOP %s\t\t\t-> 0x%.2X\n", DR[i], instruction);
		instruction++;
	}
	//PUSH RA
	for (char i = PC; i <= Di; i++) {
		fprintf(assembler, "\tPUSH %s\t\t\t-> 0x%.2X\n", AR[i], instruction);
		instruction++;
	}
	//POP RA
	for (char i = PC; i <= Di; i++) {
		fprintf(assembler, "\tPOP %s\t\t\t-> 0x%.2X\n", AR[i], instruction);
		instruction++;
	}
	//CALL [#imm]
	fprintf(assembler, "\tCALL [#{imm}]\t\t-> 0x%.2X @ imm[15:0]\n", instruction);
	instruction++;
	//Conditional jumps
	const char* CJ[8];
	CJ[0] = "JC";	CJ[1] = "JNC";	CJ[2] = "JZ";		CJ[3] = "JNZ";		CJ[4] = "JN";		CJ[5] = "JP";	CJ[6] = "JV";	CJ[7] = "JNV";
	//Conditional jumps: JC, JNC, JZ, JNZ, JN, JP, JV, JNV
	for (char condJumps = 0; condJumps <= 7; condJumps++) {
		fprintf(assembler, "\t%s [#{imm}]\t\t-> 0x%.2X @ imm[15:0]\n", CJ[condJumps], instruction);
		instruction++;
	}

	const char* EO[14];
	EO[0] = "ADD";	EO[1] = "SUB";	EO[2] = "AND";		EO[3] = "OR";		EO[4] = "XOR";		EO[5] = "NOT";	EO[6] = "LSR";	EO[7] = "LSL";
	EO[8] = "INC";	EO[9] = "DEC";	EO[10] = "ADC";		EO[11] = "SBB";		EO[12] = "CSR";		EO[13] = "CSL";
	//ADD/SUB/AND/OR/XOR Rx, Ry (60)
	for (char aluOP = 0; aluOP <= 4; aluOP++) {
		for (char i = Ra; i <= Rd; i++) {
			for (char j = Ra; j <= Rd; j++) {
				if (i != j) {
					fprintf(assembler, "\t%s %s, %s\t\t-> 0x%.2X\n", EO[aluOP], DR[i], DR[j], instruction);
					instruction++;
				}
			}
		}
	}
	//NOT/LSR/LSL Rx (12)
	for (char aluOP = 5; aluOP <= 7; aluOP++) {
		for (char i = Ra; i <= Rd; i++) {
			fprintf(assembler, "\t%s %s\t\t\t-> 0x%.2X\n", EO[aluOP], DR[i], instruction);
			instruction++;
		}
	}
	//INC/DEC Rx (8)
	for (char aluOP = 0; aluOP <= 1; aluOP++) {
		for (char i = Ra; i <= Rd; i++) {
			fprintf(assembler, "\t%s %s\t\t\t-> 0x%.2X\n", EO[aluOP + 8], DR[i], instruction);
			instruction++;
		}
	}
	//INC/DEC RA (4)
	for (char OP = 0; OP <= 1; OP++) {
		for (char i = Si; i <= Di; i++) {
			fprintf(assembler, "\t%s %s\t\t\t-> 0x%.2X\n", EO[OP + 8], AR[i], instruction);
			instruction++;
		}
	}
	//ADC/SBB Rx, Ry (4)
	for (char aluOP = 0; aluOP <= 1; aluOP++) {
		for (char i = Ra; i <= Rc; i += 2) {
			for (char j = Ra; j <= Rc; j += 2) {
				if (i != j) {
					fprintf(assembler, "\t%s %s, %s\t\t-> 0x%.2X\n", EO[aluOP + 8 + 2], DR[i], DR[j], instruction);
					instruction++;
				}
			}
		}
	}
	//CSR/CSL Rx (8)
	for (char aluOP = 6; aluOP <= 7; aluOP++) {
		for (char i = Ra; i <= Rd; i++) {
			fprintf(assembler, "\t%s %s\t\t\t-> 0x%.2X\n", EO[aluOP + 8 - 2], DR[i], instruction);
			instruction++;
		}
	}
	//CMP Rx, Ry (12)
	for (char i = Ra; i <= Rd; i++) {
		for (char j = Ra; j <= Rd; j++) {
			if (i != j) {
				fprintf(assembler, "\tCMP %s, %s\t\t-> 0x%.2X\n", DR[i], DR[j], instruction);
				instruction++;
			}
		}
	}
	//CPY [Si], [Di]
	fprintf(assembler, "\tCPY [%s], [%s]\t\t-> 0x%.2X\n", AR[Si], AR[Di], instruction);
	instruction++;
	//LDD Rx, [Di]
	for (char i = Rc; i <= Rd; i++) {
		fprintf(assembler, "\tLDD %s, [%s]\t\t-> 0x%.2X\n", DR[i], AR[Di], instruction);
		instruction++;
	}
	//LDD Rs, [Di]
	fprintf(assembler, "\tLDD %s, [%s]\t\t-> 0x%.2X\n", DR[VRAM], AR[Di], instruction);
	instruction++;
	//IN Rd
	fprintf(assembler, "\tIN Rd \t\t\t-> 0x%.2X\n", instruction);
	instruction++;

	//NOP
	fprintf(assembler, "\tNOP \t\t\t-> 0x%.2X\n", instruction);
	instruction++;


	fprintf(assembler, "}");
	fclose(assembler);
}

void printSet(char flags) {
	int k = 0;
	printf("Printing instructions with flags 0x" "%.2x" "\n", flags);
	printf("%u" ". \t", 0);
	for (int i = 0; i <= (256 * 8)-1 ; i++) {
		if (k == 8) {
			k = 1;
			printf("\n");
			printf("%u" ". \t", i/8);
		}
		else k++;
		printf("0x" "%.10" PRIx64 "\t", ucode[flags][i]);
	}
}

void printWords(int address, int n) {
	for (int i = address; i < address+n; i++) {
		printf("\n0x%.5X" "\t", i);
		printf("0x" "%.10" PRIx64 "\t", ctlWord[i]);
	}
	printf("\n");
}

void main() {

	//Program and copy instruction set to ROM buffer
	for (char set = 0; set < 32; set++) {
		programSet(set);
		for (unsigned int ins = 0; ins <= (256 * 8) - 1; ins++) {
			ctlWord[(set << 11) + ins] = ucode[set][ins];
		}
	}

	//Program interrupt handler
	for (int address = 32 * 256 * 8; address < 131072; address+=8) {
		for (char tstep = 0; tstep <= 7; tstep++) {
			// 0.PC_AA | RAM_DA | IR_DL | PC_inc		1.IHAE_DA | XH_LD | PC_DEC 	2.IHAE_DA | XL_LD | PC_AA | RA_LD	3.X_AA | PC_AL
			// 4.RA_AA | X_AL | SP_DEC		5. SP_AA | RAM_DL | DA_XL | SP_DEC		6.SP_AA | RAM_DL | XH_DA | RT
			uint64_t inst[8] = { AA(PC) | DA(RAM) | DL(INS) | IS(PC),	 DA(IHAE) | DL(XH) | DS(PC),	AA(PC) | AL(RA) | DA(IHAE) | DL(XLD),
								AA(Xfer) | AL(PC),		AL(Xfer) | AA(RA) | DS(SP),		AA(SP) | DA(XLD) | DL(RAM) | DS(SP),
								AA(SP) | DA(XH) | DL(RAM) , DL(XH) | DA(IN) | RT | RI };
			ctlWord[address + tstep] = inst[tstep];
		}
	}

	//Flip active low signals
	for (int address = 0; address < 131072; address ++) {
		ctlWord[address] ^= RI | RT | FO;
	}
	
	//Write assembler
	writeAssembler();

	//Debugging
	printWords(65528, 24);
	printSet(0b10000);



	//Write ROMs
	for (char byte = 0; byte <= 4; byte++) {

		//ROM data buffer
		uint8_t data[131072];
		for (int i = 0; i < 131072; i++) {
			data[i] = (ctlWord[i] >> (byte * 8)) & 0xFF;
		}

		//Create ROM files
		char romName[9] = "ROMX.rom";
		char romNameTxt[9] = "ROMX.txt";
		romName[3] = byte + '0';
		romNameTxt[3] = byte + '0';

		FILE* ROMdata = fopen(romName, "wb");
		FILE* ROMdata_TEXT = fopen(romNameTxt, "wb");

		//Write binaries
		fwrite( data, sizeof(data), 1, ROMdata);
		fclose(ROMdata);

		//Write text
		fprintf(ROMdata_TEXT, "{ ");
		for (int address = 0; address < sizeof(data) - 1;  address++) {
			fprintf(ROMdata_TEXT, "0x%.2X, ", data[address]);
		}
		
		fprintf(ROMdata_TEXT, "0x%X ", data[sizeof(data) - 1]);
		fprintf(ROMdata_TEXT, "};");
		fclose(ROMdata_TEXT);

	}

}