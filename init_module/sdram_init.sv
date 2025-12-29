`timescale 10ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2025 12:14:13 AM
// Design Name: 
// Module Name: sdram_init
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


module sdram_init(
input wire sys_clk,
input wire sys_rst_n,
output reg [3:0] init_cmd,
output reg [1:0] init_ba,
output reg [11:0] init_addr,
output wire init_done
    );
    
    
    parameter count_power_on = 14'd15000;
    reg [13:0] count_150us;
    wire power_on_wait_done;
    
    
    
    always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        count_150us<= 14'd0;
    else if(count_150us==count_power_on)
        count_150us<= 14'd0;
    else
        count_150us <= count_150us +14'd1;
    end 
    
    
    assign power_on_wait_done = (count_150us==count_power_on);
    
    //FSM State Encoding
    
    parameter WAIT_150U = 3'd0,
              PRECHARGE = 3'd1,
              WAIT_TRP  = 3'd2,
              AUTOREFRESH = 3'd3,
              WAIT_TRFC = 3'd4,
              LOAD_MODE = 3'd5,
              WAIT_TMRD = 3'd6,
              INIT_DONE = 3'd7;
              
              
    reg [2:0] init_state;
    
    
    reg [2:0] count_clock;
    reg rst_clock_count;
    
    always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        count_clock <= 3'd0;
    else if(rst_clock_count)
        count_clock <= 3'd0;
    else if(count_clock != 3'd7)
        count_clock <= count_clock +14'd1;
    end 
    
    
    parameter TRP_COUNT = 3'd2;
    parameter TRFC_COUNT = 3'd7;
    parameter TMRD_COUNT = 3'd2;
    
    wire trp_end= ( init_state == WAIT_TRP) && (count_clock== TRP_COUNT);
    wire trfc_end= ( init_state == WAIT_TRFC) && (count_clock== TRFC_COUNT);
    wire tmrd_end= ( init_state == WAIT_TMRD) && (count_clock== TMRD_COUNT);
    
    // RESET Counter logic 
    
    always@(*)begin
    rst_clock_count = 1'b1;
    case(init_state) 
        WAIT_150U: rst_clock_count = 1'b1;
        WAIT_TRP : rst_clock_count = trp_end ? 1'b1: 1'b0;
        WAIT_TRFC : rst_clock_count = trfc_end ? 1'b1: 1'b0;
        WAIT_TMRD : rst_clock_count = tmrd_end ? 1'b1: 1'b0;
        default : rst_clock_count = 1'b1;
    endcase
    end
    
    //Initialize FSM implementations
    reg [2:0] cnt_auto_ref;
    
    always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n) begin
        init_state <= WAIT_150U;
        cnt_auto_ref <= 3'd0;
        end else begin
        case(init_state)
             WAIT_150U:begin
                cnt_auto_ref <= 3'd0;
                if(power_on_wait_done)
                    init_state <= PRECHARGE;
             end
              PRECHARGE:begin
                init_state <= WAIT_TRP;
              end
              WAIT_TRP:begin
              if(trp_end)
                init_state <= AUTOREFRESH;
              end
              AUTOREFRESH:begin
                init_state <= WAIT_TRFC;
              end              
              WAIT_TRFC:begin
                if(trfc_end)begin
                    if(cnt_auto_ref == 3'd7)begin
                        init_state <= LOAD_MODE; 
                        end
                     else begin
                        init_state <= AUTOREFRESH;
                        cnt_auto_ref <= cnt_auto_ref + 3'd1; 
                     end
                end
              end
              LOAD_MODE:begin
                init_state <= WAIT_TMRD;
              end
              WAIT_TMRD:begin
              if(tmrd_end)
                init_state <= INIT_DONE;
              end
              INIT_DONE:
                init_state <= INIT_DONE;
              default :
                init_state <= WAIT_150U;              
        endcase
        end
       // Flag INITIALISATION
        
        assign init_done = (init_state == INIT_DONE); 
       // SDRAM address, command and bank address control
       
       localparam CMD_NOP = 4'b0111;
       localparam CMD_PRECHARGE = 4'b0010;
       localparam CMD_AUTOREFRESH = 4'b0001;
       localparam CMD_LOAD_MODE = 4'b0000;
       
       
       always@(posedge sys_clk or negedge sys_rst_n) begin
       if (!sys_rst_n)begin
        init_cmd <= CMD_NOP;
        init_ba <= 2'b11;
        init_addr <= 12'hFFF;
        end else begin
        case(init_state)
        WAIT_150U, WAIT_TRP,WAIT_TRFC ,WAIT_TMRD: begin
           init_cmd <= CMD_NOP;
            init_ba <= 2'b11;
            init_addr <= 12'hFFF; 
        end
        PRECHARGE: begin
            init_cmd <= CMD_PRECHARGE;
            init_ba <= 2'b11;
            init_addr <= 12'hFFF;
        end
        AUTOREFRESH :begin
            init_cmd <= CMD_AUTOREFRESH;
            init_ba <= 2'b11;
            init_addr <= 12'hFFF;
        end
        LOAD_MODE: begin
            init_cmd <= CMD_LOAD_MODE;
            init_ba <= 2'b11;
            init_addr <= 12'b000_000_101_100;
        end 
        default: begin
            init_cmd <= CMD_NOP;
            init_ba <= 2'b11;
            init_addr <= 12'hFFF;
        end       
        endcase
        end
       
       end
        
    
endmodule
