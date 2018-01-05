`ifndef RISCV_DEBUG_SVH
`define RISCV_DEBUG_SVH

`define	ABITS        15

`define	DTMCS_LEN    32
`define	DMI_LEN      (34 + `ABITS)

`define	PB_BASE_ADDR 'h700
`define	PB_ADDRRNG   'h100

typedef struct packed {
  logic [13:0] _z1;
  logic        dmihardreset;
  logic        dmireset;
  logic [ 0:0] _z2;
  logic [ 2:0] idle;
  logic [ 1:0] dmistat;
  logic [ 5:0] abits;
  logic [ 3:0] version;
} DTMCS;

typedef struct packed {
  logic [`ABITS-1:0] address;
  logic [31:0]       data;
  logic [ 1:0]       op;
} DMI;

typedef enum logic[`ABITS-1:0] {
  data0 = 'h04,
  data1,
  data2,
  data3,
  data4,
  data5,
  data6,
  data7,
  data8,
  data9,
  data10,
  data11,
  dmcontrol = 'h10,
  dmstatus,
  hartinfo,
  haltsum,
  hawindowsel,
  hawindow,
  abstractcs,
  command,
  abstractauto,
  progbuf0 = 'h20,
  progbuf1,
  progbuf2,
  progbuf3,
  progbuf4,
  progbuf5,
  progbuf6,
  progbuf7,
  progbuf8,
  progbuf9,
  progbuf10,
  progbuf11,
  progbuf12,
  progbuf13,
  progbuf14,
  progbuf15
} DMI_MMAP;

`endif
