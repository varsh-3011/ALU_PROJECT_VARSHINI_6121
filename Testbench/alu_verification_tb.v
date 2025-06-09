`include "alu_rtl_design_2.v"

`define PASS 1'b1
`define FAIL 1'b0

`define no_of_testcase 78

`define TEST_WIDTH (26+(4*`OP_WIDTH)) // Test vector
`define RESP_WIDTH (`TEST_WIDTH + (2* `OP_WIDTH)+ 7) //response packet
`define RES_DATA_WIDTH (2*`OP_WIDTH)+ 6 //Exact result including flags

`define SCB_STIM_WIDTH 55 //(2*`RES_DATA_WIDTH) + 11
`define SCB_FID_START 53
`define SCB_FID_END 46
`define FID_START 57
`define FID_END  50
`define RESERVED_START 49
`define RESERVED_END 48
`define RST_IDX 47
`define INVAL_START 46
`define INVAL_END 45
`define OPA_START 44
`define OPA_END 37
`define OPB_START 36
`define OPB_END 29
`define CMD_START 28
`define CMD_END 25
`define CIN_IDX 24
`define CE_IDX 23
`define MODE_IDX 22
`define ERES_START 21
`define ERES_END 6
`define COUT_IDX 5
`define EGL_START 4
`define EGL_END 2
`define OF_IDX 1
`define ERR_IDX 0

//Response packet
`define RP_ERR_IDX 58
`define RP_OFLOW_IDX 59
`define RP_EGL_START 60
`define RP_EGL_END 62
`define RP_COUT_IDX 63
`define RP_RES_START 64
`define RP_RES_END 79
`define RP_RESERVED_IDX 80

module alu_verification_tb();

integer file;

//inputs
reg [`OP_WIDTH-1:0] OPA, OPB;
reg CIN, CLK, RST, CE, MODE;
reg [3:0] CMD;
reg [1:0] INP_VALID;

//outputs
wire [(2*`OP_WIDTH)-1:0] RES;
wire COUT,OFLOW,G,E,L,ERR;

//outputs from reference model
reg [(2*`OP_WIDTH)-1:0] EXP_RES;
reg  EXP_COUT,EXP_OFLOW,EXP_G,EXP_E,EXP_L,EXP_ERR;

//Decl to Cop UP the DUT OPERATION
reg [(2*`OP_WIDTH)-1:0] RES_EXP;
reg  COUT_EXP,OFLOW_EXP,G_EXP,E_EXP,L_EXP,ERR_EXP;

//Definig memories
reg [`TEST_WIDTH-1:0] curr_test_case = 0;
reg [`TEST_WIDTH-1:0] stimulus_mem [0:`no_of_testcase-1];
reg [`TEST_WIDTH-1:0] memory_array [0:`no_of_testcase-1];
reg [`RESP_WIDTH-1:0] response_packet;
reg [`SCB_STIM_WIDTH-1:0] scb_stimulus_mem [0:`no_of_testcase-1];

//reserved bit in packet
reg [1:0] reserved;

reg [7:0]FEATURE_ID=0;
//test vector
reg [`TEST_WIDTH-1:0] test_vector;

// Feature ID - for generation of test vector
reg [7:0] fid=8'h00;

integer i,j;

reg[`RES_DATA_WIDTH-1:0] exact_data,expected_data=0;

//Instantiation of DUT
alu_rtl_design_2 dut_instance ( .OPA(OPA), .OPB(OPB), .CIN(CIN), .CLK(CLK), .RST(RST), .CMD(CMD),
                        .INP_VALID(INP_VALID),.CE(CE), .MODE(MODE), .COUT(COUT), .OFLOW(OFLOW),.RES(RES),
                         .G(G), .E(E), .L(L), .ERR(ERR) );

event fetch_stimulus;

//clock generation
initial begin
        CLK=1'b0;
        forever #10 CLK=~CLK;
end

//READ DATA FROM THE TEXT VECTOR FILE
task read_stimulus();
begin
         $readmemb ("stimulus.txt",stimulus_mem);
end
endtask

//STIMULUS GENERATOR
integer stim_mem_ptr = 0,stim_stimulus_mem_ptr = 0,feat_id =0 , pointer =0 ;

//Reference model
task automatic alu_ref_task;
    input  CLK;
    input  RST;
    input  CIN, MODE, CE;
    input  [1:0] INP_VALID;
    input  [3:0] CMD;
    input  [`OP_WIDTH-1:0] OPA, OPB;

    output reg COUT_EXP;
    output reg OFLOW_EXP;
    output reg [2*`OP_WIDTH-1:0] RES_EXP;
    output reg G_EXP, E_EXP, L_EXP;
    output reg ERR_EXP;

    reg [2*`OP_WIDTH-1:0] RES_BUFF;
    reg COUT_BUFF, OFLOW_BUFF, G_BUFF, E_BUFF, L_BUFF, ERR_BUFF;
    reg [`shift-1:0] rot_amt;

    begin
        // Reset condition
        if (RST) begin
            RES_EXP = 0;
            COUT_EXP = 1'b0;
            OFLOW_EXP = 1'b0;
            G_EXP = 1'b0;
            E_EXP = 1'b0;
            L_EXP = 1'b0;
            ERR_EXP = 1'b0;
        end else if (CE) begin
            // Clear all
            RES_BUFF = 0;
            COUT_BUFF = 0;
            OFLOW_BUFF = 0;
            G_BUFF = 0;
            L_BUFF = 0;
            E_BUFF = 0;
            ERR_BUFF = 0;

            if (MODE) begin  // Arithmetic operations
                case (CMD)
                    `ADD: if (INP_VALID == 2'b11) begin
                        RES_BUFF = OPA + OPB;
                        COUT_BUFF = RES_BUFF[`OP_WIDTH];
                    end

                    `SUB: if (INP_VALID == 2'b11) begin
                        RES_BUFF = OPA - OPB;
                        OFLOW_BUFF = (OPA < OPB);
                    end

                    `ADD_CIN: if (INP_VALID == 2'b11) begin
                        RES_BUFF = OPA + OPB + CIN;
                        COUT_BUFF = RES_BUFF[`OP_WIDTH];
                    end

                    `SUB_CIN: if (INP_VALID == 2'b11) begin
                        RES_BUFF = OPA - OPB - CIN;
                        OFLOW_BUFF = (OPA < (OPB + CIN));
                    end

                    `CMP: if (INP_VALID == 2'b11) begin
                        E_BUFF = (OPA == OPB);
                        G_BUFF = (OPA > OPB);
                        L_BUFF = (OPA < OPB);
                    end

                    `MUL_BY_INC: if (INP_VALID == 2'b11) RES_BUFF = (OPA + 1) * (OPB + 1);
                    `MUL_BY_SHIFT: if (INP_VALID == 2'b11) RES_BUFF = (OPA << 1) * OPB;

                    `ADD_SIGNED: if (INP_VALID == 2'b11) begin
                        RES_BUFF = $signed(OPA) + $signed(OPB);
                        COUT_BUFF = RES_BUFF[`OP_WIDTH];
                        OFLOW_BUFF = ((OPA[`OP_WIDTH-1] == OPB[`OP_WIDTH-1]) &&
                                     (RES_BUFF[`OP_WIDTH] != OPA[`OP_WIDTH-1]));
                        E_BUFF = ($signed(OPA) == $signed(OPB));
                        G_BUFF = ($signed(OPA) > $signed(OPB));
                        L_BUFF = ($signed(OPA) < $signed(OPB));
                    end

                    `SUB_SIGNED: if (INP_VALID == 2'b11) begin
                        RES_BUFF = $signed(OPA) - $signed(OPB);
                        OFLOW_BUFF = ((OPA[`OP_WIDTH-1] != OPB[`OP_WIDTH-1]) &&
                                     (RES_BUFF[`OP_WIDTH] != OPA[`OP_WIDTH-1]));
                        E_BUFF = ($signed(OPA) == $signed(OPB));
                        G_BUFF = ($signed(OPA) > $signed(OPB));
                        L_BUFF = ($signed(OPA) < $signed(OPB));
                    end

                    `INC_A: if (INP_VALID[0]) RES_BUFF = OPA + 1;
                    `DEC_A: if (INP_VALID[0]) RES_BUFF = OPA - 1;
                    `INC_B: if (INP_VALID[1]) RES_BUFF = OPB + 1;
                    `DEC_B: if (INP_VALID[1]) RES_BUFF = OPB - 1;

                    default: RES_BUFF = 0;
                endcase
            end else begin  // Logical operations
                case (CMD)
                    `AND: if (INP_VALID == 2'b11) RES_BUFF ={{(`OP_WIDTH){1'b0}}, OPA & OPB};
                    `NAND: if (INP_VALID == 2'b11) RES_BUFF = {{(`OP_WIDTH){1'b0}},~( OPA & OPB)};
                    `OR: if (INP_VALID == 2'b11) RES_BUFF = {{(`OP_WIDTH){1'b0}}, OPA | OPB};
                    `NOR: if (INP_VALID == 2'b11) RES_BUFF = {{(`OP_WIDTH){1'b0}}, ~(OPA | OPB)};
                    `XOR: if (INP_VALID == 2'b11) RES_BUFF = {{(`OP_WIDTH){1'b0}}, OPA ^ OPB};
                    `XNOR: if (INP_VALID == 2'b11) RES_BUFF = {{(`OP_WIDTH){1'b0}}, ~(OPA ^ OPB)};

                    `ROL_A_B: if (INP_VALID == 2'b11) begin
                        rot_amt = OPB[`shift-1:0];
                        if (|(OPB[`OP_WIDTH-1:`OP_WIDTH/2]))
                            ERR_BUFF = 1;
                        else
                            RES_BUFF = ((OPA << rot_amt) & {`OP_WIDTH{1'b1}})  | (OPA >> (`OP_WIDTH - rot_amt));
                    end

                    `ROR_A_B: if (INP_VALID == 2'b11) begin
                        rot_amt = OPB[`shift-1:0];
                        if (|(OPB[`OP_WIDTH-1:`OP_WIDTH/2]))
                            ERR_BUFF = 1;
                        else
                            RES_BUFF = (OPA >> rot_amt) |
                                       ((OPA << (`OP_WIDTH - rot_amt)) & {`OP_WIDTH{1'b1}});
                    end

                    `NOT_A: if (INP_VALID[0]) RES_BUFF = {{(`OP_WIDTH){1'b0}}, ~OPA};
                    `SHR1_A: if (INP_VALID[0]) RES_BUFF = {1'b0,OPA >> 1};
                    `SHL1_A: if (INP_VALID[0]) RES_BUFF = {{(`OP_WIDTH){1'b0}},OPA << 1};
                    `NOT_B: if (INP_VALID[1]) RES_BUFF = {{(`OP_WIDTH){1'b0}}, ~OPB};
                    `SHR1_B: if (INP_VALID[1]) RES_BUFF = {1'b0,OPB >> 1};
                    `SHL1_B: if (INP_VALID[1]) RES_BUFF = {{(`OP_WIDTH){1'b0}},OPB << 1};

                    default: RES_BUFF = 0;
                endcase
            end

            // Assign output values from buffer
            RES_EXP = RES_BUFF;
            COUT_EXP = COUT_BUFF;
            OFLOW_EXP = OFLOW_BUFF;
            G_EXP = G_BUFF;
            E_EXP = E_BUFF;
            L_EXP = L_BUFF;
            ERR_EXP = ERR_BUFF;
        end else begin
            // CE low: Clear outputs
            RES_EXP = 0;
            COUT_EXP = 0;
            OFLOW_EXP = 0;
            G_EXP = 0;
            E_EXP = 0;
            L_EXP = 0;
            ERR_EXP = 0;
        end
    end
endtask

always@(fetch_stimulus)begin
        curr_test_case=stimulus_mem[stim_mem_ptr];
        $display ("stimulus_mem data = %0b \n",stimulus_mem[stim_mem_ptr]);
        $display ("packet data = %0b \n",curr_test_case);
        stim_mem_ptr=stim_mem_ptr+1;
end
//DRIVER
task driver ();
         begin
                ->fetch_stimulus;
                @(posedge CLK);
                FEATURE_ID    =curr_test_case[`FID_START:`FID_END];
                reserved      =curr_test_case[`RESERVED_START:`RESERVED_END];
                RST           =curr_test_case[`RST_IDX];
                INP_VALID     =curr_test_case[`INVAL_START:`INVAL_END];
                OPA           =curr_test_case[`OPA_START:`OPA_END];
                OPB           =curr_test_case[`OPB_START:`OPB_END];
                CMD           =curr_test_case[`CMD_START:`CMD_END];
                CIN           =curr_test_case[`CIN_IDX];
                CE            =curr_test_case[`CE_IDX];
                MODE          =curr_test_case[`MODE_IDX];
                EXP_RES       =curr_test_case[`ERES_START:`ERES_END];
                EXP_COUT      =curr_test_case[`COUT_IDX];
                {EXP_E,EXP_G,EXP_L}=curr_test_case[`EGL_START:`EGL_END];
                EXP_OFLOW     =curr_test_case[`OF_IDX];
                EXP_ERR       =curr_test_case[`ERR_IDX];
                $display("At time (%0t), Feature_ID = %b, RST=%b, INP_VALID = %2b, OPA = %b, OPB = %b, CMD = %4b, CIN = %1b, CE = %1b, MODE = %1b, expected_result = %b, cout = %1b, Comparison_EGL = %3b, ov = %1b, err = %1b",$time,FEATURE_ID,RST,INP_VALID,OPA,OPB,CMD,CIN,CE,MODE,EXP_RES,EXP_COUT,{EXP_E,EXP_G,EXP_L},EXP_OFLOW,EXP_ERR);
        end
endtask

//GLOBAL DUT RESET
        task dut_reset ();
                begin
        CE=1;
                RST=1;
                #20 RST=0;
                end
        endtask

//GLOBAL INITIALIZATION
        task global_init ();
                begin
                curr_test_case={(`TEST_WIDTH-1){1'b0}};
                response_packet={(`RESP_WIDTH-1){1'b0}};
                stim_mem_ptr=0;
                end
        endtask


//MONITOR PROGRAM

task monitor ();
                begin
                repeat(3)@(posedge CLK);
                #5 response_packet[`TEST_WIDTH-1:0]=curr_test_case;
                response_packet[`RP_ERR_IDX]=ERR;
                response_packet[`RP_OFLOW_IDX]=OFLOW;
                response_packet[`RP_EGL_END:`RP_EGL_START]={E,G,L};
                response_packet[`RP_COUT_IDX]=COUT;
                response_packet[`RP_RES_END:`RP_RES_START] =RES;
                response_packet[`RP_RESERVED_IDX]=0; // Reserved Bit
                $display("Monitor: At time (%0t), RES = %b, COUT = %1b, EGL = %3b, OFLOW = %1b, ERR = %1b",$time,RES,COUT,{E,G,L},OFLOW,ERR);
                exact_data ={RES,COUT,{E,G,L},OFLOW,ERR};
                expected_data = {EXP_RES,EXP_COUT,{EXP_E,EXP_G,EXP_L},EXP_OFLOW,EXP_ERR};
                end
endtask


//SCORE BOARD PROGRAM TO CHECK THE DUT OP WITH EXPECTD OP

task score_board();
reg [`RES_DATA_WIDTH-1:0] expected_res;
reg [7:0] feature_id;
reg [`RES_DATA_WIDTH-1:0] response_data;
begin
        #5;
        feature_id=FEATURE_ID;
        //feature_id = curr_test_case[`FID_START:`FID_END];
        expected_res = curr_test_case[`ERES_START:`ERES_END];
        response_data = response_packet[`RP_RES_END:`RP_ERR_IDX];
        $display("feature_id = %b,expected result = %b ,response data = %b",feature_id,expected_data,exact_data);
        if(expected_data === exact_data)
                scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`PASS};
        else
                scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`FAIL};
        $display("scb_width: %b,  scb_data: %b",`SCB_STIM_WIDTH,scb_stimulus_mem[stim_stimulus_mem_ptr]);
        stim_stimulus_mem_ptr = stim_stimulus_mem_ptr + 1;
end

endtask

task gen_report;
  integer file_id, pointer;
  reg [`SCB_STIM_WIDTH-1:0] status;
  reg [7:0] feature_id;
  begin
    file_id = $fopen("results.txt", "w");
    for(pointer = 0; pointer <= `no_of_testcase-1 ; pointer = pointer+1 ) begin
      status = scb_stimulus_mem[pointer];
      feature_id = status[`SCB_FID_START:`SCB_FID_END];
      if(status[0])
        $fdisplay(file_id, "Feature ID %d : PASS", feature_id);
      else
        $fdisplay(file_id, "Feature ID %d : FAIL", feature_id);
    end
  end
endtask


// Generation of test vector
task create_test_vector;
        input [7:0] feature_id;
        input [`OP_WIDTH-1:0] opa_1,opb_1;
        input rst;
        input [3:0] command;
        input cin,clk_en,mode;
        input [2:0] inp_valid;
        begin
                FEATURE_ID=feature_id;
                reserved=2'b00;
                OPA=opa_1;
                OPB=opb_1;
                RST= rst;
                CMD=command;
                CIN=cin;
                CE= clk_en;
                MODE=mode;
                INP_VALID=inp_valid;
                alu_ref_task(CLK, RST, CIN, MODE, CE, INP_VALID, CMD, OPA, OPB, COUT_EXP, OFLOW_EXP, RES_EXP, G_EXP, E_EXP, L_EXP, ERR_EXP);
                test_vector= {FEATURE_ID,reserved, RST,INP_VALID, OPA, OPB,CMD,CIN,CE,MODE,RES_EXP,COUT_EXP,E_EXP,G_EXP,L_EXP,OFLOW_EXP,ERR_EXP};
                $fdisplay(file, "%b", test_vector);
                $display("OPA: %d, OPB: %d, fid: %d,expected RES: %b, COUT: %b, EGL: %b, OFLOW: %b, ERR: %b\n",OPA,OPB,FEATURE_ID,RES_EXP,COUT_EXP,{E_EXP,G_EXP,L_EXP},OFLOW_EXP,ERR_EXP);
        end
endtask

initial begin

#10;
global_init();
dut_reset();

file = $fopen("stimulus.txt", "w");

        while (fid !=78) begin
                if (fid < 30) begin //30 test cases for logical operation
                        for (CMD = 0; CMD <= 4'd12 ; CMD = CMD + 1) begin
                                create_test_vector(fid, $random % 256, $random % 256,1'b0, CMD, 1'b0, 1'b1, 1'b0,2'b11 );
                                fid = fid + 1;
                        end
                end

                else if (fid >= 30 && fid < 60) begin //30 test cases for arithmetic operation
                        for (CMD= 0; CMD <= 4'd13 && fid < 256; CMD = CMD + 1) begin
                                create_test_vector(fid, $random % 256, $random % 256,1'b0, CMD, 1'b0, 1'b1, 1'b1,2'b11);
                                fid = fid + 1;
                        end
                end

                else if (fid >= 60 && fid < 66) begin //6 test cases for cin
                        for (CMD = 4'd2; CMD <= 4'd3 && fid < 256; CMD = CMD + 1) begin
                                create_test_vector(fid, $random % 256, $random % 256,1'b0, CMD, 1'b1, 1'b1, 1'b1, 2'b11); //CMD,cin,ce,mode
                                fid = fid + 1;
                        end
                end
                else begin
                                 //fid, opa, opb, rst, cmd, cin, ce, mode,
                                 //inp_valid
                                create_test_vector(fid,{`OP_WIDTH{1'b1}},{`OP_WIDTH{1'b1}},1'b0,4'b0000,1'b0,1'b1,1'b1,2'b11); fid = fid + 1;
                                create_test_vector(fid,120,240,1'b0,4'b0001,1'b0,1'b1,1'b1,2'b11);fid = fid + 1;
                                create_test_vector(fid,{`OP_WIDTH{1'b1}},{`OP_WIDTH{1'b1}},1'b0,4'b0010,1'b1,1'b1,1'b1,2'b11);fid = fid + 1;//add_cin overflow
                                create_test_vector(fid,120,240,1'b0,4'b0011,1'b0,1'b1,1'b1,2'b11);fid = fid + 1; //sub_cin overflow
                                create_test_vector(fid,120,240,1'b0,4'b0011,1'b1,1'b1,1'b1,2'b11);fid = fid + 1; //Asserting reset
                                create_test_vector(fid,{`OP_WIDTH{1'b1}},240,1'b0,4'b0100,1'b0,1'b1,1'b1,2'b11);fid = fid + 1; //INC_A oflow
                                create_test_vector(fid,120,{`OP_WIDTH{1'b1}},1'b0,4'b0110,1'b0,1'b1,1'b1,2'b11);fid = fid + 1;//INC_B oflow
                                create_test_vector(fid,{`OP_WIDTH{1'b0}},240,1'b0,4'b0101,1'b0,1'b1,1'b1,2'b11);fid = fid + 1; //DEC_A oflow
                                create_test_vector(fid,120,{`OP_WIDTH{1'b0}},1'b0,4'b0111,1'b0,1'b1,1'b1,2'b11);fid = fid + 1;//DEC_B oflow
                                create_test_vector(fid,120,240,1'b0,4'b0001,1'b0,1'b0,1'b1,2'b11);fid = fid + 1;//ce=0
                                create_test_vector(fid,120,240,1'b0,4'b1111,1'b0,1'b1,1'b1,2'b11);fid = fid + 1;//invalid command

                end
        end

$fclose(file);
read_stimulus();
for(j=0;j<=`no_of_testcase-1;j=j+1)begin
        fork
                driver();
                monitor();
        join
        score_board();
end
gen_report();
$fclose(fid);
#300 $finish();
end

endmodule
