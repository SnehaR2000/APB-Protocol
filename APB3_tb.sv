`include "APB3_Interface.sv"
`define TEST2_PSLVERR_WRITE_READ

module apb_testbench;
 
APB3Signals intf(); //INTERFACE INSTANTIATION
  


  // Initial block for clock
  initial
  begin
     $display("-----------SIMULATION STARTED----------------");
   intf.PCLK=0;
  end
  always  #5  intf.PCLK = ~ intf.PCLK;



  // Initial block for asserting & de-asserting the reset
  initial
  begin
   $monitor("Time = \t%t\t RESET = \t%0d\t Master state = \t%s\t\t \t\tSlave state = \t%s\t \t\tPRDATA = \t%d\t",$time,intf.PRESETn,t1.master.current_state,t1.slave.current_state,intf.PRDATA);
    intf.PRESETn = 1;
    #50
    intf.PRESETn = 0;
  end

    top t1(.intf(intf));//TOP MODULE INSTANTIATION

  // initial block to end the simulation
  initial
  begin
    #500;
     $display("-----------SIMULATION ENDED----------------");
    $finish;
  end
 

 

   initial
   begin  
 
//TEST SCENARIO FOR 2 WRITE FOLLOWED BY 2 READ
 `ifdef TEST1_WRITE_READ

     @(negedge intf.PRESETn);
     intf.data = 3;
     intf.addr = 8;
     intf.data_dir=1;
     intf.data_valid=1;
     @(posedge intf.transaction_done);
     intf.data_valid=0;
     $display ("MEMEORY ADDRESS EVEN SAVED DATA  = %d\t",t1.slave.memoryeven[intf.PADDR]);
     intf.data = 2;
     intf.addr = 7;
     intf.data_dir=1;
     intf.data_valid=1;
     @(posedge intf.transaction_done);
     intf.data_valid=0;
     $display ("MEMEORY ADDRESS ODD SAVED DATA = %d\t",t1.slave.memoryodd[intf.PADDR]);
     intf.data = 10;
     intf.addr = 8;
     intf.data_dir=0;
     intf.data_valid=1;
     @(posedge intf.transaction_done);
     intf.data_valid=0;

     
     intf.data = 10;
     intf.addr = 7;
     intf.data_dir=0;
     intf.data_valid=1;
     @(posedge intf.transaction_done);
     intf.data_valid=0;
`endif
 
//TEST SCENARIO FOR PSLVERR DURING WRITE OOR READ WHEN ADDRESS IS OUT OF RANGE    
`ifdef TEST2_PSLVERR_WRITE_READ
     intf.data = 4;
     intf.addr = 4002;
     intf.data_dir=0;
     intf.data_valid=1;
     @(posedge intf.transaction_done);
     intf.data_valid=0;  
`endif


        
   end

 
endmodule
