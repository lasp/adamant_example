with Pico_Uart;

package body Diagnostic_Uart is

   function Get return Basic_Types.Byte is
   begin
      return Pico_Uart.Receive_Byte;
   end Get;

   procedure Get (Bytes : out Basic_Types.Byte_Array) is
   begin
      for B of Bytes loop
         B := Pico_Uart.Receive_Byte;
      end loop;
   end Get;

   procedure Put (B : in Basic_Types.Byte) is
      Bytes : constant Basic_Types.Byte_Array (0 .. 0) := [0 => B];
   begin
      Pico_Uart.Send_Byte_Array (To_Send => Bytes);
   end Put;

   procedure Put (Bytes : in Basic_Types.Byte_Array) is
   begin
      Pico_Uart.Send_Byte_Array (To_Send => Bytes);
   end Put;

end Diagnostic_Uart;
