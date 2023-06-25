module mips32_testbench_basic_arithmetics;


	reg clk1, clk2;
	integer k;
	
	mips32 mips (clk1 , clk2);
	
	initial
		begin
			clk1 = 0; clk2 = 0;
			repeat(200)
			begin
				#5 clk1 = 1; #5 clk1 = 0;
				#5 clk2 = 1; #5 clk2 = 0;
			end
	end
	
		
		initial
			begin
				for (k=0; k<31; k++)
					mips.Reg[k] = k;
					
					mips.Mem[0] = 32'b001010_00000_00001_0000000000010100; // ADDI R1, R0, 20
					mips.Mem[1] = 32'b001010_00000_00010_0000000000011110; // ADDI R2, R0, 30
					mips.Mem[2] = 32'h0e94a000; // OR R20, R20, R20 DUMMY INSTRUCTION
					mips.Mem[3] = 32'b000000_00001_00010_00011_00000_000000; // ADD R3, R2, R1 (should be 50)
					mips.Mem[4] = 32'h0e94a000; // OR R20, R20, R20 DUMMY INSTRUCTION
					mips.Mem[5] = 32'b001011_00011_00100_0000000000001111; // SUBI R4, R3, 15 (50-15 should be 35)
					mips.Mem[6] = 32'h0e94a000; // OR R20, R20, R20 DUMMY INSTRUCTION
					mips.Mem[7] = 32'b000001_00100_00001_00101_00000_000000; // SUB R4, R1, R5 (R5 should store 35-20 = 15)
					mips.Mem[8] = 32'h0e94a000; // OR R20, R20, R20 DUMMY INSTRUCTION
					mips.Mem[9] = 32'b011100_00100_00110_0000000000001111; // MULI R6, R4, 15 (R6 should store 35*15 = 525)
					mips.Mem[10] = 32'b000101_00010_00011_00111_00000_000000; // MUL R2, R3, R7 (R7 should store 30*50 = 1500)
					mips.Mem[11] = 32'hfc000000; // HLT
					
					mips.HALTED = 0;
					mips.PC = 0;
					mips.TAKEN_BRANCH = 0;
					
					#2000
					
					for(k=0;k<8;k++)
						$display ("R%1d - %2d", k, mips.Reg[k]);					
		end
		
				initial
					begin
						$dumpfile("mips.vcd");

						$dumpvars(0, mips32_testbench_basic_arithmetics);

						#3000 $finish;
				end

endmodule
