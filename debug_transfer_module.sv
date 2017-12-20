`include "riscv_debug.svh"
`include "dmi_port.svh"

module debug_transfer_module #(
  parameter	ABITS      = `ABITS,
  parameter	DTMCS_LEN  = `DTMCS_LEN,
  parameter	DMI_LEN    = `DMI_LEN
)(
  input  logic dtmcs_valid_i,
  input  DTMCS dtmcs_i,
  output DTMCS dtmcs_o,
  input  logic dmi_valid_i,
  input  DMI   dmi_i,
  output DMI   dmi_o,

  DMIPort.Master dm,

  input logic clk,
  input logic rst,
  input logic test_mode
);

logic during_transaction_reg;
logic write_reg;
logic [ABITS-1:0] addr_reg;
logic [31:0] wdata_reg;
logic [31:0] rdata_reg;

// TODO: dont ignore dtmcs writes
wire [5:0] abits = ABITS;
assign dtmcs_o = {17'd0, 3'd0, 2'd0, abits, 4'd1};
// TODO: implement op field correctly
assign dmi_o = {addr_reg, rdata_reg, 2'b0};

assign dm.valid = during_transaction_reg && !dm.ready;
assign dm.write_en = write_reg;
assign dm.addr = DMI_MMAP'(addr_reg);
assign dm.wdata = wdata_reg;

always @ (posedge clk) begin
  if(rst) begin
    during_transaction_reg <= 0;
    addr_reg <= 0;
    wdata_reg <= 0;
    rdata_reg <= 0;
    write_reg <= 0;
  end
  else begin
    if(during_transaction_reg) begin
      if(dm.ready) begin
        during_transaction_reg <= 0;
        rdata_reg <= dm.rdata;
      end
    end
    // TODO: handle busy condition
    else if(dmi_valid_i) begin
      during_transaction_reg <= (1 == dmi_i.op) || (2 == dmi_i.op);
      write_reg <= (2 == dmi_i.op);
      addr_reg <= dmi_i.address;
      wdata_reg <= dmi_i.data;
    end
  end
end

endmodule
