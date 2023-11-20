--------------------------------------------------------------------------------
-- Interrupt_Responder Component Implementation Body
--------------------------------------------------------------------------------

with Interrupt_Action;

package body Component.Interrupt_Responder.Implementation is

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The schedule invokee connector
   overriding procedure Tick_T_Recv_Sync (Self : in out Instance; Arg : in Tick.T) is
      Ignore : Instance renames Self;
   begin
      -- Call the interrupt action:
      Interrupt_Action.Do_Action (Arg);
   end Tick_T_Recv_Sync;

end Component.Interrupt_Responder.Implementation;
