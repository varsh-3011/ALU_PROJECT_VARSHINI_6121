`include "alu_defines.v"

module alu_ref_model(CLK, RST, CIN, MODE,INP_VALID,CE,CMD,OPA,OPB,RES_EXP,COUT_EXP,OFLOW_EXP,G_EXP,E_EXP,L_EXP,ERR_EXP);

input [`OP_WIDTH-1:0] OPA,OPB;
input CLK,RST,CE,MODE,CIN;
input [1:0] INP_VALID;
input [3:0] CMD;
output reg COUT_EXP  = 1'b0;
output reg OFLOW_EXP = 1'b0;
output reg [2*(`OP_WIDTH)-1:0] RES_EXP ;
output reg G_EXP = 1'b0;
output reg E_EXP = 1'b0;
output reg L_EXP = 1'b0;
output reg ERR_EXP = 1'b0;

//INTERNAL REGISTER
reg COUT_BUFF,OFLOW_BUFF,G_BUFF,E_BUFF,L_BUFF,ERR_BUFF;
reg [2*(`OP_WIDTH)-1:0]RES_BUFF;
reg [`shift-1:0] rot_amt=0;

task clear_all;
begin
    RES_BUFF   = 0;
    COUT_BUFF  = 0;
    OFLOW_BUFF = 0;
    G_BUFF    = 0;
    L_BUFF    = 0;
    E_BUFF    = 0;
    ERR_BUFF = 0;
end
endtask

always @(posedge CLK or posedge RST)begin
        if (RST) begin
                RES_EXP = {(`OP_WIDTH+1){1'b0}};
                COUT_EXP = 1'b0;
                OFLOW_EXP = 1'b0;
                {E_EXP,G_EXP,L_EXP}=3'b000;
                ERR_EXP = 1'b0;
         end

        else begin
                RES_EXP = RES_BUFF;
                COUT_EXP = COUT_BUFF;
                OFLOW_EXP = OFLOW_BUFF;
                G_EXP = G_BUFF;
                E_EXP = E_BUFF;
                L_EXP = L_BUFF;
                ERR_EXP = ERR_BUFF;
        end
end

always@(posedge CLK or posedge RST) begin
            if(CE) begin
                if(MODE) begin
                    clear_all();
                    case(CMD)             // CMD is the binary code value of the Arithmetic Operation
                        `ADD:
                            begin
                                if(INP_VALID==2'b11) begin
                                    RES_BUFF=OPA+OPB;
                                    COUT_BUFF=RES_BUFF[`OP_WIDTH];
                                end
                                else ;
                            end

                        `SUB:
                            begin
                                if(INP_VALID==2'b11) begin
                                    RES_BUFF=OPA-OPB;
                                    OFLOW_BUFF = (OPA<OPB)?1:0;
                                end
                                else ;
                            end

                        `ADD_CIN:
                            begin
                                if(INP_VALID==2'b11) begin
                                    RES_BUFF=OPA+OPB+CIN;
                                    COUT_BUFF=RES_BUFF[`OP_WIDTH];
                                end
                                else;
                            end

                        `SUB_CIN:             // CMD = 0011: SUB_CIN. Here we set the overflow flag
                            begin
                                if(INP_VALID==2'b11) begin
                                    RES_BUFF=OPA-OPB-CIN;
                                    OFLOW_BUFF=(OPA<(OPB+CIN))?1:0;
                                end
                                else;
                            end

                        `CMP:
                            begin
                                if(INP_VALID==2'b11) begin
                                        E_BUFF=(OPA==OPB);
                                        G_BUFF=(OPA>OPB);
                                        L_BUFF=(OPA<OPB);
                                end
                                else;
                            end

                        `MUL_BY_INC:
                            begin
                                if(INP_VALID==2'b11)
                                    RES_BUFF= (OPA+1) *(OPB+1);
                                else;
                            end

                        `MUL_BY_SHIFT:
                            begin
                                if(INP_VALID==2'b11)
                                    RES_BUFF = (OPA<<1) * OPB;
                                else;
                            end

                        `ADD_SIGNED:
                            begin
                                if(INP_VALID==2'b11) begin
                                    RES_BUFF =  $signed(OPA) + $signed(OPB);
                                    COUT_BUFF =( RES_BUFF[`OP_WIDTH])?1:0;
                                    OFLOW_BUFF= ((OPA[`OP_WIDTH-1] == OPB[`OP_WIDTH-1]) && (RES_BUFF[`OP_WIDTH] != OPA[`OP_WIDTH-1])) ? 1'b1 : 1'b0;
                                    E_BUFF=($signed(OPA) == $signed(OPB))?1:0;
                                    G_BUFF=($signed(OPA) > $signed(OPB))?1:0;
                                    L_BUFF=($signed(OPA) < $signed(OPB))?1:0;
                                end
                                else;
                            end

                        `SUB_SIGNED:
                            begin
                                if(INP_VALID==2'b11) begin
                                    RES_BUFF =  $signed(OPA) - $signed(OPB);
                                    OFLOW_BUFF= ((OPA[`OP_WIDTH-1] != OPB[`OP_WIDTH-1]) && (RES_BUFF[`OP_WIDTH] != OPA[`OP_WIDTH-1])) ? 1'b1 : 1'b0;
                                    E_BUFF=($signed(OPA) == $signed(OPB))?1:0;
                                    G_BUFF=($signed(OPA) > $signed(OPB))?1:0;
                                    L_BUFF=($signed(OPA) < $signed(OPB))?1:0;
                                end
                                else;
                            end

                        `INC_A:
                            begin
                                    if(INP_VALID==2'b11 || INP_VALID==2'b01 )
                                        RES_BUFF=OPA+1;
                                    else;
                            end

                        `DEC_A:
                            begin
                                    if(INP_VALID==2'b11 || INP_VALID==2'b01 )
                                        RES_BUFF=OPA-1;
                                    else;
                            end

                        `INC_B:
                            begin
                                    if(INP_VALID==2'b11 || INP_VALID==2'b10 )
                                        RES_BUFF=OPB+1;
                                    else;
                            end
                        `DEC_B:
                             begin
                                    if(INP_VALID==2'b11 || INP_VALID==2'b10 )
                                        RES_BUFF=OPB-1;
                                    else;
                            end

                    default:    // For any other case send logic low value
                            clear_all();
                    endcase
                end

            else  begin// MODE signal is low, then this is a Logical Operation
                clear_all();

                case(CMD)    // CMD is the binary code value of the Logical Operation

                    `AND:
                        begin
                            if(INP_VALID==2'b11)
                                RES_BUFF=OPA&OPB;
                            else;
                        end

                    `NAND:
                         begin
                            if(INP_VALID==2'b11)
                                RES_BUFF=~(OPA&OPB);  // CMD = 0001: NAND
                            else;
                        end

                    `OR:
                        begin
                            if(INP_VALID==2'b11)
                                RES_BUFF=OPA|OPB;     // CMD = 0010: OR
                             else;
                        end

                    `NOR:
                        begin
                            if(INP_VALID==2'b11)
                                RES_BUFF=~(OPA|OPB);  // CMD = 0011: NOR
                            else;
                        end

                    `XOR:
                         begin
                            if(INP_VALID==2'b11)
                                RES_BUFF=OPA^OPB ;   // CMD = 0100: XOR
                            else;
                         end

                    `XNOR:
                         begin
                            if(INP_VALID==2'b11)
                                 RES_BUFF=~(OPA^OPB);  // CMD = 0101: XNOR
                            else;
                         end

                    `ROL_A_B:                        // CMD = 1100: ROL_A_B
                            begin
                                if(INP_VALID==2'b11)begin
                                    rot_amt=OPB[`shift-1:0];
                                        if(|(OPB[`OP_WIDTH-1: (`OP_WIDTH/2)]))
                                            ERR_BUFF=1;
                                        else
                                            RES_BUFF=((OPA<< rot_amt)&{`OP_WIDTH{1'b1}})|(OPA>>(`OP_WIDTH-rot_amt));
                                end
                                else;
                            end

                    `ROR_A_B:                        // CMD = 1101: ROR_A_B
                            begin
                                if(INP_VALID==2'b11)begin
                                    rot_amt=OPB[`shift-1:0];
                                        if(|(OPB[`OP_WIDTH-1: (`OP_WIDTH/2)]))
                                            ERR_BUFF=1;
                                        else
                                            RES_BUFF=(OPA>>rot_amt)|((OPA<<(`OP_WIDTH-rot_amt))&{`OP_WIDTH{1'b1}});
                                end
                                else;
                            end

                    `NOT_A:
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b01)
                                RES_BUFF=~OPA;
                            else;
                        end

                    `SHR1_A:
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b01)
                                    RES_BUFF=OPA >> 1;
                            else;
                        end

                    `SHL1_A:
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b01)
                                    RES_BUFF=OPA << 1;
                            else;
                        end

                    `NOT_B:            // CMD = 0111: NOT_B
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b10)
                                    RES_BUFF=~OPB;
                            else;
                        end

                    `SHR1_B:
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b10)
                                    RES_BUFF=OPB >> 1;      // CMD = 1010: SHR1_B
                            else;
                        end

                    `SHL1_B:
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b10)
                                    RES_BUFF=OPB << 1;      // CMD = 1011: SHL1_B
                            else;
                        end

                    default:    // For any other case send high impedence value
                        clear_all();

                endcase
            end
        end  //CE is low

        else
            clear_all();

    end

endmodule
