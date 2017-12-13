`ifndef JTAG_TAP_SVH
`define JTAG_TAP_SVH

`define IDCODE_VAL   'h249511c3
`define	IR_LEN       5

interface Jtag;
  logic TMS; 
  logic TCK; 
  logic TRSTn; 
  logic TDI; 
  logic TDO; 

  modport Host (
    output TMS,
    output TCK,
    output TRSTn,
    output TDI,
    input  TDO
  );

  modport Target (
    input  TMS,
    input  TCK,
    input  TRSTn,
    input  TDI,
    output TDO
  );
endinterface

typedef enum logic[3:0] {
  test_logic_reset,
  run_test_idle,
  select_dr_scan,
  capture_dr,
  shift_dr,
  exit1_dr,
  pause_dr,
  exit2_dr,
  update_dr,
  select_ir_scan,
  capture_ir,
  shift_ir,
  exit1_ir,
  pause_ir,
  exit2_ir,
  update_ir
} JtagState;

typedef enum logic[`IR_LEN-1:0] {
  EXTEST         = 'b0000,
  SAMPLE_PRELOAD = 'b0001,
  IDCODE         = 'b0010,
  DEBUG          = 'b1000,
  MBIST          = 'b1001,
  BYPASS         = 'b1111,
  RISCV_DTMCS    = 'h10,
  RISCV_DMI      = 'h11,
  DEFAULT        = 'b0101
} JtagInstruction;

`endif
