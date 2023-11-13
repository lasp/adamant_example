with Pico;

package body Handlers is
   protected body Protected_Handler is
      procedure Handler is
      begin
         Pico.Led.Toggle;
      end Handler;
   end Protected_Handler;
end Handlers;
