module motorCtrlSimple(
	input CLK_50MHZ,
	input reset,
	input [19:0] divider,
	input moveDir,
	input moveDirInvers,
	input stepClockEna,	
	output dir,
	output reg step,
	output reg signed [31:0] cur_position = 0
);

reg [19:0] clockCounter = 0;

assign dir = moveDirInvers?~moveDir : moveDir;
always @(posedge CLK_50MHZ) begin
	if(reset) begin
		cur_position <= 32'h0;	
	end
	else if(stepClockEna) begin 			
		if(clockCounter == 0) begin
			clockCounter <= divider;
			step <= 1'b1;			
			//deltaPosLoc <= deltaPosLoc - 1;
			//deltaPosCur <= deltaPosCur + 16'h1;
			if(moveDir==1'b1) begin
				cur_position <= cur_position + 32'h1;
			end
			else if(moveDir==1'b0) begin
				cur_position <= cur_position - 32'h1;
			end
	
		end
		else begin
			clockCounter <= clockCounter - 1;
			if(clockCounter == {1'b0, divider[18:1]}) 
				step <= 1'b0;							
		end		
	end
end
endmodule


