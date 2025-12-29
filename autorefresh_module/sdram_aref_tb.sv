module sdram_aref_tb();
    
    reg sys_clk = 0;
    reg sys_rst_n =0;
    
    always #5 sys_clk = ~sys_clk;
    
    initial begin
    sys_rst_n = 1'b0;
    repeat(3) @(posedge sys_clk);
    sys_rst_n = 1'b1;        
    end
    
    
    //SDRAM init controller Outputs

wire [3:0] init_cmd;
wire [1:0] init_ba;
wire [11:0] init_addr;
wire  init_done;



 //Instantiate DUT: SDRAM Initialization Controller
 sdram_init sdram_init_inst(
 .sys_clk (sys_clk),
 .sys_rst_n (sys_rst_n),
 .init_cmd (init_cmd),
 .init_ba (init_ba),
 .init_addr(init_addr),
 .init_done(init_done)
 
 );
 
 
 reg aref_en =0;
 
 //DUT Output 
 wire aref_req;
 wire aref_end;
 wire [3:0] aref_cmd_out;
 wire [1:0] aref_ba_out;
 wire [11:0] aref_addr_out;
 
 //Signals to SDRAM model
 wire [3:0] sdram_cmd;
 wire [1:0] sdram_ba;
 wire [11:0] sdram_addr;
 
     // DUT instantiation
    sdram_aref dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .init_end(init_done),
        .aref_en(aref_en),
        .aref_req(aref_req),
        .aref_cmd_out(aref_cmd_out),
        .aref_ba_out(aref_ba_out),
        .aref_addr_out(aref_addr_out),
        .aref_end(aref_end)
        
    );
    

  
    // Command/address routing: only valid after init_done
    assign sdram_cmd  = (init_done) ? aref_cmd_out  : init_cmd; // 1111 = NOP
    assign sdram_ba   = (init_done) ? aref_ba_out   :init_ba;
    assign sdram_addr = (init_done) ? aref_addr_out : init_addr;
 
 
    initial begin
        $monitor("Time=%0t: init_done=%b, aref_en=%b, aref_req=%b, aref_end=%b, aref_state=%b",
                 $time, init_done, aref_en, aref_req, aref_end, dut.aref_state);
    end
    
    // Test sequence
initial begin
    // Wait for initialization to complete
    wait(init_done == 1'b1);
    $display("Initialization complete at time %0t", $time);
    
    // Wait for auto-refresh request (clk_count needs to reach threshold)
    wait(aref_req == 1'b1);
    $display("Auto-refresh requested at time %0t", $time);
    
    // Enable auto-refresh
    @(posedge sys_clk);
    aref_en = 1'b1;
    $display("Auto-refresh enabled at time %0t", $time);
    
    // Wait for auto-refresh to complete
    wait(aref_end == 1'b1);
    $display("Auto-refresh completed at time %0t", $time);
    
    // Disable aref_en to prevent immediate retrigger
    @(posedge sys_clk);
    aref_en = 1'b0;
    
    // Wait a bit more
    repeat(10) @(posedge sys_clk);
    
    $display("Test completed successfully!");
    $finish;
end
    // Timeout
    initial begin
        #5000000; // 5ms timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end    
    
endmodule
