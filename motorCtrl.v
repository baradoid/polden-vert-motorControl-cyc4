module motorCtrl(
	input CLK_50MHZ,
	input [23:0] velocityMax_div,
	input [15:0] deltaPos,
	input newPosSignal,
	output reg dir,
	output reg step,
	output reg [31:0] cur_position = 0 ,
	output debug15625mks
);

parameter idleState = 0;
parameter speedUpState = 1;
parameter speedConstState = 2;
parameter speedDownSpeedState = 3;
parameter speedConstState2 = 4;

parameter speedDeviationCount = 8'd244; //244*4,096 ms ~ 1sec

reg [7:0] deltaPosLoc = 100;
reg [1:0] state = idleState;
reg [15:0] timer5msPulsesCnt = 0;
reg [15:0] timer10msPulsesCnt = 0;
reg [7:0] timer15625mksPulsesCnt = 0; //15625 in 50MHz

reg [19:0] clockCounter = 0;
reg [19:0] divider = 0;
//reg [15:0] dividerInc = 0;



reg [51:0] counter_50Mhz; always @(posedge CLK_50MHZ) begin counter_50Mhz <= counter_50Mhz + 52'd1; end
//reg [3:0] stepPulseCounter = 0;
reg [19:0] counter15625mks = 0;

wire clock_5ms = (counter_50Mhz[17:0]== 18'h3ffff);
wire clock_10ms = (counter_50Mhz[18:0]== 19'h7ffff);
wire clock_15625mks = (counter15625mks==0);

assign debug15625mks = clock_15625mks;

wire timer5msFinal = (timer5msPulsesCnt==0);
wire timer10msFinal = (timer10msPulsesCnt==0);
wire timer15625mksFinal = (timer15625mksPulsesCnt==0);

reg stepClockEna = 0;

//reg [31:0] cur_position = 0;
//reg [31:0] movePeriodTimeCounter = 0;
reg [19:0] movePeriodSpeedIncTimeCounter = 0;
 
//parameter velocity_div_start = 24'hF424;
parameter velocity_div_start = 24'h1E848;
//parameter velocity_div_start = 24'h1312d0;

reg [7:0] sinTable [63:0];
//reg [3:0] memory [15:0] ;
initial $readmemh("sin_init.hex", sinTable, 0) ;


reg [7:0] sinTableCurInd = 0;
reg [7:0] sinTableCurVal = 0;

//wire [23:0] dividerIncWire = velocity_div_start - velocityMax_div;

reg [23:0] velocityDeviation2Max_divLoc;
reg [31:0] velocityDeviation2MaxMultSin;

always @(posedge CLK_50MHZ) begin
	//if(velocity_rpm_locked != velocity_rpm) begin
		//velocity_rpm_locked <= velocity_rpm;	
	//end
	
	
	if(newPosSignal) begin
		//new_position <= newPos;
		//state <= speedConstState;		
		//if(newPos > new_position) begin
		//	dir <= 1;
		//end
		dir <= 0;
		divider <= velocity_div_start;
		velocityDeviation2Max_divLoc <= (velocity_div_start-velocityMax_div);
		
		//dividerInc[15:0] <= dividerIncWire[22:7];
		
		clockCounter <= 0;
		timer5msPulsesCnt <= 100;
		timer10msPulsesCnt <= 128;
		timer15625mksPulsesCnt <= 63;
		stepClockEna <= 1;
		state <= speedUpState;
		deltaPosLoc <= deltaPos; 		
		sinTableCurInd <= 0;
	end
	
	sinTableCurVal[7:0] <=sinTable[sinTableCurInd];
	velocityDeviation2MaxMultSin[31:0] <= velocityDeviation2Max_divLoc[23:0]*sinTable[sinTableCurInd];


	case(state)
		idleState: begin
			//state <= speedUpState;
			//stepClockEna <= 0;
		end
		
		speedUpState: begin					
			if(timer15625mksFinal) begin			
				state <= speedConstState;					
				timer10msPulsesCnt <= 100;
			end
			if(clock_15625mks) begin			
				//if(divider > 20'h115) begin
					divider[19:0] <= velocity_div_start - velocityDeviation2MaxMultSin[31:12];
					sinTableCurInd <= sinTableCurInd + 1;
				//end
				//else begin
				//	state <= speedConstState;
				//	timer10msPulsesCnt <= 1000;
				//end
				
			end
		end
		
		speedConstState: begin	
			if(timer10msFinal) begin
				state <= speedDownSpeedState;
				timer10msPulsesCnt <= 128;
				timer15625mksPulsesCnt <= 63;
				sinTableCurInd <= 63;
			end
		end
		
		speedDownSpeedState: begin
			if(timer15625mksFinal) begin			
				state <= idleState;	
				stepClockEna <= 0;
			end
			if(clock_15625mks) begin			
					divider[19:0] <= velocity_div_start - velocityDeviation2MaxMultSin[31:12];
					sinTableCurInd <= sinTableCurInd - 1;
			end

//			if(clock_10ms) begin			
//				if(divider < 20'h1E848) begin
//					divider <= divider + dividerInc;
//				end
//				else begin
//					stepClockEna <= 0;
//					state <= idleState;
//				end				
//			end
			
		end		
	endcase
	
	if(stepClockEna) begin 		
		if(clockCounter == 0) begin
			clockCounter <= divider;
			step <= 1'b1;			
			//deltaPosLoc <= deltaPosLoc - 1;
		end
		else begin
			clockCounter <= clockCounter - 1;
			if(clockCounter == {1'b0, divider[18:1]}) 
				step <= 1'b0;							
		end

		
		if((step==1'b1) && (dir==1'b1)) begin
			cur_position <= cur_position + 1;
		end
		if((step==1'b1) && (dir==1'b0)) begin
			cur_position <= cur_position - 1;
		end
	end
	
	
	if(timer5msPulsesCnt == 0) begin				
		//divider <= divider - 100;			
		//timerCounterInc <= 100;					
	end
	if(clock_5ms && (timer5msPulsesCnt>0)) begin			 
		timer5msPulsesCnt <= timer5msPulsesCnt - 1;							
	end	

	if(timer10msPulsesCnt == 0) begin				
		//divider <= divider - 100;			
		//timerCounterInc <= 100;					
	end
	if(clock_10ms && (timer10msPulsesCnt>0)) begin			 
		timer10msPulsesCnt <= timer10msPulsesCnt - 1;									
	end	
	
	
	if(counter15625mks == 0) begin		
		if(timer15625mksPulsesCnt > 0) begin			
			counter15625mks <= 781250; //15625 in 50MHz
			timer15625mksPulsesCnt <= timer15625mksPulsesCnt-1;
		end
	end
	else begin
		counter15625mks <= counter15625mks - 1;
	
	end

	
end
//
//initial
//begin
//
//	
//	sinTable[00] = 8'd0;
//	sinTable[01] = 8'd0;
//	sinTable[02] = 8'd0;
//	sinTable[03] = 8'd1;
//	sinTable[04] = 8'd1;
//	sinTable[05] = 8'd2;
//	sinTable[06] = 8'd3;
//	sinTable[07] = 8'd4;
//	sinTable[08] = 8'd6;
//	sinTable[09] = 8'd7;
//	sinTable[11] = 8'd9;
//	sinTable[12] = 8'd10;
//	sinTable[13] = 8'd12;
//	sinTable[14] = 8'd14;
//	sinTable[15] = 8'd16;
//	sinTable[16] = 8'd18;
//	sinTable[17] = 8'd21;
//	sinTable[18] = 8'd23;
//	sinTable[19] = 8'd25;
//	sinTable[20] = 8'd28;
//	sinTable[21] = 8'd31;
//	sinTable[22] = 8'd33;
//	sinTable[23] = 8'd36;
//	sinTable[24] = 8'd39;
//	sinTable[25] = 8'd42;
//	sinTable[26] = 8'd45;
//	sinTable[27] = 8'd48;
//	sinTable[28] = 8'd51;
//	sinTable[29] = 8'd54;
//	sinTable[30] = 8'd57;
//	sinTable[31] = 8'd60;
//	sinTable[32] = 8'd64;
//	sinTable[33] = 8'd67;
//	sinTable[34] = 8'd70;
//	sinTable[35] = 8'd73;
//	sinTable[36] = 8'd76;
//	sinTable[37] = 8'd79;
//	sinTable[38] = 8'd82;
//	sinTable[39] = 8'd85;
//	sinTable[40] = 8'd88;
//	sinTable[41] = 8'd91;
//	sinTable[42] = 8'd94;
//	sinTable[43] = 8'd96;
//	sinTable[44] = 8'd99;
//	sinTable[45] = 8'd102;
//	sinTable[46] = 8'd104;
//	sinTable[47] = 8'd106;
//	sinTable[48] = 8'd109;
//	sinTable[49] = 8'd111;
//	sinTable[50] = 8'd113;
//	sinTable[51] = 8'd115;
//	sinTable[52] = 8'd117;
//	sinTable[53] = 8'd118;
//	sinTable[54] = 8'd120;
//	sinTable[55] = 8'd121;
//	sinTable[56] = 8'd123;
//	sinTable[57] = 8'd124;
//	sinTable[58] = 8'd125;
//	sinTable[59] = 8'd126;
//	sinTable[60] = 8'd126;
//	sinTable[61] = 8'd127;
//	sinTable[62] = 8'd127;
//	sinTable[63] = 8'd127;
//end

endmodule
