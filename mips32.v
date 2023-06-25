module mips32(clk1, clk2);

			input wire clk1, clk2;
			
			// IF_ID_ registers
			reg [31:0]	PC, IF_ID_IR, IF_ID_NPC;
			
			// ID_EX_ registers
			reg [31:0]	ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_RD, ID_EX_B, ID_EX_Imm, ID_EX_ImmJ, ID_EX_ImmU;
			reg [4:0]	ID_EX_SA;

			// EX_MEM registers
			reg [31:0]	EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
			reg			EX_MEM_cond1, EX_MEM_cond2, EX_MEM_cond3;

			// MEM_WB_ registers
			reg [31:0]	MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
			
			// Type variables
			reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;
			
			reg [31:0] Reg [31:0];		// Register Bank 32x32
			reg [31:0] Mem [1023:0];	// Memory Bank 1024x32
			reg [31:0] Ra;
			
			// Assembly Commands
			parameter	ADD = 6'b000_000,		SUB = 6'b000_001,		AND = 6'b000_010,		OR = 6'b000_011,
							SLT = 6'b000_100,		MUL = 6'b000_101,		MOVE = 6'b000_110,	NEG = 6'b000_111, 
							LD = 6'b001_000,		STR = 6'b001_001,		ADDI = 6'b001_010,	SUBI = 6'b001_011, 
							SLTI = 6'b001_100,	BNE = 6'b001101,		BEQ = 6'b001110,		ADDIU = 6'b001_111,
							SUBIU = 6'b010_000,	ANDI = 6'b010_001,	NOR = 6'b010_010,		NOT = 6'b010_011,
							ORI = 6'b010_100,		WSBH = 6'b010_101,	XOR = 6'b010_110,		XORI = 6'b010_111,
							MOVN = 6'b011_000,	MOVZ = 6'b011_001,	JMP = 6'b011_010,		SLTIU = 6'b011_011,
							MULI = 6'b011_100,	MULIU = 6'b011_101,	BGE = 6'b011_110,		BGT = 6'b011_111,
							BLE = 6'b100_000,		BLT = 6'b100_001,		JAL = 6'b100_010,		LDU = 6'b100_011,
							STU = 6'b100_100,		SLL = 6'b100_101,		SLLV = 6'b100_110,	SRL = 6'b100_111,
							SRLV = 6'b101_000,	SRA = 6'b101_001,		SRAV = 6'b101_010,
							HLT = 6'b111_111;
			
			// Command types (3-bit) [2:0]
			parameter	RR_ALU = 3'b000, RM_ALU = 3'b001, RU_ALU = 3'b010, LOAD = 3'b011, STORE = 3'b100,
							BRANCH = 3'b101, JUMP = 3'b110, HALT = 3'b111;
							
			reg HALTED;				// set after HLT instruction is completed (in WB stage)
			reg TAKEN_BRANCH;		// required to disable instructions after branch
			
			
			
			/*______________________ Different Stages of the Pipeline __________________*/
						
			// The Instruction Fetch (IF) Stage
			
			always @ (posedge clk1)
				if(HALTED == 0) begin // we fetch only if halt is not set
					if( 
							// 1 - EQ (==) ; 0 - NEQ (!=)
							((EX_MEM_IR[31:26] == BEQ) && (EX_MEM_cond1 == 1)) ||
							((EX_MEM_IR[31:26] == BNE) && (EX_MEM_cond1 == 0)) ||
							// 1 - GE (>=) ; 0 - LT (<)
							((EX_MEM_IR[31:26] == BGE) && (EX_MEM_cond2 == 1)) ||
							((EX_MEM_IR[31:26] == BLT) && (EX_MEM_cond2 == 0)) ||
						 
							// 1 - LE (<=) ; 0 - GT (>)
							((EX_MEM_IR[31:26] == BLE) && (EX_MEM_cond3 == 1)) ||
							((EX_MEM_IR[31:26] == BGT) && (EX_MEM_cond3 == 0))
						 ) // check whether a branch is taken

							
						begin
							TAKEN_BRANCH	<= #2 1'b1;
							IF_ID_IR			<= #2 Mem[EX_MEM_ALUOut];
							IF_ID_NPC		<= #2 EX_MEM_ALUOut + 1;
							PC					<= #2 EX_MEM_ALUOut + 1;
						end
					else
						begin
							IF_ID_IR			<= #2 Mem[PC];
							IF_ID_NPC		<= #2 PC + 1;
							PC					<= #2 PC + 1;
							 TAKEN_BRANCH	<= #2 0; // reset the taken branch back to zero

						end
				end
			
			// The Instruction Decode (ID) Stage
			
			/* We do 3 things:
			1 we decode the instruction
			2 we are pre-fetching two source registers
			3 we are sign-extending the offset */
			
			always @ (posedge clk2)
				if (HALTED == 0) begin
				
					//Rs - register
					if( IF_ID_IR[25:21] == 5'b00000)	ID_EX_A <= 0; // if R0 then assign 0 to ID_EX_A
					else ID_EX_A <= #2 Reg[IF_ID_IR[25:21]];
					
					//Rt - register
					if( IF_ID_IR[20:16] == 5'b00000)	ID_EX_B <= 0; // if R0 then assign 0 to ID_EX_B
					else ID_EX_B <= #2 Reg[IF_ID_IR[20:16]];

					ID_EX_NPC	<= #2 IF_ID_NPC;
					ID_EX_IR		<= #2 IF_ID_IR;

					ID_EX_Imm	<= #2 {{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};
					ID_EX_ImmJ	<= #2 {{6{IF_ID_IR[25]}},{IF_ID_IR[25:0]}};
					ID_EX_ImmU	<= #2 {16'b0,IF_ID_IR[15:0]};
					ID_EX_SA		<= #2 Reg[IF_ID_IR[10:6]];
					ID_EX_RD		<= #2 Reg[IF_ID_IR[15:11]];
					
					case(IF_ID_IR[31:26])
							ADD,SUB,AND,OR,SLT,MUL,XOR,NOR:			ID_EX_type <= #2 RR_ALU; // 8 instr
							ADDI, SUBI, SLTI, MULI, NOT:				ID_EX_type <= #2 RM_ALU; // 5 instr
							ANDI, ORI, XORI, MOVN, MOVZ:				ID_EX_type <= #2 RR_ALU; // 5 instr
							ADDIU, SUBIU, MULIU, SLTIU:				ID_EX_type <= #2 RU_ALU; // 4 instr
							SLL, SLLV, SRL, SRLV, SRA, SRAV:			ID_EX_type <= #2 RR_ALU; // 6 instr
							MOVE, NEG, WSBH:								ID_EX_type <= #2 RR_ALU; // 4 instr
							LD, LDU:											ID_EX_type <= #2 LOAD;	 // 2 instr
							STR, STU:										ID_EX_type <= #2 STORE;  // 2 instr
							BNE, BEQ, BGE, BGT, BLE, BLT:				ID_EX_type <= #2 BRANCH; // 6 instr
							JMP, JAL:										ID_EX_type <= #2 JUMP;   // 2 instr
							HLT:												ID_EX_type <= #2 HALT;	 // 1 instr
							default:											ID_EX_type <= #2 HALT;
					endcase
				end
			
			// The Execute (EX) stage
			always @(posedge clk1)
				if (HALTED == 0) begin
					EX_MEM_type		<= #2 ID_EX_type;
					EX_MEM_IR		<= #2 ID_EX_IR;
					// TAKEN_BRANCH	<= #2 0; // reset the taken branch back to zero

					case (ID_EX_type)
							RR_ALU: 
							begin
									case(ID_EX_IR[31:26]) 
											ADD:			EX_MEM_ALUOut <=  #2 ID_EX_A + ID_EX_B;
											SUB:			EX_MEM_ALUOut <=  #2 ID_EX_A - ID_EX_B;
											AND:			EX_MEM_ALUOut <=  #2 ID_EX_A & ID_EX_B;
											OR:			EX_MEM_ALUOut <=  #2 ID_EX_A | ID_EX_B;
											SLT:			EX_MEM_ALUOut <=  #2 ID_EX_A < ID_EX_B;
											MUL:			EX_MEM_ALUOut <=  #2 ID_EX_A * ID_EX_B;
											XOR:			EX_MEM_ALUOut <=  #2 ID_EX_A ^ ID_EX_B;
											NOR:			EX_MEM_ALUOut <=  #2 ~(ID_EX_A | ID_EX_B);
											SLL:			EX_MEM_ALUOut <=  #2 ID_EX_A << ID_EX_SA;
											SLLV:			EX_MEM_ALUOut <=  #2 ID_EX_A << ID_EX_B;
											SRL:			EX_MEM_ALUOut <=  #2 ID_EX_A >> ID_EX_SA;
											SRLV:			EX_MEM_ALUOut <=  #2 ID_EX_A >> ID_EX_B;
											SRA:			EX_MEM_ALUOut <=	#2	ID_EX_A >>> ID_EX_SA;
											SRAV:			EX_MEM_ALUOut <=	#2	ID_EX_A >>> ID_EX_B;
											MOVN:			EX_MEM_ALUOut <=	#2 (ID_EX_B != 0) ? ID_EX_A : ID_EX_RD;
											MOVZ:			EX_MEM_ALUOut <=	#2	(ID_EX_B == 0) ? ID_EX_A : ID_EX_RD;
											MOVE:			EX_MEM_ALUOut <=  #2 ID_EX_A;
											NEG:			EX_MEM_ALUOut <=  #2 (~(ID_EX_A) + 1);
											WSBH:			EX_MEM_ALUOut <=  #2 {{ID_EX_A[23:16],ID_EX_A[31:24]},{ID_EX_A[7:0],ID_EX_A[15:8]}};

											default:		EX_MEM_ALUOut <=  #2 32'hxxxx_xxxx;
									endcase
							end
							RM_ALU: 
							begin
									case(ID_EX_IR[31:26]) 
											ADDI:			EX_MEM_ALUOut <=  #2 ID_EX_A + ID_EX_Imm;
											SUBI:			EX_MEM_ALUOut <=  #2 ID_EX_A - ID_EX_Imm;
											SLTI:			EX_MEM_ALUOut <=  #2 ID_EX_A < ID_EX_Imm;
											MULI:			EX_MEM_ALUOut <=  #2 ID_EX_A * ID_EX_Imm;
											ANDI:			EX_MEM_ALUOut <=  #2 ID_EX_A & ID_EX_Imm;
											ORI:			EX_MEM_ALUOut <=  #2 ID_EX_A | ID_EX_Imm;
											XORI:			EX_MEM_ALUOut <=  #2 ID_EX_A ^ ID_EX_Imm;
											NOT:			EX_MEM_ALUOut <=  #2 ~ID_EX_A;
											default:		EX_MEM_ALUOut <=  #2 32'hxxxx_xxxx;
									endcase
							end
							RU_ALU:
							begin
									case(ID_EX_IR[31:26]) 
											ADDIU:		EX_MEM_ALUOut <=  #2 ID_EX_A + ID_EX_ImmU;
											SUBIU:		EX_MEM_ALUOut <=  #2 ID_EX_A - ID_EX_ImmU;
											MULIU:		EX_MEM_ALUOut <=  #2 ID_EX_A * ID_EX_ImmU;
											SLTIU:		EX_MEM_ALUOut <=  #2 ID_EX_A < ID_EX_ImmU;
									endcase
							end
							LOAD, STORE: begin
									case(ID_EX_IR[31:26]) 
									LD, STR: begin
															EX_MEM_ALUOut	<= #2 ID_EX_A + ID_EX_Imm;
															EX_MEM_B			<= #2 ID_EX_B;
															end
									LDU, STU: begin		
															EX_MEM_ALUOut	<= #2 ID_EX_A + ID_EX_ImmU;
															EX_MEM_B			<= #2 ID_EX_B;
															end
									endcase

							end
							BRANCH: 
							begin
															EX_MEM_ALUOut	<= #2 ID_EX_NPC + ID_EX_Imm;
															EX_MEM_cond1	<= #2 (ID_EX_A == ID_EX_B); // 1 - EQ (==) ; 0 - NEQ (!=)
															EX_MEM_cond2	<= #2 (ID_EX_A >= ID_EX_B); // 1 - GE (>=) ; 0 - LT (<)
															EX_MEM_cond3	<= #2 (ID_EX_A <= ID_EX_B); // 1 - LE (<=) ; 0 - GT (>)
							end
							JUMP: begin
									case(ID_EX_IR[31:26]) 
									JMP:						EX_MEM_ALUOut	<= #2 ID_EX_NPC + ID_EX_ImmJ;
									JAL: begin
																Ra					<= #2 ID_EX_NPC + 1;
																EX_MEM_ALUOut	<= #2 ID_EX_NPC + ID_EX_ImmJ;
																
									end
									endcase
							end
					endcase
				end
			
			// The Memory (MEM) stage
			always @(posedge clk2)
				if (HALTED == 0) 
				begin
					MEM_WB_type <= #2 EX_MEM_type;
					MEM_WB_IR	<= #2 EX_MEM_IR;

						case(EX_MEM_type)
								RR_ALU, RM_ALU:		MEM_WB_ALUOut	<= #2 EX_MEM_ALUOut;
								LOAD:						MEM_WB_LMD		<= #2 Mem[EX_MEM_ALUOut];
								STORE:			if(TAKEN_BRANCH == 0) Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B;
						endcase
				end
				
			// The Write Back (WB) stage
			always @(posedge clk1)
			begin
				if(TAKEN_BRANCH == 0) 
					case(MEM_WB_type)
							RR_ALU:					Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut;	// Rd
							
							RM_ALU,RU_ALU:			Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut;	// Rt
							
							LOAD:						Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;		// Rt
							
							HALT:						HALTED <= #2 1'b1;
					endcase
			end
			
endmodule

