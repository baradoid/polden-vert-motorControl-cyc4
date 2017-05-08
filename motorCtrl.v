module motorCtrl(
	input CLK_50MHZ,
	input [19:0] velocityMax_div,
	input [15:0] deltaPos,
	input moveDir,
	input newPosSignal,
	output reg dir,
	output reg step,
	output reg [31:0] cur_position = 0 ,
	output debug15625mks
);

parameter idleState = 0;
parameter readFifoState = 1;
parameter calcAllValues = 2;
parameter speedUpState = 3;
parameter speedConstState = 4;
parameter speedDownSpeedState = 5;
parameter speedConstState2 = 6;

parameter speedDeviationCount = 8'd244; //244*4,096 ms ~ 1sec

reg [2:0] state = idleState;
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
parameter velocity_div_start = 20'h1E848;
//parameter velocity_div_start = 24'h1312d0;


//wire [23:0] dividerIncWire = velocity_div_start - velocityMax_div;

reg [19:0] velocityMax_divLoc;
//reg [19:0] velocityDeviation2Max_divLoc;
wire [35:0] velocityDeviationMultSin;
wire [19:0] velocityDivStartMaxDelta;

reg [15:0] deltaPosLoc;

reg moveDirLoc;


reg [5:0] sinTableAddr = 0;
//reg [7:0] sinTableCurInd = 0;
//reg [7:0] sinTableCurVal = 0;
wire [15:0] sinVal;



add20b sub20_deviaton(.dataa(velocity_div_start[19:0]), .datab(velocityMax_divLoc[19:0]), .result(velocityDivStartMaxDelta[19:0]));
sinrom sinTable(.clock(CLK_50MHZ), .address(sinTableAddr[5:0]), .q(sinVal[15:0]));
mult mpl(.dataa(sinVal[15:0]), .datab(velocityDivStartMaxDelta[19:0]), .result(velocityDeviationMultSin[35:0]));

//add20b sub20_divider(.dataa(velocity_div_start[19:0]), .datab(velocityDeviationMultSin[27:8]), .result(curVelocityDiv[19:0]));
wire [19:0] curVelocityDiv; // = velocityMax_divLoc[19:0] + velocityDeviationMultSin[35:16];
add20b_2 inst2(.dataa(velocityMax_divLoc[19:0]), .datab(velocityDeviationMultSin[35:16]), .result(curVelocityDiv[19:0]));
	
wire fifoEmpty;
reg rdReq = 0;
wire [36:0] fifoQ;
mcCmdFifo cmdFifo(.clock(CLK_50MHZ), .data( {moveDir, deltaPos[15:0], velocityMax_div[19:0]} ), 
						.rdreq(rdReq), .wrreq(newPosSignal), .empty(fifoEmpty), .q(fifoQ));
						

reg [15:0] deltaPosCur;
always @(posedge CLK_50MHZ) begin
	case(state)
		idleState: begin
			if(!fifoEmpty) begin

				rdReq <= 1'b1;		
				velocityMax_divLoc <= fifoQ[19:0];
				//20'h341;
				deltaPosLoc <= fifoQ[35:20];
				moveDirLoc <= fifoQ[36];
				
				divider[19:0] <= velocity_div_start; //velocity_div_start[19:0]+velocityMax_div[19:0];
				//velocityDeviation2Max_divLoc[19:0] <= (velocity_div_start[19:0]-velocityMax_div[19:0]);
						
				sinTableAddr <= 0;		
		
				state <= calcAllValues;
				
			end
//			
//			if(newPosSignal) begin
//
//				velocityMax_divLoc <= velocityMax_div;
//				divider[19:0] <= velocity_div_start; //velocity_div_start[19:0]+velocityMax_div[19:0];
//				//velocityDeviation2Max_divLoc[19:0] <= (velocity_div_start[19:0]-velocityMax_div[19:0]);
//				
//				timer5msPulsesCnt <= 100;
//				timer10msPulsesCnt <= 128;
//				state <= readFifoState;		
//				sinTableAddr <= 0;
//			end
		
			//stepClockEna <= 0;
		end
		
		//readFifoState: begin			
		//	state <= calcAllValues;
		//end
		
		calcAllValues: begin
			rdReq <= 1'b0;	
			//divider[19:0] <= curVelocityDiv[19:0]; 
			state <= speedUpState;
			timer15625mksPulsesCnt <= 63;
			
			stepClockEna <= 1;
			clockCounter <= 0;
			
			dir <= moveDirLoc;
			deltaPosCur <= 16'h0;
		end
		
		speedUpState: begin					
			if((timer15625mksFinal) || (deltaPosCur[15:0] >= {2'h0,deltaPosLoc[15:2]}) ) begin		//если истёк таймер или прошли четверть пути
				state <= speedConstState;					
				timer10msPulsesCnt <= 100;
				deltaPosCur[15:0] <= 0;
			end
			if(clock_15625mks) begin			
				//if(divider > 20'h115) begin
					divider[19:0] <= curVelocityDiv[19:0]; //velocityMax_divLoc[19:0]  + velocityDeviation2MaxMultSin[27:8];
					sinTableAddr <= sinTableAddr + 1;
				//end
				//else begin
				//	state <= speedConstState;
				//	timer10msPulsesCnt <= 1000;
				//end				
			end
		end
		
		speedConstState: begin	
			if(timer10msFinal || (deltaPosCur[15:0] >= {1'b0,deltaPosLoc[15:1]}) ) begin //если истёк таймер или прошли половину
				state <= speedDownSpeedState;
				//timer10msPulsesCnt <= 128;
				timer15625mksPulsesCnt <= sinTableAddr;
				sinTableAddr <= sinTableAddr-2;
				deltaPosCur <= 16'h0;
			end
		end
		
		speedDownSpeedState: begin
			if(timer15625mksFinal || (deltaPosCur[15:0] >=  deltaPosLoc[15:2])) begin				//если истёк таймер или прошли четверть пути
				state <= idleState;	
				stepClockEna <= 0;
			end
			if(clock_15625mks) begin			
					divider[19:0] <=  curVelocityDiv[19:0]; //velocityMax_divLoc[19:0] + velocityDeviation2MaxMultSin[27:8];
					sinTableAddr <= sinTableAddr - 1;
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
			deltaPosCur <= deltaPosCur + 16'h1;
	
		end
		else begin
			clockCounter <= clockCounter - 1;
			if(clockCounter == {1'b0, divider[18:1]}) 
				step <= 1'b0;							
		end


//		if((step==1'b1) && (dir==1'b1)) begin
//			cur_position <= cur_position + 1;
//		end
//		if((step==1'b1) && (dir==1'b0)) begin
//			cur_position <= cur_position - 1;
//		end
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


endmodule
