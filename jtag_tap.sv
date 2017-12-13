`include "jtag_tap.svh"
`include "riscv_debug.svh"

module jtag_tap #(
  parameter IDCODE_VAL = `IDCODE_VAL,
  parameter	DTMCS_LEN  = `DTMCS_LEN,
  parameter	DMI_LEN    = `DMI_LEN,
  parameter	IR_LEN     = `IR_LEN
)(
  input logic clk,

  Jtag.Target tap,
  input logic test_mode,

  output logic dtmcs_valid_o,
  input  DTMCS dtmcs_i,
  output DTMCS dtmcs_o,
  output logic dmi_valid_o,
  input  DMI   dmi_i,
  output DMI   dmi_o
);

logic   TDO_reg;
assign  tap.TDO = TDO_reg;

logic TCK_d, TCK_dd;
logic TCK_rise;
logic TCK_fall;
always@(posedge clk) begin
  TCK_d <= tap.TCK;
  TCK_dd <= TCK_d;
end
assign TCK_rise = !TCK_dd && TCK_d;
assign TCK_fall = TCK_dd && !TCK_d;

logic output_valid;

// ===============================================
//                  TAP FSM
// ===============================================
JtagState state;
JtagState nxt_state;

always_ff @ (posedge clk) begin
  if(TCK_rise)
    state <= nxt_state;
end

always_comb begin
	case(state)
		test_logic_reset: nxt_state = tap.TMS ? test_logic_reset : run_test_idle   ;
		run_test_idle:    nxt_state = tap.TMS ? select_dr_scan   : run_test_idle   ;
		select_dr_scan:   nxt_state = tap.TMS ? select_ir_scan   : capture_dr      ;
		capture_dr:       nxt_state = tap.TMS ? exit1_dr         : shift_dr        ;
		shift_dr:         nxt_state = tap.TMS ? exit1_dr         : shift_dr        ;
		exit1_dr:         nxt_state = tap.TMS ? update_dr        : pause_dr        ;
		pause_dr:         nxt_state = tap.TMS ? exit2_dr         : pause_dr        ;
		exit2_dr:         nxt_state = tap.TMS ? update_dr        : shift_dr        ;
		update_dr:        nxt_state = tap.TMS ? select_dr_scan   : run_test_idle   ;
		select_ir_scan:   nxt_state = tap.TMS ? test_logic_reset : capture_ir      ;
		capture_ir:       nxt_state = tap.TMS ? exit1_ir         : shift_ir        ;
		shift_ir:         nxt_state = tap.TMS ? exit1_ir         : shift_ir        ;
		exit1_ir:         nxt_state = tap.TMS ? update_ir        : pause_ir        ;
		pause_ir:         nxt_state = tap.TMS ? exit2_ir         : pause_ir        ;
		exit2_ir:         nxt_state = tap.TMS ? update_ir        : shift_ir        ;
		update_ir:        nxt_state = tap.TMS ? select_dr_scan   : run_test_idle   ;
		default:          nxt_state = test_logic_reset;
	endcase
end

// ===============================================
//                  REGISTERS
// ===============================================
JtagInstruction ir;

// RISCV specific
DTMCS dtmcs_reg;
DMI dmi_reg;
assign dtmcs_o = dtmcs_reg;
assign dtmcs_valid_o = output_valid && (RISCV_DTMCS == ir);
assign dmi_o = dmi_reg;
assign dmi_valid_o = output_valid && (RISCV_DMI == ir);

// ===============================================
//                  SCAN CHAIN
// ===============================================

// IR chain
JtagInstruction ir_chain;

// DR chain
logic [31:0] idcode_chain;
logic [ 0:0] bypass_chain;

// RISCV specific
DTMCS dtmcs_chain;
DMI dmi_chain;

// ===============================================
//                  SEQUENTIAL
// ===============================================
always_ff @ (posedge clk) begin
  if(TCK_rise) begin
    if (test_logic_reset == state) begin
      ir_chain[IR_LEN-1:0] <= 'b0;
      idcode_chain <= IDCODE_VAL;
      bypass_chain <=  1'b0;
    end
    else begin
      if(capture_ir == state)
        ir_chain <= DEFAULT;
      else if(shift_ir == state)
        ir_chain[IR_LEN-1:0] <= {tap.TDI, ir_chain[IR_LEN-1:1]};
      else begin
        if (capture_dr == state)
          case(ir)
            IDCODE:      idcode_chain    <= IDCODE_VAL;
            RISCV_DTMCS: dtmcs_chain     <= dtmcs_i;
            RISCV_DMI:   dmi_chain       <= dmi_i;
            default:     bypass_chain[0] <= 1'b0;
          endcase
        else if(shift_dr == state)
          case(ir)
            IDCODE:      idcode_chain    <= {tap.TDI, idcode_chain[31:1]};
            RISCV_DTMCS: dtmcs_chain     <= {tap.TDI, dtmcs_chain[DTMCS_LEN-1:1]};
            RISCV_DMI:   dmi_chain       <= {tap.TDI, dmi_chain[DMI_LEN-1:1]};
            default:     bypass_chain[0] <= tap.TDI;
          endcase
      end
    end
  end

  if(TCK_fall) begin
    if(shift_ir == state)
      TDO_reg <= ir_chain[0];
    else begin
      case(ir)
        IDCODE:      TDO_reg <= idcode_chain[0];
        RISCV_DTMCS: TDO_reg <= dtmcs_chain[0];
        RISCV_DMI:   TDO_reg <= dmi_chain[0];
        default:     TDO_reg <= bypass_chain[0];
      endcase
    end

    if (test_logic_reset == state) begin
      output_valid <= 0;
      ir <= IDCODE;
      dtmcs_reg <= 0;
      dmi_reg <= 0;
    end
    else if(update_ir == state) begin
      ir <= ir_chain;
      output_valid <= 0;
    end
    else if(update_dr == state) begin
      case(ir)
        RISCV_DTMCS: dtmcs_reg <= dtmcs_chain;
        RISCV_DMI:   dmi_reg <= dmi_chain;
      endcase
      output_valid <= 1;
    end
    else
      output_valid <= 0;
  end
  else
    output_valid <= 0;

end
endmodule
