# Custom-MIPS32-CPU
A custom, reduced ISA MIPS32 CPU, updated from the previous.

## General Description

This is my first, fully functional pipelined CPU (32-bit) project in Verilog(behavioral).  Like all modern CPUs, MIPS32 uses a 5-stage pipeline in order to speedup the instruction execution. The pipeline is divided in Instruction Fetch, Instruction Decode, Execute, Memory and Write Back stages. In between these there are the intermediate pipeline stages which do the actual pipelining and parallel elaboration: IF/ID, ID/EX; EX/MEM and MEM/WB.

In the behavioral description, I used an “always” cycle for each of the five main stages IF, ID, EX, MEM and WB, synchronized by a dual phase clock. As far as the intermediate pipeline states are concerned, they are described with registers that have a notation of the sort IF_ID_xxx, ID_EX_xxx, EX_MEM_xxx and so on.

## Instruction Set (Reduced)

In order to simplify things, I avoided using the funct(bits 5...0) in the case of Register (R) Type instructions. Overall, out of 64 instructions that could be realized with the 6 normal instruction bits, I decided to implement 44 and leave 20 free for further elaboration and/or individual customization. The list of of present instructions is:

ADD<br>
SUB <br>
AND<br>
OR<br>
SLT<br>
MUL<br>
MOVE<br>
NEG<br>
LD<br>
STR<br>
ADDI<br>
SUBI<br>
SLTI<br>
BNE<br>
BEQ<br>
ADDIU<br>
SUBIU<br>
ANDI<br>
NOR<br>
NOT<br>
ORI<br>
WSBH<br>
XOR<br>
XORI<br>
MOVN<br>
MOVZ<br>
JMP<br>
SLTIU<br>
MULI<br>
MULIU<br>
BGE<br>
BGT<br>
BLE<br>
BLT<br>
JAL<br>
LDU<br>
STU<br>
SLL<br>
SLLV<br>
SRL<br>
SRLV<br>
SRA<br>
SRAV<br>
HLT<br>

## Notes

I am also including two testbenches, with commands written mixedly (both in binary and hex) to show the capabilities of the CPU. One testbench tests the basic arithmetic funcitons, the other is a factorial calculation which uses loop and branch-not-equal.

### Screenshoot of Branch Loop testbench simulation below:
![image](https://github.com/oriod-malo/Custom-MIPS32-CPU/assets/123891760/544d1d6f-80ce-4f7f-a186-b364798b803f)
