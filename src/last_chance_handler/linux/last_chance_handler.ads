with System;

package Last_Chance_Handler is

   procedure Last_Chance_Handler (Msg : System.Address; Line : Integer)
      with Export => True,
             Convention => C,
             External_Name => "__gnat_last_chance_handler";

end Last_Chance_Handler;
