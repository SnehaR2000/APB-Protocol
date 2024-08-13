`include "APB3_Interface.sv"
`define NO_WAIT

//APB3 MASTER MODULE
module apb3_master(APB3Signals.master intf);//MASTER MODPORT INSTANTIATION
                 
   //ENUM FOR STATE TRANSACTION  
   typedef enum reg [1:0]{
   IDLE=2'b00,
   SETUP=2'b01,
   ACCESS=2'b10
   } apb3_states; 
 

   // STATE VARIABLES
   apb3_states current_state,next_state;
 
   //PROCEDURAL BLOCK FOR INITIAL CONDITION  
    always@(posedge intf.PCLK)
     begin
      if(intf.PRESETn)
        begin
          current_state<=IDLE;
        end
       else
         begin
          current_state<=next_state;
         end
      end
 
   //COMBINATIONAAL BLOCK FOR STATE TRANSITION  
    always_comb
    begin
      case(current_state)

        IDLE:
         begin
            if(intf.PRESETn)
             begin
                next_state=IDLE;
             end
            else if(intf.data_valid == 1) // condition to check if there is any valid data
             begin
                next_state = SETUP;
             end
            else
             begin      
               next_state=IDLE;
             end        
 
           
            intf.PSELx = 0;
            intf.PWRITE = 0;
            intf.PENABLE = 0;
            intf.PWDATA = 0;
         end

        SETUP:
         begin
            next_state = ACCESS;
            intf.PSELx = 1;
             begin
             intf.PADDR = intf.addr;
              if(intf.data_dir == 1)
               begin
                intf.PWDATA = intf.data;
                intf.PWRITE = 1;
                end
              else
               begin
                intf.PWDATA = 0;
                intf.PWRITE = 0;
               end
              end
          end


        ACCESS:
         begin
            
            if(intf.PREADY == 1)
              begin
                next_state = IDLE;
              end
            else
              begin
                next_state = ACCESS;
              end

             intf.PSELx = 1;
             intf.PADDR = intf.addr;
              if(intf.data_dir == 1)
               begin
                 intf.PWDATA = intf.data;
                 intf.PWRITE = 1;
               end
              else
               begin
                intf.PWDATA = 0;
                intf.PWRITE = 0;
               end
                intf.PENABLE = 1;
          end

         default:
          begin
           next_state=IDLE;
          end
       endcase
   end 

  always @(posedge intf.PCLK)
  begin
    if(intf.PRESETn == 1)
     current_state <= IDLE;
    else
     current_state <= next_state;    
    end 
 
  // LOGIC to read out data and indicating transaction
  always @(posedge intf.PCLK)
  begin
    if((current_state == ACCESS) && (intf.PREADY == 1))
    begin
       intf.transaction_done <=1;
       
      if(intf.data_dir == 0)
      begin
        intf.data_out <= intf.PRDATA;
      end
    end
    else
    begin
        intf.transaction_done <= 0;
        intf.data_out <= 0;
    end
  end
 
endmodule


 //APB3 SLAVE MODULE
 module apb3_slave(APB3Signals.slave intf); //MODPORT SLAVE INSTANTIATION
 

   
 
  reg [31:0]memoryeven[1024:0]; //dual array this is for even address storage
  reg [31:0]memoryodd[1024:0]; //dual array this is for odd aggress storage
  logic wait_cycle=3; //wait cycle is to wait during access phase of master 


//ENUM DECLARATION FOR STATE TRANSITION

 typedef enum reg [1:0]{
  IDLE=2'b00,
  SETUP=2'b01,
  ACCESS=2'b10
} apb3_states;

//DECLARATION OF STATE VARIABLE
apb3_states current_state,next_state;

// INTERNAL REGISTERS
   reg  [31:0] count; //to count the no. of cycle it waited 
 
  initial
  begin

      count = 0;
      intf.PRDATA=1'b0;
  end
 
//PROCEDURAL BLOCK FOR SEQUENTIAL LOGIC
 
  always@(posedge intf.PCLK) begin
    if(intf.PRESETn)
      current_state<=IDLE;
    else
      current_state<=next_state;
   
    if( (current_state == IDLE) && (intf.PENABLE == 1))
    begin
       count <= count + 1;    
    end
   else
    begin
       count <= 0;    
    end
  end

//COMBINATIONAL LOGIC FOR STATE TRANSITION
 
  always@(*) begin
    case(current_state)      
      IDLE:
      begin
          `ifdef NO_WAIT // for no wait state
          if( (intf.PSELx == 1))
          begin          
              next_state = SETUP;          
          end
          `endif

           `ifdef WAIT //for wait state 
             if( (intf.PSELx == 1) &&(count>wait_cycle ))
          begin          
              next_state = SETUP;          
          end
          `endif

          else
          begin
            next_state = IDLE;            
          end
 
          intf.PREADY  = 0;  
          intf.PSLVERR = 0; 
          intf.PRDATA=0;   
         
      end
      SETUP:
      begin
         intf.PREADY = 0;
         intf.PSLVERR = 0;    
         next_state = ACCESS;
         
         if(intf.PSELx == 0)
         begin
             next_state = IDLE;
         end        
      end      
      ACCESS:
      begin
          if( (intf.PSELx == 1) && (intf.PENABLE == 1))
          begin
              next_state = IDLE;
          end
          else if((intf.PSELx == 1) && (intf.PENABLE == 0))
          begin
            next_state = ACCESS;
          end
          else
          begin
            next_state = IDLE;
          end

                    intf.PREADY = 1; 
      end
      default :
      begin
        next_state=IDLE;
      end

    endcase
  end   

always@(posedge intf.PREADY)begin
        
          if( (intf.PSELx == 1) && (intf.PENABLE == 1))
          begin
             if(intf.PADDR > 4000) //example taken to send error message above 4000 value of adrreses are considered as not present or invalid
             begin
                intf.PSLVERR <= 1;
                $display("xxxxxxxxxxxERROR DETECTEDxxxxxxxxxxxxxxx");
             end
             else if(intf.PWRITE == 0)
             begin
                 if((intf.PADDR%2)==0)begin
                 intf.PRDATA <= memoryeven[intf.PADDR];
                 end 
                 else
                 intf.PRDATA <= memoryodd[intf.PADDR];
             end
             else if(intf.PWRITE == 1)
             begin
                 if((intf.PADDR%2)==0)begin
                 memoryeven[intf.PADDR] <= intf.PWDATA;
                 end 
                 else
                 memoryodd[intf.PADDR] <= intf.PWDATA;
             end
             else
             begin
               intf.PSLVERR <= 1;
             end
          end
end

endmodule


// APB3 TOP MODULE
module top(APB3Signals intf);
apb3_master master(.intf(intf.master)); //APB3 MASTER MODULE INSTANTIATION
apb3_slave slave (.intf(intf.slave));   //APB3 SLAVE MODULE INSTANTIATION
endmodule

