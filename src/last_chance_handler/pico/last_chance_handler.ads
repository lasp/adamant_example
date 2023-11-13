with Ada.Exceptions; use Ada.Exceptions;

package Last_Chance_Handler is

   procedure Last_Wishes (Error : Exception_Occurrence);
   pragma Export (C, Last_Wishes, "__gnat_last_chance_handler");
   pragma No_Return (Last_Wishes);

end Last_Chance_Handler;
