with HAL.UART; use HAL.UART;
with RP.Device; use RP.Device;
with RP.GPIO; use RP.GPIO;
with RP.UART;
with Pico;

package body Pico_Uart is

   Test_Error : exception;
   The_UART : RP.UART.UART_Port renames RP.Device.UART_0;

   procedure Initialize is
      Uart_Tx : RP.GPIO.GPIO_Point renames Pico.GP16; -- White wire
      Uart_Rx : RP.GPIO.GPIO_Point renames Pico.GP17; -- Green wire
   begin
      -- I don't know if the pull up is needed, but it doesn't hurt?
      Uart_Tx.Configure (Output, Pull_Up, RP.GPIO.UART);
      Uart_Rx.Configure (Input, Floating, RP.GPIO.UART);
      The_UART.Configure
         (Config =>
            (Baud      => 115_200,
             Word_Size => 8,
             Parity    => False,
             Stop_Bits => 1,
             others    => <>));
   end Initialize;

   -- Byte arrays don't have a "scalar storage order" since they are an array of single byte
   -- items. So this warning doesn't apply. We can safely overlay a byte array with any type
   -- no matter the underlying scalar storage order.
   pragma Warnings (Off, "overlay changes scalar storage order");

   procedure Send_Byte_Array (To_Send : in Basic_Types.Byte_Array) is
      To_Send_Bytes : UART_Data_8b (1 .. To_Send'Length) with Import, Convention => Ada, Address => To_Send'Address;
      Status : UART_Status;
   begin
      The_UART.Transmit (To_Send_Bytes, Status, Timeout => 0);
      if Status /= Ok then
         raise Test_Error with "UART transmit failed with status " & Status'Image;
      end if;
   end Send_Byte_Array;

   procedure Put_Line (To_Send : in String) is
      To_Send_El : constant String := To_Send & ASCII.CR & ASCII.LF;
      To_Send_Array : Basic_Types.Byte_Array (0 .. To_Send_El'Length - 1) with Import, Convention => Ada, Address => To_Send_El'Address;
   begin
      Send_Byte_Array (To_Send_Array);
   end Put_Line;

   function Receive_Byte return Basic_Types.Byte is
      Byte : UART_Data_8b (0 .. 0);
      To_Return : Basic_Types.Byte with Import, Convention => Ada, Address => Byte'Address;
      Status : UART_Status;
   begin
      The_UART.Receive (Byte, Status, Timeout => 0);
      case Status is
         when Err_Error =>
            raise Test_Error with "Echo receive failed with status " & Status'Image;
         when Err_Timeout =>
            raise Test_Error with "Unexpected Err_Timeout with timeout disabled!";
         when Busy =>
            --   Busy indicates a Break condition- RX held low for a full
            --   word time. This may be detected unintentionally if a
            --   transmitter is not connected. Break is used by some
            --   protocols (eg. LIN bus) to indicate the end of a frame.
            --
            --   For this example, we just ignore it.
            null;
         when Ok =>
            null;
      end case;
      return To_Return;
   end Receive_Byte;

   pragma Warnings (On, "overlay changes scalar storage order");

end Pico_Uart;
