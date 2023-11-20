with Ada.Text_IO; use Ada.Text_IO;
with Tick.Representation;

package body Interrupt_Action is
   procedure Do_Action (The_Tick : in Tick.T) is
   begin
      Put_Line ("Interrupt received: ");
      Put_Line (Tick.Representation.Image (The_Tick));
   end Do_Action;
end Interrupt_Action;
