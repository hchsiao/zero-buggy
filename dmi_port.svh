`ifndef DMI_PORT_SVH
`define DMI_PORT_SVH

`include "riscv_debug.svh"

interface DMIPort;
  logic          valid;
  logic          ready;
  logic          write_en;
  DMI_MMAP       addr;
  logic [31:0]   rdata;
  logic [31:0]   wdata;

  modport Master (
    output valid,
    input  ready,
    output write_en,
    output addr,
    input  rdata,
    output wdata
  );

  modport Slave (
    input  valid,
    output ready,
    input  write_en,
    input  addr,
    output rdata,
    input  wdata
  );
endinterface

`endif
