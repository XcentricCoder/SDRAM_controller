`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2025 06:37:10 PM
// Design Name: 
// Module Name: sdram_init_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sdram_init_tb;

//Clock and Reset Declarations
reg  s_clk =0;
reg s_rstn = 0;

//SDRAM init controller Outputs

wire [3:0] init_cmd;
wire [1:0] init_ba;
wire [11:0] init_addr;
wire  init_done;

// Clock Generation 
always #5 s_clk = ~s_clk;

// Reset Generation
initial begin
    s_rstn = 1'b0;
    repeat(3) @(posedge s_clk)
    s_rstn = 1'b1;
end

//Simulation End Condition

 //Simulation End Condition
initial begin
    #160_000;   // Run for 160 µs
    $display("Simulation finished after 160 µs");
    $finish;
end

 //Instantiate DUT: SDRAM Initialization Controller
 sdram_init sdram_init_inst(
 .sys_clk (s_clk),
 .sys_rst_n (s_rstn),
 .init_cmd (init_cmd),
 .init_ba (init_ba),
 .init_addr(init_addr),
 .init_done(init_done)
 
 );
 
 

endmodule
