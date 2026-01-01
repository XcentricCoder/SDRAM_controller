`timescale 1ns / 1ps

module sdram_self_rem_tb();
   reg sys_clk = 0;
   reg sys_rst_n = 0;
   reg self_ref_en = 0;
   wire sdram_cke;
   wire [3:0] sdram_cmd;
   wire [1:0] sdram_ba;
   wire [11:0] sdram_addr;
   wire self_ref_done;
   
   wire [15:0] sdram_dq;
   wire init_done;
   
   assign init_done = 1;
   
    always #5 sys_clk = ~sys_clk;
    
    initial begin
    sys_rst_n = 1'b0;
    repeat(3) @(posedge sys_clk);
    sys_rst_n = 1'b1;        
    end
    
    
    //Trigger self-refresh Module
    initial begin
        repeat(10) @(posedge sys_clk)
            self_ref_en = 1'b1;     //Enable self-refresh
        repeat(15) @(posedge sys_clk)
            self_ref_en = 1'b0;     //Disable self-refresh
    end
    
   
    // Monitor self-refresh Completion
    initial begin
        @(posedge self_ref_done)
         $display("Self-Refresh Completed");
        @(posedge sys_clk)
         $finish;
    end    
    
    sdram_self_ref sdram_self_ref_inst(
    .sys_clk (sys_clk),
    .sys_rst_n (sys_rst_n),
    .sdram_init (init_done),
    .self_ref_en (self_ref_en),
    .sdram_cke (sdram_cke),
    .sdram_cmd (sdram_cmd),
    .sdram_ba (sdram_ba),
    .sdram_addr (sdram_addr),
    .self_ref_done (self_ref_done)
    
    
    );
    // Instantiate SDRAM Model
    sdram_model_plus  sdram_model_plus_inst (
        .Dq         (sdram_dq),        // Bi-directional Data Bus
        .Addr       (sdram_addr),      // Address Bus
        .Ba         (sdram_ba),        // Bank Address
        .Clk        (sys_clk),           // Clock
        .Cke        (sdram_cke),       // Clock Enable
        .Cs_n       (sdram_cmd[3]),    // Chip Select
        .Ras_n      (sdram_cmd[2]),    // Row Address Strobe
        .Cas_n      (sdram_cmd[1]),    // Column Address Strobe
        .We_n       (sdram_cmd[0]),    // Write Enable
        .Dqm        (2'b00),           // Data Mask
        .Debug      (1'b1)             // Debug Mode
    );
endmodule
