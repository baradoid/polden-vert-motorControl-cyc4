
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module DE0_NANO_test(

	//////////// CLOCK //////////
	input  CLOCK_50,

	//////////// LED //////////
	output [7:0] LED,

	//////////// KEY //////////
	input [1:0] KEY,

	//////////// SW //////////
	input [3:0] SW,

	//////////// 2x13 GPIO Header //////////
	inout 		    [12:0] GPIO_2,
	input 		     [2:0] GPIO_2_IN,

	//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
	output 		    [33:0] gpio0,
	input 		     [1:0] gpio0_IN,

	//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
	inout 		    [33:0] gpio1,
	input 		     [1:0] gpio1_IN 
);

//assign LED[0] = SW[0];

wire uartRxDataReady;
wire [7:0] uartRxData;

parameter uartIdle = 0; 
parameter recvNum = 1;
parameter recvDir = 2;
parameter recvPos = 3;
parameter recvVelocity = 4;
parameter processCmd = 5;
reg [3:0] recvHalfByteCnt = 0;

reg [2:0] uartState = uartIdle;
//
//async_receiver #(.ClkFrequency(50000000), .Baud(230400)) RX(.clk(CLOCK_50),
//																				 //.BitTick(uartTick1),
//																				 .RxD(gpio0_IN[0]), 
//																				 .RxD_data_ready(uartRxDataReady), 
//																				 .RxD_data(uartRxData));

reg txdStart = 0;																
reg [7:0] txdData;	

wire uartTxBusy;
reg uartTxBusyR; always @(posedge CLOCK_50) uartTxBusyR <= uartTxBusy;
wire uartTxBusyPE = uartTxBusy && ~uartTxBusyR;
wire uartTxBusyNE = ~uartTxBusy && uartTxBusyR;
wire uartTxFree = ~uartTxBusy && ~uartTxBusyR; 

integer counter50MHz = 0; always @(posedge CLOCK_50) counter50MHz <= counter50MHz + 1;
wire uartStartSignal = (counter50MHz[3:0]==4'hf);
//async_transmitter #(.ClkFrequency(50000000), .Baud(230400)) TX(.clk(CLOCK_50), 
//																					.TxD_start(txdStart),
//																					.TxD_data(txdData),
//																					.TxD(gpio0[2]),
//																					.TxD_busy(uartTxBusy));
																					
integer sendCounter = 0;
integer uartStartSendTimerCounter = 0;
integer uartSendByteTimerCounter = 0;
integer speedDivToUart = 0;
																					
//reg [23:0] newPos;
reg [15:0] deltaPos;
reg [19:0] velocityImpPerSec;
reg [3:0] posNum;
reg [11:0] newPosSignal ;
reg sign = 0;
//assign AGPIO[34] = sign;
reg [19:0] velocityMax_div = 0;
reg dir = 0;

wire [26:0] speedDiv; 
speed_divis spddiv(.numer(26'd50000000), .denom(velocityImpPerSec /*{2'h0,deltaPos[15:2]}*/), .quotient(speedDiv));

