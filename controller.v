`timescale 1ns / 1ps
`include "def.v"
module Controller(clk, reset, 
	memdata, memaddr, ireg_d0_lsb, mmu_invalid,
	instr0, instr1, current_state, 
	cr, pc);
	//
	input clk, reset;							//
	input [31:0] memdata;					//
	input ireg_d0_lsb;						//
	input mmu_invalid;						//1ならMMUからの不正通知
	
	output reg [15:0] memaddr;				//参照したいアドレス
	output reg [31:0] instr0 = 0;			//
	output reg [31:0] instr1 = 0;			//
	output reg [3:0] current_state = 0;	//
	output reg [7:0] cr = 0;				//コントロールレジスタ
	output reg [15:0] pc = 0;				//プログラムカウンタ
	//
	wire	[15:0] pc_next;
	wire  [7:0] cr_next;
	wire	[3:0]	next_state;
	assign pc_next = (
		current_state == `STATE_FETCH0 || 
		current_state == `STATE_FETCH1 ? pc + 1'b1 : pc);
	//
	wire [7:0] instr0_op;
	wire [7:0] next_instr0_op;
	assign instr0_op       	= instr0[31:24];
	assign next_instr0_op   = memdata[31:24];
	//
	reg cr_next_hlt;
	reg cr_next_skip;
	assign cr_next = {6'b0, cr_next_skip, cr_next_hlt};
	always begin
		// HLT bit
		if((current_state == `STATE_EXEC && instr0_op == `OP_HLT) /*|| mmu_invalid == 1*/) begin
			cr_next_hlt = 1;
		end
		else cr_next_hlt = cr[`BIT_CR_HLT];
		// SKIP bit
		case (current_state)
			`STATE_FETCH0: begin
				case(next_instr0_op)
					`OP_LIMM32, `OP_LBSET: begin
						cr_next_skip = cr[`BIT_CR_SKIP];
					end
					default: cr_next_skip = 0;
				endcase
			end
			`STATE_FETCH1: begin
				cr_next_skip = 0;
			end
			`STATE_EXEC: begin
				if(instr0_op == `OP_CND && ireg_d0_lsb == 0) begin
					cr_next_skip = 1;
				end
				else cr_next_skip = 0;
			end
			default: cr_next_skip = cr[`BIT_CR_SKIP];
		endcase
		#1;
	end
	//
	always begin
		case (current_state)
			`STATE_FETCH0:	memaddr = pc;
			`STATE_FETCH1:	memaddr = pc;
			default:		memaddr = 0;
		endcase
		#1;
	end

	//ここのフラグ(genCRNextHLT)が1で動作停止
	function genCRNextHLT(input [3:0]cstate, input[7:0] op);
		genCRNextHLT = (cstate == `STATE_EXEC && op == `OP_HLT);
	endfunction
	
	always @(posedge clk) begin
		if(reset == 1) begin
			pc = 0;
			current_state = `STATE_FETCH0;
			cr = 0;
		end
		if(reset == 0 && cr[`BIT_CR_HLT] == 0) begin
			if(current_state == `STATE_FETCH0) begin
				instr0 = memdata;
			end
			if(current_state == `STATE_FETCH1) begin
				instr1 = memdata;
			end
			current_state <= next_state;
			pc <= pc_next;
			cr <= cr_next;
		end
	end
	// state transition
	assign next_state = genNextState(current_state, next_instr0_op);
	function [3:0] genNextState (
		input [3:0] currentState, 
		input [7:0] next_instr0_op);
		case (currentState)
			`STATE_FETCH0: begin
				case(next_instr0_op)
					`OP_LIMM32, `OP_LBSET: begin
						genNextState = `STATE_FETCH1;
					end
					default: begin
						genNextState = 
							(cr[`BIT_CR_SKIP] == 1 ? `STATE_FETCH0 : `STATE_EXEC);
					end
				endcase
			end
			`STATE_FETCH1: begin
				genNextState = 
					(cr[`BIT_CR_SKIP] == 1 ? `STATE_FETCH0 : `STATE_EXEC);
			end
			`STATE_EXEC: begin
				genNextState = `STATE_FETCH0;
			end
			default: genNextState = `STATE_FETCH0;
		endcase
	endfunction
endmodule
