`timescale 1ns / 1ps

module sdram_self_ref(
    input wire sys_clk,
    input wire sys_rst_n,
    input wire sdram_init,
    input wire self_ref_en,
    output reg sdram_cke,
    output reg [3:0] sdram_cmd,
    output reg [1:0] sdram_ba,
    output reg [11:0] sdram_addr,
    output reg self_ref_done
    );
    
        parameter PRECHARGE = 4'b0010,
              AUTOREFRESH = 4'b0001,
              NOP = 4'b0111;
         
         
         parameter SR_IDLE = 4'b0000;           // Idle state
         parameter SR_PRECHARGE = 4'b0001;      // Precharge all banks
         parameter SR_ENTRY = 4'b0010;          // Enter Self-Refresh Mode
         parameter SR_WAIT = 4'b0011;           // Stay in Self-Refresh Mode
         parameter SR_EXIT = 4'b0100;           // Exit Self-Refresh Mode
         parameter SR_POST_REFRESH = 4'b0101;   // Perform 4096 Auto-Refresh Operations
         parameter SR_WAIT_TRP = 4'b0110;       // Wait for tRP timings
         parameter SR_WAIT_TRFC1 = 4'b0111;     // First Refresh Wait State
         parameter SR_WAIT_TRFC2 = 4'b1000;     // Second Refresh Wait State
         
         reg [3:0] sr_state;                    //Self-Refresh state variable
         reg [12:0] ref_count;                  //Counter for 4096 Auto-Refresh Operations
         reg [3:0] tXSR_count;                  //Counter for tSRE timings requirements
         reg [2:0] trp_count;
         reg [3:0] trfc_count; 
         
         always@(posedge sys_clk or negedge sys_rst_n) begin
         if (!sys_rst_n) begin
            sr_state <= SR_IDLE;
            sdram_cke <= 1'b1;
            sdram_cmd <= NOP;
            sdram_ba <= 2'b11;
            sdram_addr <= 12'hfff;
            self_ref_done <= 1'b0;
            ref_count <= 13'd0;
            tXSR_count <= 4'd0;
            trp_count <= 0;
            trfc_count <= 0;
         end
         else begin
            case(sr_state)
                
                SR_IDLE: begin
                   self_ref_done <= 1'b0;
                   ref_count <= 13'd0;
                   tXSR_count <= 4'd0;
                   trp_count <= 0;
                   trfc_count <= 0;
                   if(sdram_init && self_ref_en)begin
                    sr_state <= SR_PRECHARGE;
                   end
                  end
                  
                  SR_PRECHARGE: begin
                    sr_state <= SR_WAIT_TRP;
                    sdram_cmd <= PRECHARGE;
                   end 
                   
                  SR_WAIT_TRP:begin
                    if(trp_count < 2) begin
                        sdram_cmd <= NOP;
                        trp_count <= trp_count + 1;
                        sr_state <= SR_WAIT_TRP;
                    end else begin
                        trp_count <= 0;
                        sr_state <= SR_ENTRY;
                    end
                  end
                  
                  SR_ENTRY: begin
                    sdram_cke <= 1'b0;
                    sdram_cmd <= AUTOREFRESH;
                    sr_state <= SR_WAIT_TRFC1;
                  end
                  
                  SR_WAIT_TRFC1: begin
                    sdram_cmd <= NOP;
                    if(trfc_count <8) begin
                        trfc_count <= trfc_count +1;
                        sr_state <= SR_WAIT_TRFC1;                        
                    end else begin
                        trfc_count <= 0;
                        sr_state <= SR_WAIT;
                    end
                  end
                  
                  SR_WAIT: begin
                    sdram_cke <= 1'b0;
                    sdram_cmd <= NOP;
                    if(!self_ref_en) begin
                        sr_state <= SR_POST_REFRESH;
                    end
                  end
                  
                  SR_POST_REFRESH: begin
                    sdram_cke <= 1'b1;
                    if(ref_count < 13'd4096) begin
                        sdram_cmd <= AUTOREFRESH;
                        ref_count <= ref_count +1;
                        sr_state <= SR_WAIT_TRFC2;
                        end 
                    else begin
                        sr_state <= SR_EXIT;
                        ref_count <= 13'd0;
                        end
                  end 
                  
                  SR_WAIT_TRFC2: begin
                    sdram_cmd <= NOP;
                    if(trfc_count <8) begin
                        trfc_count <= trfc_count +1;
                        sr_state <= SR_WAIT_TRFC2;                        
                    end else begin
                        trfc_count <= 0;
                        sr_state <= SR_POST_REFRESH;
                    end
                  end
                  
                  SR_EXIT: begin
                    sdram_cke <= 1'b1;
                    sdram_cmd <= NOP;
                    if(tXSR_count <= 4'd8) begin
                        tXSR_count <= tXSR_count +1;
                        sr_state <= SR_EXIT;
                    end
                    else begin
                        tXSR_count <= 4'd0;
                        sr_state <= SR_IDLE;
                        self_ref_done <= 1'b1;
                    end
                  end
                  
                  
                  default: sr_state <= SR_IDLE;               
                  
            endcase
         end
         end 
              
endmodule
