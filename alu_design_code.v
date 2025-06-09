`include "alu_defines.v"

module alu_rtl_design_2 (OPA,OPB,CIN,CLK,RST,INP_VALID,CMD,CE,MODE,COUT,OFLOW,RES,G,E,L,ERR);

//Input output port declaration

input [`OP_WIDTH-1:0] OPA,OPB;
input CLK,RST,CE,MODE,CIN;
input [1:0] INP_VALID;
input [3:0] CMD;


//output reg [`OP_WIDTH:0] RES  = {(`OP_WIDTH+1){1'b0}};
output reg COUT  = 1'b0;
output reg OFLOW = 1'b0;
output reg [2*(`OP_WIDTH)-1:0] RES ;
output reg G = 1'b0;
output reg E = 1'b0;
output reg L = 1'b0;
output reg ERR = 1'b0;

reg [`shift-1:0] shift_amt=0;

//Temporary register declaration
reg [`OP_WIDTH-1:0] OPA_1, OPB_1;
reg COUT_BUFF,OFLOW_BUFF,G_BUFF,E_BUFF,L_BUFF,ERR_BUFF;
reg [2*(`OP_WIDTH)-1:0]RES_BUFF;

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

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        RES = {(`OP_WIDTH+1){1'b0}};
        COUT = 1'b0;
        OFLOW = 1'b0;
        G = 1'b0;
        E = 1'b0;
        L = 1'b0;
        ERR = 1'b0;
    end

    else begin
        RES = RES_BUFF;
        COUT = COUT_BUFF;
        OFLOW = OFLOW_BUFF;
        G = G_BUFF;
        E = E_BUFF;
        L = L_BUFF;
        ERR = ERR_BUFF;
    end
end

always@(posedge CLK) begin
            if(CE) begin
                if(MODE) begin
                    clear_all();
                    case(CMD)
                        `ADD:
                            begin
                                if(INP_VALID==2'b11) begin
                                    RES_BUFF={{`OP_WIDTH{1'b0}} ,OPA}+ {{`OP_WIDTH{1'b0}} ,OPB};
                                    COUT_BUFF=RES_BUFF[`OP_WIDTH]?1:0;
                                end
                                else ;
                            end

                        `SUB:
                            begin
                                if(INP_VALID==2'b11) begin
                                    RES_BUFF={{`OP_WIDTH{1'b0}} ,OPA}- {{`OP_WIDTH{1'b0}} ,OPB};
                                    OFLOW_BUFF = ((OPA[`OP_WIDTH-1] != OPB[`OP_WIDTH-1]) && (RES_BUFF[`OP_WIDTH] != OPA[`OP_WIDTH-1])) ? 1'b1 : 1'b0;
                                end
                                else ;
                            end

                        `ADD_CIN:
                            begin
                                if(INP_VALID==2'b11) begin
                                    RES_BUFF={{`OP_WIDTH{1'b0}} ,OPA}+ {{`OP_WIDTH{1'b0}} ,OPB} + CIN;
                                    COUT_BUFF=RES_BUFF[`OP_WIDTH]?1:0;
                                end
                                else;
                            end

                        `SUB_CIN:             // CMD = 0011: SUB_CIN. Here we set the overflow flag
                            begin
                                if(INP_VALID==2'b11) begin
                                    RES_BUFF={{`OP_WIDTH{1'b0}} ,OPA} - {{`OP_WIDTH{1'b0}} ,OPB} - CIN;
                                    OFLOW_BUFF=((OPA[`OP_WIDTH-1] != OPB[`OP_WIDTH-1]) && (RES_BUFF[`OP_WIDTH-1] != OPA[`OP_WIDTH-1])) ? 1'b1 : 1'b0;
                                end
                                else;
                            end

                        `CMP:
                            begin
                                if(INP_VALID==2'b11) begin
                                    if(OPA==OPB)
                                            {E_BUFF,G_BUFF,L_BUFF}=3'b100;

                                    else if(OPA>OPB)
                                            {E_BUFF,G_BUFF,L_BUFF}=3'b010;

                                    else
                                            {E_BUFF,G_BUFF,L_BUFF}=3'b001;
                                end
                                else;
                            end

                        `MUL_BY_INC:
                            begin
                                if(INP_VALID==2'b11)
                                    RES_BUFF=(OPA+1)*(OPB+1) ;
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
                                    if(INP_VALID==2'b11 || INP_VALID==2'b01 )begin
                                        RES_BUFF={{`OP_WIDTH{1'b0}} ,OPA}+ 1;
                                        if(RES_BUFF[`OP_WIDTH]) OFLOW_BUFF=1;
                                        else;
                                    end
                                    else;
                            end

                        `DEC_A:
                            begin
                                    if(INP_VALID==2'b11 || INP_VALID==2'b01 )begin
                                        if(OPA==0) OFLOW_BUFF=1;
                                        else RES_BUFF={{`OP_WIDTH{1'b0}} ,OPA} - 1;
                                    end
                                    else;
                            end

                        `INC_B:
                            begin
                                    if(INP_VALID==2'b11 || INP_VALID==2'b01 )begin
                                        RES_BUFF={{`OP_WIDTH{1'b0}} ,OPB}+ 1;
                                        if(RES_BUFF[`OP_WIDTH]) OFLOW_BUFF=1;
                                        else;
                                    end
                                    else;
                            end

                        `DEC_B:
                             begin
                                    if(INP_VALID==2'b11 || INP_VALID==2'b01 )begin
                                        if(OPA==0) OFLOW_BUFF=1;
                                        else RES_BUFF={{`OP_WIDTH{1'b0}} ,OPA} - 1;
                                    end
                                    else;
                             end

                    default:    // For any other case send logic low value
                            clear_all();
                    endcase
                end

            else  begin// MODE signal is low, perform logical operation
                clear_all();

                case(CMD)

                        `AND:
                           begin
                                 if(INP_VALID==2'b11)
                                        RES_BUFF=('hFF & (OPA & OPB));
                                else;
                           end

                        `NAND:
                           begin
                                 if(INP_VALID==2'b11)
                                        RES_BUFF=('hFF & (~(OPA & OPB)));
                                 else;
                           end

                        `OR:
                           begin
                                 if(INP_VALID==2'b11)
                                        RES_BUFF=('hFF & (OPA | OPB));
                                else;
                           end

                    `NOR:
                        begin
                            if(INP_VALID==2'b11)
                                RES_BUFF=('hFF & ~(OPA | OPB));
                            else;
                        end

                    `XOR:
                         begin
                            if(INP_VALID==2'b11)
                                RES_BUFF=('hFF & (OPA ^ OPB));
                            else;
                         end

                    `XNOR:
                         begin
                            if(INP_VALID==2'b11)
                                 RES_BUFF=('hFF & ~(OPA ^ OPB));
                            else;
                         end

                    `ROL_A_B:
                            begin
                                if(INP_VALID==2'b11)begin
                                    shift_amt=OPB[`shift-1:0];
                                        if(|(OPB[`OP_WIDTH-1: (`OP_WIDTH/2)]))
                                            ERR_BUFF=1;
                                        else
                                            RES_BUFF=((OPA<< shift_amt)&{`OP_WIDTH{1'b1}})|((OPA>>(`OP_WIDTH-shift_amt)));
                                end
                                else;
                            end

                    `ROR_A_B:
                            begin
                                if(INP_VALID==2'b11)begin
                                    shift_amt=OPB[`shift-1:0];
                                        if(|(OPB[`OP_WIDTH-1: (`OP_WIDTH/2)]))
                                            ERR_BUFF=1;
                                        else
                                            RES_BUFF=((OPA>>shift_amt))|((OPA<<(`OP_WIDTH-shift_amt))&{`OP_WIDTH{1'b1}});
                                end
                                else;
                            end

                    `NOT_A:
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b01)
                                RES_BUFF=('hFF & ~OPA);
                            else;
                        end

                    `SHR1_A:
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b01)
                                    RES_BUFF=('hFF & {1'b0,OPA>>1});
                            else;
                        end

                    `SHL1_A:
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b01)
                                    RES_BUFF=('hFF & (OPA<<1));
                            else;
                        end

                    `NOT_B:
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b10)
                                    RES_BUFF=('hFF & ~OPB);
                            else;
                        end

                    `SHR1_B:
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b10)
                                    RES_BUFF=('hFF & {1'b0,OPB>>1});
                            else;
                        end

                    `SHL1_B:
                        begin
                            if(INP_VALID==2'b11 || INP_VALID==2'b10)
                                    RES_BUFF=('hFF & (OPB<<1));
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
