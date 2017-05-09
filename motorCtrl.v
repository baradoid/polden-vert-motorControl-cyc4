module motorCtrl(
	input CLK_50MHZ,
	input [19:0] velocityMaxIPS,
	input [15:0] deltaPos,
	input moveDir,
	input newPosSignal,
	output reg dir,
	output reg step,
	output reg [31:0] cur_position = 0 ,
	output debugDeviationPeriod,
	output reg [19:0] div
);

parameter idleState = 0;
parameter readFifoState = 1;
parameter calcAllValues1 = 2;
parameter calcAllValues2 = 3;
parameter speedUpState = 4;
parameter speedConstState = 5;
parameter speedDownSpeedState = 6;
parameter speedConstState2 = 7;

parameter maxSpeedAccelIPS = 80000; //imp per sec2
parameter clockFreq = 50000000; //Hz
parameter points = 64; //

parameter speedDeviationPeriod = (clockFreq/(points*maxSpeedAccelIPS)*64);

parameter speedDeviationCount = 8'd244; //244*4,096 ms ~ 1sec

reg [4:0] state = idleState;
reg [15:0] timer5msPulsesCnt = 0;
reg [15:0] timer10msPulsesCnt = 0;
reg [7:0] timer15625mksPulsesCnt = 0; //15625 in 50MHz

reg [19:0] clockCounter = 0;
reg [19:0] divider = 0;
//reg [15:0] dividerInc = 0;



reg [51:0] counter_50Mhz; always @(posedge CLK_50MHZ) begin counter_50Mhz <= counter_50Mhz + 52'd1; end
//reg [3:0] stepPulseCounter = 0;
reg [19:0] counter15625mks = 0;

reg [23:0] deviationPeriodCounter = 0;
reg [23:0] deviationPeriodVal = 0;
reg [7:0] deviationTimerPulsesCnt = 0;

