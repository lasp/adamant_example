with RP.GPIO;      use RP.GPIO;
with Pico;

package body Counter_Action is

   procedure Do_Action (Count : in Unsigned_32) is
      Ignore : Unsigned_32 renames Count;
   begin
      -- Toggle the LED on the Raspberry Pi Pico.
      Pico.LED.Toggle;
   end Do_Action;

begin
   -- Make sure LED is enabled on the the Raspberry Pi Pico
   -- during elaboration.
   RP.GPIO.Enable;
   Pico.LED.Configure (RP.GPIO.Output);
   Pico.LED.Set;
end Counter_Action;
