--------------------------------------------------------------------------------
-- Adc_Data_Collector Component Implementation Body
--------------------------------------------------------------------------------

with RP.Device;    use RP.Device;
with RP.GPIO;       use RP.GPIO;
with RP.ADC;         use RP.ADC;
with Pico;

package body Component.Adc_Data_Collector.Implementation is

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The schedule invokee connector
   overriding procedure Tick_T_Recv_Sync (Self : in out Instance; Arg : in Tick.T) is
      Ignore : Tick.T renames Arg;
      The_Time : constant Sys_Time.T := Self.Sys_Time_T_Get;
   begin
      Pico.SMPS_PS.Set;

      -- Read ADC and produce data products:
      Self.Data_Product_T_Send (Self.Data_Products.Channel_0 (The_Time, (Value => Integer (RP.ADC.Read_Microvolts (0)))));
      Self.Data_Product_T_Send (Self.Data_Products.Vsys (The_Time, (Value => Integer (RP.ADC.Read_Microvolts (Pico.VSYS_DIV_3) * 3))));
      Self.Data_Product_T_Send (Self.Data_Products.Temperature (The_Time, (Value => Integer (RP.ADC.Temperature))));

      Pico.SMPS_PS.Clear;
   end Tick_T_Recv_Sync;

begin
   -- Setup the pico ADC at elaboration time.
   --
   -- The Pico's power regulator dynamically adjusts it's switching frequency
   -- based on load. This introduces noise that can affect ADC readings. The
   -- Pico datasheet recommends setting Power Save pin high while performing
   -- ADC measurements to minimize this noise, at tne expense of higher power
   -- consumption.
   Pico.SMPS_PS.Configure (Output, Pull_Up);
   Pico.SMPS_PS.Clear;

   RP.ADC.Enable;
   RP.ADC.Configure (0);
   RP.ADC.Configure (Pico.VSYS_DIV_3);
end Component.Adc_Data_Collector.Implementation;
