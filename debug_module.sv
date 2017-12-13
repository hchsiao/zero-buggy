`include "riscv_debug.svh"
`include "dmi_port.svh"

module debug_module #(
  parameter	ABITS      = `ABITS
)(
  DMIPort.Slave dm,

  input logic clk,
  input logic rst,
  input logic test_mode,

  output logic halted,
  output logic postexec
);

logic [31:0] mem[256];
logic [ 9:0] hartsel;
logic        ndmreset;
logic        dmactive;
logic        transfer;
logic        write;
logic [15:0] regno;

logic [31:0] rdata;
always_comb begin
  case(dm.addr)
    dmstatus: rdata = {
      16'b0,
      (hartsel != 0),
      (hartsel != 0),
      2'b0,
      !halted,
      !halted,
      halted,
      halted,
      8'h82
    };
    dmcontrol: rdata = {
      6'b0,
      hartsel,
      14'b0,
      ndmreset,
      dmactive
    };
    haltsum: rdata = {
      31'b0,
      halted
    };
    abstractcs: rdata = {
      8'd16,
      16'd0,
      8'd12
    };
    32'h40: rdata = { // TODO
      31'b0,
      halted
    };
    default: rdata = mem[dm.addr];
  endcase
end

assign dm.ready = 1;
assign dm.rdata = rdata;

int i;
always @ (posedge clk) begin
  if(rst) begin
    for(i = 0; i < 256; i=i+1)
      mem[i] <= 0;
    halted <= 0;
    hartsel <= 0;
    ndmreset <= 0;
    dmactive <= 0;
    postexec <= 0;
    transfer <= 0;
    write <= 0;
    regno <= 0;
  end
  else begin
    if(dm.valid && dm.write_en) begin
      case(dm.addr)
        dmcontrol: begin // TODO: name these constants
          halted = dm.wdata[31];
          hartsel = dm.wdata[25:16];
          ndmreset = dm.wdata[1];
          dmactive = dm.wdata[0];
        end
        command: begin
          if(0 == dm.wdata[31:24]) begin // TODO: check busy...
            postexec <= dm.wdata[18];
            transfer <= dm.wdata[17];
            write <= dm.wdata[16];
            regno <= dm.wdata[15:0];
          end
        end
        default: mem[dm.addr] <= dm.wdata;
      endcase
    end
  end
end

endmodule