always @(posedge CLOCK_50) begin

		if((sendCounter == 0) && (uartStartSendTimerCounter == 0)) begin
			speedDivToUart <= debugDiv;//speedDiv;
			sendCounter <= 8;			
			uartStartSendTimerCounter <= 32'd250000;
		end
		else begin
			uartStartSendTimerCounter <= uartStartSendTimerCounter - 1;			
		end
		
		if( (sendCounter>0) && uartTxFree && (uartStartSignal)) begin
			if(sendCounter == 8) begin
				txdStart <= 1;	
				txdData <= "S";
			end 
			else if(sendCounter == 2) begin							
					txdStart <= 1;	
					txdData <= "\r";
			end
			else if(sendCounter == 1) begin							
					txdStart <= 1;	
					txdData <= "\n";
			end			
			else begin
					txdStart <= 1;						
					txdData <= speedDivToUart[7:0];
					speedDivToUart[31:0] <= {8'h0, speedDivToUart[31:8]};
			end
			sendCounter <= sendCounter - 1;
		end
		if(uartTxBusy) begin			
			uartSendByteTimerCounter <= uartSendByteTimerCounter - 1;
		end
		
		if(uartTxBusyPE)
			txdStart <= 1'b0;		
		
		
		if(uartRxDataReady) begin
			case(uartState)
				uartIdle: begin				
					if(uartRxData == "S") begin
						//uartState <= recvNum;	
						uartState <= recvNum;
					//	LED[1] <= 1'b1;						
					end
					else begin
					//	LED[0] <= 1'b0;						
					//	LED[1] <= 1'b0;						
					//	LED[2] <= 1'b0;						
					//	LED[3] <= 1'b0;						
					end	
					
				end			
				recvNum: begin
					uartState <= recvDir;							
					posNum <= uartRxData - 8'h30;					
					sign <=1'b0;			
					
					//deltaPos <= 16'hffff;
					deltaPos <= 16'd40000;
										
				end
				recvDir: begin
					dir <= uartRxData[0]; 
					uartState <= recvVelocity;	
					recvHalfByteCnt <= 5;
					velocityImpPerSec <= 0;
					
				end
				recvVelocity: begin
					
					//velocityMax_div <= 20'h341;
					if(uartRxData[7:0]>8'h39)
						velocityImpPerSec[19:0] <= {velocityImpPerSec[15:0], uartRxData[3:0]+4'h9 };
					else
						velocityImpPerSec[19:0] <= {velocityImpPerSec[15:0], uartRxData[3:0]};
					
					recvHalfByteCnt <= recvHalfByteCnt - 1;
					if(recvHalfByteCnt == 0) begin
						uartState <= processCmd;					
					end										
				end
				
				recvPos: begin
					uartState <= processCmd;
					
					
					velocityMax_div <= 20'h271;
					//velocityMax_div <= 20'h1F4;
					//velocityMax_div <= 20'h115;
					//velocityMax_div <= speedDiv;					
					
					sign <=1'b1;
					
					//newPos <= uartRxData;
					//deltaPos <= 16'hffff;
					
					
					//LED[3] <= 1'b1;
					
				end
				
				processCmd: begin
					uartState <= uartIdle;					
					newPosSignal[posNum] <=1'b1;
				end
			
			endcase
		end
		else begin
			newPosSignal[0] <=1'b0;	
			newPosSignal[1] <=1'b0;	
			newPosSignal[2] <=1'b0;	
			newPosSignal[3] <=1'b0;	
			newPosSignal[4] <=1'b0;	
			newPosSignal[5] <=1'b0;	
			newPosSignal[6] <=1'b0;	
			newPosSignal[7] <=1'b0;	
			newPosSignal[8] <=1'b0;	
			newPosSignal[9] <=1'b0;	
		end

end
																				 
wire [19:0] debugDiv;

wire [19:0] dividerW;
wire moveDirW;				
wire moveDirInverseW;
wire stepClockEnaW;
wire positionReset;

wire signed [31:0] curPos0;
//assign gpio0[3] = CLOCK_50;
//motorCtrl mr00(.CLK_50MHZ(CLOCK_50), .deltaPos(deltaPos), .moveDir(dir), .newPosSignal(newPosSignal[0]), .velocityMaxIPS(velocityImpPerSec), .dir(gpio0[0]), .step(gpio0[1]), 
//																																																				.debugDeviationPeriod(gpio0[5]),
//																																																				.div(debugDiv));
motorCtrlSimple mrs00(.CLK_50MHZ(CLOCK_50), .reset(positionReset), .divider(dividerW[19:0]), .moveDir(moveDirW), .moveDirInvers(moveDirInverseW), .stepClockEna(stepClockEnaW), .dir(gpio0[0]), .step(gpio0[1]), .cur_position(curPos0));
//motorCtrl mr01(.CLK_50MHZ(CLOCK_50), .deltaPos(deltaPos), .newPosSignal(newPosSignal[1]), .velocityMax_div(velocityMax_div), .dir(gpio0[2]), .step(gpio0[3]));
/*motorCtrl mr02(.CLK_50MHZ(CLOCK_50), .deltaPos(newPos[23:0]), .newPosSignal(newPosSignal[2]), .velocityMax_div(velocityMax_div), .dir(gpio0[4]), .step(gpio0[5]));
motorCtrl mr03(.CLK_50MHZ(CLOCK_50), .deltaPos(newPos[23:0]), .newPosSignal(newPosSignal[3]), .velocityMax_div(velocityMax_div), .dir(gpio0[6]), .step(gpio0[7]));
motorCtrl mr04(.CLK_50MHZ(CLOCK_50), .deltaPos(newPos[23:0]), .newPosSignal(newPosSignal[4]), .velocityMax_div(velocityMax_div), .dir(gpio0[8]), .step(gpio0[9]));
motorCtrl mr05(.CLK_50MHZ(CLOCK_50), .deltaPos(newPos[23:0]), .newPosSignal(newPosSignal[5]), .velocityMax_div(velocityMax_div), .dir(gpio0[10]), .step(gpio0[11]));
motorCtrl mr06(.CLK_50MHZ(CLOCK_50), .deltaPos(newPos[23:0]), .newPosSignal(newPosSignal[6]), .velocityMax_div(velocityMax_div), .dir(gpio0[12]), .step(gpio0[13]));
motorCtrl mr07(.CLK_50MHZ(CLOCK_50), .deltaPos(newPos[23:0]), .newPosSignal(newPosSignal[7]), .velocityMax_div(velocityMax_div), .dir(gpio0[14]), .step(gpio0[15]));
motorCtrl mr08(.CLK_50MHZ(CLOCK_50), .deltaPos(newPos[23:0]), .newPosSignal(newPosSignal[8]), .velocityMax_div(velocityMax_div), .dir(gpio0[16]), .step(gpio0[17]));
motorCtrl mr09(.CLK_50MHZ(CLOCK_50), .deltaPos(newPos[23:0]), .newPosSignal(newPosSignal[9]), .velocityMax_div(velocityMax_div), .dir(gpio0[18]), .step(gpio0[19]));*/

//motorCtrl mr01(.CLK_10MHZ(CLK_SE_AR), .clock_4ms(clock_4ms), .deltaPos(newPos[1]), .newPosSignal(newPosSignal[1]), .dir(AGPIO[33]), .step(AGPIO[34]));
//motorCtrl mr02(.CLK_10MHZ(CLK_SE_AR), .clock_4ms(clock_4ms), .deltaPos(newPos[2]), .newPosSignal(newPosSignal[2]), .dir(AGPIO[31]), .step(AGPIO[32]));
//motorCtrl mr03(.CLK_10MHZ(CLK_SE_AR), .clock_4ms(clock_4ms), .deltaPos(newPos[3]), .newPosSignal(newPosSignal[3]), .dir(AGPIO[29]), .step(AGPIO[30]));
//motorCtrl mr04(.CLK_10MHZ(CLK_SE_AR), .clock_4ms(clock_4ms), .deltaPos(newPos[4]), .newPosSignal(newPosSignal[4]), .dir(AGPIO[27]), .step(AGPIO[28]));
//motorCtrl mr05(.CLK_10MHZ(CLK_SE_AR), .clock_4ms(clock_4ms), .deltaPos(newPos[5]), .newPosSignal(newPosSignal[5]), .dir(AGPIO[25]), .step(AGPIO[26]));
//motorCtrl mr06(.CLK_10MHZ(CLK_SE_AR), .clock_4ms(clock_4ms), .deltaPos(newPos[6]), .newPosSignal(newPosSignal[6]), .dir(AGPIO[23]), .step(AGPIO[24]));
//motorCtrl mr07(.CLK_10MHZ(CLK_SE_AR), .clock_4ms(clock_4ms), .deltaPos(newPos[7]), .newPosSignal(newPosSignal[7]), .dir(AGPIO[21]), .step(AGPIO[22]));
//motorCtrl mr08(.CLK_10MHZ(CLK_SE_AR), .clock_4ms(clock_4ms), .deltaPos(newPos[8]), .newPosSignal(newPosSignal[8]), .dir(AGPIO[19]), .step(AGPIO[20]));
//motorCtrl mr09(.CLK_10MHZ(CLK_SE_AR), .clock_4ms(clock_4ms), .deltaPos(newPos[9]), .newPosSignal(newPosSignal[9]), .dir(AGPIO[17]), .step(AGPIO[18]));
//motorCtrl mr10(.CLK_10MHZ(CLK_SE_AR), .clock_4ms(clock_4ms), .newPos(newPos[10]), .newPosSignal(newPosSignal[10]), .dir(AGPIO[15]), .step(AGPIO[16]));
//motorCtrl mr11(.CLK_10MHZ(CLK_SE_AR), .clock_4ms(clock_4ms), .newPos(newPos[11]), .newPosSignal(newPosSignal[11]), .dir(AGPIO[13]), .step(AGPIO[14]));

//
nios nios(.clk_clk(CLOCK_50), .reset_reset_n(KEY[0]), 
				.pio_leds_external_connection_export(LED[7:0]),
				.pio_0_external_connection_in_port(curPos0),
				.pio_0_external_connection_out_port({moveDirInverseW, positionReset, stepClockEnaW, moveDirW, dividerW[19:0]}), 
				
				.uart_0_external_connection_rxd(gpio0_IN[0]),
				.uart_0_external_connection_txd(gpio0[2])
				/*.a_16550_uart_0_rs_232_serial_sin(gpio0_IN[0]),
				.a_16550_uart_0_rs_232_serial_sout(gpio0[2])*/);

endmodule

