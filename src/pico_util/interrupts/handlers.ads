with System;
with Ada.Interrupts.Names;

package Handlers is

   protected type Protected_Handler is
      pragma Interrupt_Priority (System.Interrupt_Priority'Last);
   private
      procedure Handler;
      pragma Attach_Handler (Handler, Ada.Interrupts.Names.Io_Irq_Bank0_Interrupt_Cpu_1);
   end Protected_Handler;

end Handlers;
