interface APB3Signals;

  // APB3 Signals
  logic PCLK;
  logic PRESETn;
  logic PSELx;
  logic PENABLE;
  logic PWRITE;
  logic [31:0] PWDATA;
  logic [31:0] PADDR;
  logic [31:0] PRDATA;
  logic PREADY;
  logic PSLVERR;
  
  //System Request Signal
  logic [31:0]addr;
  logic data_valid;
  logic [31:0]data;
  logic data_dir;
  logic [31:0] data_out;
  logic transaction_done; 


//ModPort for master 
modport master( input  addr,
                input  data_valid,
                input  data,
                input  data_dir,
                output data_out,
                output transaction_done,
                input  PCLK,
                input  PRESETn,
                output PWRITE, 
                output PSELx,
                output PENABLE,
                output PWDATA,
                input  PRDATA,
                input  PREADY,
                output PADDR,
                input PSLVERR
             );


//MODPort for slave
modport slave(input  PCLK,
              input  PRESETn,
              input  PADDR,
              input  PWDATA,
              input  PENABLE, 
              output PRDATA,
              output PREADY,
              output PSLVERR,
              input  PSELx,
              input  PWRITE
               );

endinterface

  