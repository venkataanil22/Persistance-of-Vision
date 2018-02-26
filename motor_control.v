///////////////////////////////////////////////////////////
// motor_control :    									 // 
//                                   					 //
// Motor Control is implemented in three primary blocks: //
//	--> 'read_encoder' block						     //
//  -->	'PI_control_loop' block						     //
//  --> 'PWM' block      							     //
//                                                       //
// All the three primary blocks are instantiated under   //
// one single top module 'motor_contol'                  //
///////////////////////////////////////////////////////////

module motor_control(input wire encoder, clk, resetn, motor_on, // active-low reset
                     output wire pwm_out, motor_dir_a,
					 output wire [1:0] error_leds);
					 					 
// debounced buttons
wire [5:0] db_btns;

// active-low reset
assign reset = ~resetn;

// motor direction - Clockwise
assign motor_dir_a = 1'b1; 

// Read the data from the encoder
wire signed [31:0] period;
read_encoder read_encoder(encoder,clk,reset,period);

// Run the data from the encoder through a control loop to 
// determine the duty_cycle which will be an input to 'PWM' block.
wire control_clk;
clock_divider #(10) control_clk_generator(clk,control_clk);
wire signed [31:0] desired_period;
assign desired_period = 32'd20597; //at 500RPM
wire[9:0] duty_cycle;
PI_control_loop control_loop(control_clk,reset,period,desired_period,duty_cycle,error_leds);
wire [9:0] motor_duty_cycle;
assign motor_duty_cycle = motor_on ? duty_cycle : 10'b0;

// Set up the 10-bit PWM at 4.88kHz to control the motor
// based on the output 'duty_cycle of the control loop.
PWM #(10,3) PWM(motor_duty_cycle,clk,reset,pwm_out);	

endmodule

///////////////////////////////////////////////////////////
// read_encoder :                                        //
//                                                       //
// Reading output from motor encoder and counting the    //
// 'encoder period' which will be an output to           //
// PI_control_loop			         				     //
///////////////////////////////////////////////////////////

module read_encoder(input wire encoder, clk, reset,
			        output reg signed [31:0] period);

// 2-FF Synchronizer
reg prev_encoder, synch_encoder;
reg [31:0] counter;

// Counting the 'encoder period'
always @(posedge clk or posedge reset) 
begin
if (reset)
	begin
	period <= 32'h072F1;
	end
else 
	begin
	prev_encoder <= synch_encoder;
	synch_encoder <= encoder;
	
	// reset the counter and set the output period to the count value
	// on every rising edge of the encoder
	if (synch_encoder^prev_encoder) 
		begin
		period <= counter;
		counter <= 32'b1;
		end
	else 
		begin
		counter <= counter + 1'b1;
		end
	end
end

endmodule



///////////////////////////////////////////////////////////
// PI_control_loop:                                      //
//                                                       //
// Makes sure the motor running at any constant speed 	 //		        
// using PI control method. And outputs respective duty  //		        
// cycle for the PWM signal that will be generated to 	 //		        
// control the motor speed.                              //
///////////////////////////////////////////////////////////
module PI_control_loop(input wire clk, reset,
				       input wire signed [31:0] period, desired_period,
				       output reg [9:0] duty_cycle,
				       output reg [1:0] error);

wire signed [31:0] err, out;
reg signed [31:0] i; 

// difference
assign err = period - desired_period;

// The integral term is needed to remove steady state    
// error, but only used once we are close to the desired 
// period.
always @(posedge clk or posedge reset) 
begin
if (reset)
	begin
	i <= 32'b0;
	end
else if (i < $signed(32'b0)) 
	begin
	i <= 32'b0;
	end
else if (err < $signed(32'hFFF) && err > $signed(-32'hFFF))
	begin
	i <= err + i;
	end
end

assign out = (err >>> 'd3) + (i >>> 'd14);

// assign duty_cycle with the type of the error 
always@(*)
begin
if (out < $signed(32'b0)) 
	begin
	duty_cycle = 10'b0;
	error = 2'b01;
	end
else if (out > $signed(32'b1110000000)) 
	begin
	duty_cycle = 10'b1110000000;
	error = 2'b10;
	end
else 
	begin
	duty_cycle = out[9:0];
	error = 2'b00;
	end
end
					  
endmodule

///////////////////////////////////////////////////////////
// PWM                                                   //
//                                                       //
// Does required PWMing of the signal for the motor      //
// driver as per our desired speeds.                     //
///////////////////////////////////////////////////////////
module PWM #(parameter N = 10, CLK_DIV = 32) // the parameter N is the resolution of the duty 
											 // cycle, in bits.
											 // The frequency of the PWM signal is dependent on the  
										     // input parameter CLK_DIV and the duty cycle resolution.
		    (input  wire [N-1:0] duty_cycle,
		     input  wire         clk, reset,
			 output reg         signal);
			 
// Internal variables to slow down the clock 
reg slow_clk; //the slowed down clock for the PWM
reg [CLK_DIV-1:0] slow_clk_counter; //the counter used to slow down the clock
reg [N-1:0] counter; //counter for PWM output

// upon reset
always@ (posedge clk or posedge reset) 
begin
if (reset) 
	begin
	slow_clk_counter <= 1'b0;
	slow_clk <= 1'b0;
	end
else 
	begin
	slow_clk_counter <= slow_clk_counter + 1'b1;
	slow_clk <= slow_clk_counter[CLK_DIV-1];
	end
end

// Set up the counter to count on the slow clock
always @(posedge slow_clk or posedge reset) 
begin
if (reset) 
	begin
	counter <= 1'b0;
	end
else 
	begin
	counter <= counter + 1'b1;
	end
end
 
// 1-FF Synchronizer
reg [N-1:0] sync_duty_cycle;

always @(posedge slow_clk or posedge reset)
begin
if (reset) 
	begin
	sync_duty_cycle <= duty_cycle;
	end
else if (~|counter) 
	begin
	sync_duty_cycle <= duty_cycle;
	end
end


// These signals tell us when to raise or lower the output
wire raise_signal, lower_signal;
assign lower_signal = ~|(sync_duty_cycle^counter);
assign raise_signal = ~|counter;

// Set up the output signal based on the lower and raise values
always @(posedge slow_clk)
begin
if (lower_signal)
	begin
	signal <= 1'b0;
	end
else if (raise_signal) 
	begin
	signal <= 1'b1;
	end
end

endmodule

module clock_divider #(parameter CLK_DIV = 32) 
                      (input wire clk, 
					   output reg slow_clk);
					   
reg [CLK_DIV-1:0] slow_clk_counter; //the counter used to slow down the clock

// set up the slow clock and reset logic
always @(posedge clk) 
begin
slow_clk_counter <= slow_clk_counter + 1'b1;
slow_clk <= slow_clk_counter[CLK_DIV-1];
end

endmodule