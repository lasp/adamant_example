with RP.Device;    use RP.Device;
with RP.GPIO;       use RP.GPIO;
with RP.ADC;         use RP.ADC;
with RP.Clock;
with Pico;
with Pico_Uart;

procedure Main is
   Vsys : Microvolts;
begin
   -- Initialize the Pico internal clock:
   RP.Clock.Initialize (Pico.XOSC_Frequency);
   RP.Clock.Enable (RP.Clock.PERI);

   -- Initialize the UART. This needs to be done
   -- after clock initialization, so cannot be done
   -- at elaboration time:
   Pico_Uart.Initialize;

   --   The Pico's power regulator dynamically adjusts it's switching frequency
   --   based on load. This introduces noise that can affect ADC readings. The
   --   Pico datasheet recommends setting Power Save pin high while performing
   --   ADC measurements to minimize this noise, at the expense of higher power
   --   consumption.
   Pico.SMPS_PS.Configure (Output, Pull_Up);
   Pico.SMPS_PS.Clear;

   RP.ADC.Enable;
   RP.ADC.Configure (0);
   RP.ADC.Configure (Pico.VSYS_DIV_3);

   RP.Device.Timer.Enable;
   loop
      Pico.SMPS_PS.Set;
      Vsys := RP.ADC.Read_Microvolts (Pico.VSYS_DIV_3) * 3;
      Pico_Uart.Put_Line ("Channel 0:   " & RP.ADC.Read_Microvolts (0)'Image & "μv");
      Pico_Uart.Put_Line ("VSYS:          " & Vsys'Image & "μv");
      Pico_Uart.Put_Line ("Temperature:" & RP.ADC.Temperature'Image & "°C");
      Pico.SMPS_PS.Clear;
      RP.Device.Timer.Delay_Milliseconds (1000);
   end loop;
end Main;
