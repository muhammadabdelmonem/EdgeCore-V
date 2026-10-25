`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2025 10:59:13 PM
// Design Name: 
// Module Name: Branch_State_Machine
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


module Branch_State_Machine(
input  [1:0]   Branch_State_E,
input  [63:0]  PC_TargetE,PCPlus4E,
input         JumpE, BranchE, Jalr, BranchTaken,
output reg [63:0] Mispred_CorrectTarget,
output reg        Mispred_Sel,
output reg [1:0]  Branch_NextState
    );
    wire [2:0] Type = {BranchE,JumpE,Jalr};
  
    localparam [1:0] Strongly_Not_Taken =2'b00;
    localparam [1:0] Weakly_Not_Taken =2'b01;
    localparam [1:0] Weakly_Taken =2'b10;
    localparam [1:0] Strongly_Taken =2'b11;
    
    always@(*) begin
     case(Type)
     3'b010:begin
              Branch_NextState =Strongly_Taken;
              if( (Branch_State_E == Weakly_Not_Taken) || (Branch_State_E == Strongly_Not_Taken) )begin
                 Mispred_Sel = 1'b1;
                 Mispred_CorrectTarget=PC_TargetE;
              end
              else begin
                 Mispred_Sel = 1'b0;
                 Mispred_CorrectTarget=64'b0;
              end
            end
     3'b011:begin
              Branch_NextState =Strongly_Not_Taken;
              Mispred_Sel = 1'b1;
              Mispred_CorrectTarget=PC_TargetE;
            end
     3'b100:begin
            case(Branch_State_E) 
            Strongly_Not_Taken:begin
                                if(BranchTaken) begin
                                    Branch_NextState = Weakly_Not_Taken;
                                    Mispred_Sel = 1'b1;
                                    Mispred_CorrectTarget=PC_TargetE;
                                end
                                else begin
                                    Branch_NextState = Strongly_Not_Taken;
                                    Mispred_Sel = 1'b0;
                                    Mispred_CorrectTarget=64'b0;
                                end
                               end
            Weakly_Not_Taken:begin
                                if(BranchTaken) begin
                                    Branch_NextState = Weakly_Taken;
                                    Mispred_Sel = 1'b1;
                                    Mispred_CorrectTarget=PC_TargetE;
                                end
                                else begin
                                    Branch_NextState = Strongly_Not_Taken;
                                    Mispred_Sel = 1'b0;
                                    Mispred_CorrectTarget=64'b0;
                                end
                             end
            Weakly_Taken:begin
                                if(BranchTaken) begin
                                    Branch_NextState = Strongly_Taken;
                                    Mispred_Sel = 1'b0;
                                    Mispred_CorrectTarget=64'b0;
                                end
                                else begin
                                    Branch_NextState = Weakly_Not_Taken;
                                    Mispred_Sel = 1'b1;
                                    Mispred_CorrectTarget=PCPlus4E;
                                end
                          end
            Strongly_Taken:begin
                                if(BranchTaken) begin
                                    Branch_NextState = Strongly_Taken;
                                    Mispred_Sel = 1'b0;
                                    Mispred_CorrectTarget=64'b0;
                                end
                                else begin
                                    Branch_NextState = Weakly_Taken;
                                    Mispred_Sel = 1'b1;
                                    Mispred_CorrectTarget=PCPlus4E;
                                end
                            end
            endcase
            end
     default:begin
                Branch_NextState = Strongly_Not_Taken;
                Mispred_Sel = 1'b0;
                Mispred_CorrectTarget=64'b0;
     
             end
    endcase
    end
endmodule
