with GNAT.IO;
with System.Storage_Elements;

package body Last_Chance_Handler is

   -------------------------
   -- Last_Chance_Handler --
   -------------------------

   procedure Last_Chance_Handler (Msg : System.Address; Line : Integer) is
      -- pragma Unreferenced (Msg, Line);
      use System.Storage_Elements; -- make "+" visible for System.Address

      function Peek (Addr : System.Address) return Character is
         C : Character with
            Address => Addr;
      begin
         return C;
      end Peek;
      A : System.Address := Msg;
   begin
      GNAT.IO.Put ("LCH called => ");
      while Peek (A) /= ASCII.NUL loop
         GNAT.IO.Put (Peek (A));
         A := A + 1;
      end loop;
      GNAT.IO.Put (": ");
      GNAT.IO.Put (Line); -- avoid the secondary stack for Line'Image
      GNAT.IO.New_Line;
   end Last_Chance_Handler;

end Last_Chance_Handler;
