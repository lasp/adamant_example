-- with Ada.Real_Time; use Ada.Real_Time;

package body Interrupt_Action is

   procedure Do_Action (The_Tick : Tick.T) is
      Ignore : Tick.T renames The_Tick;
      -- Now : constant Time := Clock;
   begin
      null;
   end Do_Action;

end Interrupt_Action;
