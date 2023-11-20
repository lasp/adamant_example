with Basic_Types;

package Pico_Uart is

   -- Set up the UART with the following default configuration:
   --
   -- GP16      = TX
   -- GP17      = RX
   -- Baud      = 115200
   -- Parity    = False
   -- Stop bits = 1
   -- Word size = 8
   --
   procedure Initialize;

   -- Transmit raw data bytes over the UART:
   procedure Send_Byte_Array (To_Send : in Basic_Types.Byte_Array);

   -- Transmit a string over the UART. This appends a return line to
   -- the transmitted string.
   procedure Put_Line (To_Send : in String);

   -- Receive a byte from UART. This will block until a byte is
   -- received or an error is encountered. It spins on the serial,
   -- so if you use this function make sure it is in the lowest
   -- priority task on the system.
   function Receive_Byte return Basic_Types.Byte;

end Pico_Uart;
