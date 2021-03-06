//CONV
module posit_single_processor #(
) (
  input                 clk_i,
  input                 rst_ni,

  input                 conv_req_i,   //instruction request control
  input                 conv_we_i,    //write enable signal
  input [3:0]           conv_be_i,    //byte enable signal
  input [31:0]          conv_addr_i,
  input [31:0]          conv_wdata_i,
  output logic          conv_rvalid_o,
  output logic [31:0]   conv_rdata_o
);

  localparam bit [9:0] OP_A = 0; 
  localparam bit [9:0] OP_B = 8;
  localparam bit [9:0] OUTPUT_OP = 16; //Cuando se envía que operación se va a realizar y a su vez se devuelve el output de la operación

  localparam bit [2:0] ADD = 1;
  localparam bit [2:0] MUL = 2;
  localparam bit [2:0] DIV = 3;

  parameter N = 16;
  //parameter Bs=log2(N);
  parameter es = 2;

  posit_add #(.N(N), .es(es)) padd (add1, add2, start, out1, inf1, zero1, done1);
  posit_mult #(.N(N), .es(es)) pmul (mul1, mul2, start, out2, inf2, zero2, done2);
  posit_div #(.N(N), .es(es)) pdiv (div1, div2, start, out3, inf3, zero3, done3);

  logic        rvalid_d, rvalid_q;
  logic [N-1:0] a_d, add1, mul1, div1;
  logic [N-1:0] b_d, add2, mul2, div2;
  logic [N-1:0] a_q;
  logic [N-1:0] b_q;
  logic [N-1:0] out;
  logic [2:0] op_q, op_d;
  logic [N-1:0] out1 = 0, out2 = 0, out3 = 0;
  logic [31:0] rdata_d, rdata_q;
  logic start = 1;
  logic inf, zero, done;
  //TODO: Meter detecciones cuando se active el flag de zero o inf
  logic inf1 = 0, inf2 = 0, inf3 = 0;
  logic zero1 = 0, zero2 = 0, zero3 = 0;
  logic done1 = 0, done2 = 0, done3 = 0;

  logic conv_we, ab_we, op_we;


  assign conv_we = conv_req_i & conv_we_i;

  assign a_we = conv_we & (conv_addr_i[4:0] == OP_A);
  assign b_we = conv_we & (conv_addr_i[4:0] == OP_B);
  assign op_we = conv_we & (conv_addr_i[4:0] == OUTPUT_OP);

  assign a_d = (a_we ? conv_wdata_i[N-1:0] : a_q);
  assign b_d = (b_we ? conv_wdata_i[N-1:0] : b_q);
  assign op_d = (op_we ? conv_wdata_i[2:0] : op_q);

  always_ff @(posedge clk_i or negedge rst_ni) begin
          if(~rst_ni) begin
                 a_q <= 'b0;
          end else begin
                 a_q <= a_d;
          end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
          if(~rst_ni) begin;
		 b_q <= 'b0;
          end else begin
		 b_q <= b_d;
          end
  end


  always_comb begin
          unique case (op_d) //Switch con todas las operaciones
                ADD: begin
			add1 <= a_q;
			add2 <= b_q;
                        inf <= inf1;
			done <= done1;
			zero <= zero1;
                        out <= out1;
		end
                MUL: begin
			mul1 <= a_q;
			mul2 <= b_q;
                        inf <= inf2;
			done <= done2;
			zero <= zero2;
                        out <= out2;
		end
                DIV: begin
			div1 <= a_q;
			div2 <= b_q;
                        inf <= inf3;
			done <= done3;
			zero <= zero3;
                        out <= out3;
		end
                default: begin
                end
          endcase
  end


  assign start = conv_be_i;


  //assign out = inf;  

  //assign out = conv_addr_i[31:0];

  assign rdata_d = out;

  always_ff @(posedge clk_i) begin
        if(conv_req_i) begin
              rdata_q <= rdata_d;
        end
  end


  assign conv_rdata_o = rdata_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
        if(!rst_ni) begin
                rvalid_q <= 1'b0;
        end else begin
                rvalid_q <= conv_req_i;
        end
  end

  assign conv_rvalid_o = rvalid_q;

endmodule