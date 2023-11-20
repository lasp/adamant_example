with RP.GPIO;      use RP.GPIO;
with RP.Clock;
with Ada.Real_Time; use Ada.Real_Time;
with Pico;
with RP.Device;   use RP.Device;
with RP.UART;
with HAL.UART;    use HAL.UART;

--
-- This hello world program blinks the LED on a Raspberry Pi Pico and
-- prints "Hello, Pico!" to UART0 on GP16 (TX) and GP17 (RX).
--
procedure Main is
   Test_Error : exception;
   The_UART : RP.UART.UART_Port renames RP.Device.UART_0;
   Uart_Tx   : RP.GPIO.GPIO_Point renames Pico.GP16; -- White wire
   Uart_Rx   : RP.GPIO.GPIO_Point renames Pico.GP17; -- Green wire
   Status    : UART_Status;

   procedure Send_Hello is
      Hello          : constant String := "Hello, Pico!" & ASCII.CR & ASCII.LF;
      Hello_Bytes : UART_Data_8b (1 .. Hello'Length);
   begin
      for I in Hello'Range loop
         Hello_Bytes (I) := Character'Pos (Hello (I));
      end loop;

      The_UART.Transmit (Hello_Bytes, Status);
      if Status /= Ok then
         raise Test_Error with "Send_Hello transmit failed with status " & Status'Image;
      end if;
   end Send_Hello;

   Period   : constant Time_Span := Milliseconds (250);
   Release : Time;
begin
   RP.Clock.Initialize (Pico.XOSC_Frequency);
   RP.Clock.Enable (RP.Clock.PERI);
   -- RP.Device.Timer.Enable;
   RP.GPIO.Enable;
   Pico.LED.Configure (RP.GPIO.Output);
   Pico.LED.Set;

   -- I don't know if the pull up is needed, but it doesn't hurt?
   Uart_Tx.Configure (Output, Pull_Up, RP.GPIO.UART);
   Uart_Rx.Configure (Input, Floating, RP.GPIO.UART);
   The_UART.Configure
      (Config =>
         (Baud         => 115_200,
          Word_Size => 8,
          Parity      => False,
          Stop_Bits => 1,
          others      => <>));

   --   Compute the first release time
   Release := Clock + Period;
   loop
      delay until Release;
      Pico.LED.Toggle;
      --delay 0.2;

      -- Next release time
      Release := Release + Period;
      Send_Hello;
      -- RP.Device.Timer.Delay_Milliseconds (250);
   end loop;
end Main;
