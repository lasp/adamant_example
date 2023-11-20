with Ada.Real_Time; use Ada.Real_Time;
with Pico_Example;
with Pico;
-- with RP.GPIO;      use RP.GPIO;
with RP.Clock;
with Pico_Uart;
with Last_Chance_Handler;
pragma Unreferenced (Last_Chance_Handler);

procedure Main is
   Wait_Time : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Microseconds (1000000);
   Start_Time : constant Ada.Real_Time.Time := Ada.Real_Time.Clock + Wait_Time;
begin
   -- Initialize the Pico internal clock:
   RP.Clock.Initialize (Pico.XOSC_Frequency);
   RP.Clock.Enable (RP.Clock.PERI);

   -- Initialize the UART. This needs to be done
   -- after clock initialization, so cannot be done
   -- at elaboration time:
   Pico_Uart.Initialize;

   -- Initialize the LED:
   -- RP.GPIO.Enable;
   -- Pico.LED.Configure (RP.GPIO.Output);
   -- Pico.LED.Set;

   -- Initialize the UART:
   -- Pico_Uart.Put_Line ("Starting...");

   -- Set up the assembly:
   -- Pico_Uart.Put_Line ("Init_Base");
   Pico_Example.Init_Base;
   -- Pico_Uart.Put_Line ("Set_Id_Bases");
   Pico_Example.Set_Id_Bases;
   -- Pico_Uart.Put_Line ("Connect_Components");
   Pico_Example.Connect_Components;
   -- Pico_Uart.Put_Line ("Init_Components");
   Pico_Example.Init_Components;

   -- Start the assembly:
   -- Pico_Uart.Put_Line ("delaying...");
   delay until Start_Time;
   -- Pico_Uart.Put_Line ("Start_Components");
   Pico_Example.Start_Components;
   -- Pico_Uart.Put_Line ("Set_Up_Components");
   Pico_Example.Set_Up_Components;

   -- Loop forever:
   loop
      delay until Clock + Milliseconds (500);
      -- Pico.LED.Toggle;
      -- Pico_Uart.Put_Line ("looping...");
   end loop;
end Main;
