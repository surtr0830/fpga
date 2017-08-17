`timescale 1ns / 1ps
`include "def.v"
module AddrDecoder(reqType, ofs, base, count, lbType, addr, invalid);
	input [5:0] reqType;
	input [15:0] ofs;
	input [15:0] base;
	input [15:0] count;
	input [5:0] lbType;
	output [15:0] addr;
	output invalid;	//1のときアドレス不正
	//
	assign addr = base + ofs;
	assign invalid = !(
		isValidLabelType(reqType) && 
		reqType == lbType &&
		ofs < count
	);
	function isValidLabelType(input [5:0] type);
		case(reqType)
			//`LBTYPE_UNDEFINED:;
			`LBTYPE_VPTR:	isValidLabelType = 1'd1;
			`LBTYPE_SINT8:	isValidLabelType = 1'd1;
			`LBTYPE_UINT8:	isValidLabelType = 1'd1;
			`LBTYPE_SINT16:	isValidLabelType = 1'd1;
			`LBTYPE_UINT16:	isValidLabelType = 1'd1;
			`LBTYPE_SINT32:	isValidLabelType = 1'd1;
			`LBTYPE_UINT32:	isValidLabelType = 1'd1;
			`LBTYPE_SINT4:	isValidLabelType = 1'd1;
			`LBTYPE_UINT4:	isValidLabelType = 1'd1;
			`LBTYPE_SINT2:	isValidLabelType = 1'd1;
			`LBTYPE_UINT2:	isValidLabelType = 1'd1;
			`LBTYPE_SINT1:	isValidLabelType = 1'd1;
			`LBTYPE_UINT1:	isValidLabelType = 1'd1;
			`LBTYPE_CODE:	isValidLabelType = 1'd1;
			default:	isValidLabelType = 1'd0;
		endcase
	endfunction
endmodule

module testbench_addrdec();
	reg clk;
	//
	reg [5:0] reqType;
	reg [15:0] ofs;
	reg [15:0] base;
	reg [15:0] count;
	reg [5:0] lbType;
	wire [15:0] addr;
	wire invalid;

	AddrDecoder addrdec(reqType, ofs, base, count, lbType, addr, invalid);

	initial begin
		$dumpfile("addrdec.vcd");
		$dumpvars(0, testbench_addrdec);
		// all invalid
		reqType = `LBTYPE_UNDEFINED;
		ofs = 4;
		base = 16'hffff;
		count = 0;
		lbType = `LBTYPE_UNDEFINED;
		//
		#1;
		$display ("addr: %X", addr);
		$display ("invalid: %X", invalid);
		if(invalid == 1) $display("PASS");
		else begin
			$display("FAILED");
			$finish;
		end
		// valid
		reqType = `LBTYPE_CODE;
		ofs 	= 4;
		base	= 16'hff00;
		count	= 16'h00ff;
		lbType	= `LBTYPE_CODE;
		//
		#1;
		$display ("addr: %X", addr);
		$display ("invalid: %X", invalid);
		if(invalid == 0 && addr == 16'hff04) $display("PASS");
		else begin
			$display("FAILED");
			$finish;
		end
		// type not matched
		reqType = `LBTYPE_VPTR;
		ofs 	= 4;
		base	= 16'hff00;
		count	= 16'h00ff;
		lbType	= `LBTYPE_CODE;
		//
		#1;
		$display ("addr: %X", addr);
		$display ("invalid: %X", invalid);
		if(invalid == 1) $display("PASS");
		else begin
			$display("FAILED");
			$finish;
		end
		// out of limit
		reqType = `LBTYPE_CODE;
		ofs 	= 4;
		base	= 16'hff00;
		count	= 16'h004;
		lbType	= `LBTYPE_CODE;
		//
		#1;
		$display ("addr: %X", addr);
		$display ("invalid: %X", invalid);
		if(invalid == 1) $display("PASS");
		else begin
			$display("FAILED");
			$finish;
		end
		// last element in bound
		reqType = `LBTYPE_CODE;
		ofs 	= 3;
		base	= 16'hff00;
		count	= 16'h004;
		lbType	= `LBTYPE_CODE;
		//
		#1;
		$display ("addr: %X", addr);
		$display ("invalid: %X", invalid);
		if(invalid == 0 && addr == 16'hff03) $display("PASS");
		else begin
			$display("FAILED");
			$finish;
		end
		//
		$display ("Simulation end");
		$finish;
	end
	always begin
		// クロックを生成する。
		// #1; は、1クロック待機する。
		clk <= 0; #1;
		clk <= 1; #1;
	end

	always @ (posedge clk)
	begin

	end

endmodule