//wire clock_5ms = (counter_50Mhz[17:0]== 18'h3ffff);
wire clock_10ms = (counter_50Mhz[18:0]== 19'h7ffff);
//wire clock_15625mks = (counter15625mks==0);
wire clock_deviation = (deviationPeriodCounter==0);

assign debugDeviationPeriod = clock_deviation;
//
//wire timer5msFinal = (timer5msPulsesCnt==0);
wire timer10msFinal = (timer10msPulsesCnt==0);
//wire timer15625mksFinal = (timer15625mksPulsesCnt==0);

wire deviationTimerFinal = (deviationPeriodCounter==0);


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
wire [35:0] velocityDeviationMultSinWire;

wire [19:0] velocityDivStartMaxDeltaWire;
reg [19:0] velocityDivStartMaxDeltaReg;

reg [15:0] deltaPosLoc;

reg moveDirLoc;


reg [5:0] sinTableAddr = 0;
//reg [7:0] sinTableCurInd = 0;
//reg [7:0] sinTableCurVal = 0;
wire [15:0] sinVal;



add20b sub20_deviaton(.dataa(velocity_div_start[19:0]), .datab(velocityMax_divLoc[19:0]), .result(velocityDivStartMaxDeltaWire[19:0])); //sub
sinrom sinTable(.clock(CLK_50MHZ), .address(sinTableAddr[5:0]), .q(sinVal[15:0]));
mult mpl(.dataa(sinVal[15:0]), .datab(velocityDivStartMaxDeltaReg[19:0]), .result(velocityDeviationMultSinWire[35:0]));

//add20b sub20_divider(.dataa(velocity_div_start[19:0]), .datab(velocityDeviationMultSin[27:8]), .result(curVelocityDiv[19:0]));
wire [19:0] curVelocityDiv; // = velocityMax_divLoc[19:0] + velocityDeviationMultSin[35:16];
add20b_2 inst2(.dataa(velocityMax_divLoc[19:0]), .datab(velocityDeviationMultSinWire[35:16]), .result(curVelocityDiv[19:0]));
	
wire fifoEmpty;
reg rdReq = 0;
wire [36:0] fifoQ;
mcCmdFifo cmdFifo(.clock(CLK_50MHZ), .data( {moveDir, deltaPos[15:0], velocityMaxIPS[19:0]} ), 
						.rdreq(rdReq), .wrreq(newPosSignal), .empty(fifoEmpty), .q(fifoQ));

wire [35:0] deviationPeriodWire;
mult20bx16b inst1(.dataa(fifoQ[19:0]), .datab(speedDeviationPeriod), .result(deviationPeriodWire));

wire [26:0] speedDiv; 
speed_divis spddiv(.numer(26'd50000000), .denom(fifoQ[19:0]), .quotient(speedDiv));
						
reg [15:0] deltaPosCur;
always @(posedge CLK_50MHZ) begin
	case(state)
		idleState: begin
			if(!fifoEmpty) begin

				rdReq <= 1'b1;						
				//20'h341;
				deltaPosLoc <= fifoQ[35:20];
				moveDirLoc <= fifoQ[36];
				
				divider[19:0] <= velocity_div_start; //velocity_div_start[19:0]+velocityMax_div[19:0];
				//velocityDeviation2Max_divLoc[19:0] <= (velocity_div_start[19:0]-velocityMax_div[19:0]);
						
				sinTableAddr <= 0;		
		
				state <= calcAllValues1;
				
				
				deviationPeriodVal <= deviationPeriodWire[30:6]; // div by 64
				velocityMax_divLoc <= speedDiv[19:0];
				//div <= speedDiv[19:0];
				
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
		
		calcAllValues1: begin
			rdReq <= 1'b0;	
			velocityDivStartMaxDeltaReg <= velocityDivStartMaxDeltaWire;
			//divider[19:0] <= curVelocityDiv[19:0]; 
			state <= calcAllValues2;
			
			stepClockEna <= 1;
			clockCounter <= 0;
			
			dir <= moveDirLoc;
			deltaPosCur <= 16'h0;
			
			deviationTimerPulsesCnt <= 63;
		end
		
		calcAllValues2: begin		
			velocityDivStartMaxDeltaReg <= velocityDivStartMaxDeltaWire;
		end
		
		speedUpState: begin					
			if(deviationTimerFinal) begin		//РµСЃР»Рё РёСЃС‚С‘Рє С‚Р°Р№РјРµСЂ РёР»Рё РїСЂРѕС€Р»Рё С‡РµС‚РІРµСЂС‚СЊ РїСѓС‚Рё
				state <= speedConstState;					
				timer10msPulsesCnt <= 100;
				deltaPosCur[15:0] <= 0;
			end
			if(clock_deviation) begin			
				//if(divider > 20'h115) begin
					div <= curVelocityDiv[19:0];
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
			if(timer10msFinal ) begin //РµСЃР»Рё РёСЃС‚С‘Рє С‚Р°Р№РјРµСЂ РёР»Рё РїСЂРѕС€Р»Рё РїРѕР»РѕРІРёРЅСѓ
				state <= speedDownSpeedState;
				//timer10msPulsesCnt <= 128;
				deviationTimerPulsesCnt <= 63;
				sinTableAddr <= 63;
				deltaPosCur <= 16'h0;
			end
		end
		
		speedDownSpeedState: begin
			if(deviationTimerFinal ) begin				//РµСЃР»Рё РёСЃС‚С‘Рє С‚Р°Р№РјРµСЂ РёР»Рё РїСЂРѕС€Р»Рё С‡РµС‚РІРµСЂС‚СЊ РїСѓС‚Рё
				state <= idleState;	
				stepClockEna <= 0;
			end
			if(clock_deviation) begin			
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
	
	
//	if(timer5msPulsesCnt == 0) begin				
//		//divider <= divider - 100;			
//		//timerCounterInc <= 100;					
//	end
//	if(clock_5ms && (timer5msPulsesCnt>0)) begin			 
//		timer5msPulsesCnt <= timer5msPulsesCnt - 1;							
//	end	
//
	if(timer10msPulsesCnt == 0) begin				
		//divider <= divider - 100;			
		//timerCounterInc <= 100;					
	end
	if(clock_10ms && (timer10msPulsesCnt>0)) begin			 
		timer10msPulsesCnt <= timer10msPulsesCnt - 1;									
	end	
	
//	
//	if(counter15625mks == 0) begin		
//		if(timer15625mksPulsesCnt > 0) begin			
//			counter15625mks <= 781250; //15625 in 50MHz
//			timer15625mksPulsesCnt <= timer15625mksPulsesCnt-1;
//		end
//	end
//	else begin
//		counter15625mks <= counter15625mks - 1;
//	
//	end

	if(deviationPeriodCounter == 0) begin		
		if(deviationTimerPulsesCnt > 0) begin			
			deviationPeriodCounter <= deviationPeriodVal; 
			deviationTimerPulsesCnt <= deviationTimerPulsesCnt-1;
		end
	end
	else begin
		deviationPeriodCounter <= deviationPeriodCounter - 1;
	
	end
	
	
	
end
//


endmodule

