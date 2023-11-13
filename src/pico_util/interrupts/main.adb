with Rp.Gpio; use Rp.Gpio;
--with RP.GPIO.Interrupts;
with Rp.Clock;
with Pico;

with Handlers;

procedure Main is
begin
   Rp.Clock.Initialize (Pico.Xosc_Frequency);
   Rp.Gpio.Enable;

    --   GP9 is connected to a normally open button that connects to GND when pressed
    --   debouncing is an exercise left to the reader
   Pico.Gp9.Configure (Input, Pull_Up);

    -- RP.GPIO.Interrupts.Attach_Handler (Pico.GP9, Handlers.Toggle_LED'Access);
   Pico.Gp9.Enable_Interrupt (Falling_Edge);

   Pico.Led.Configure (Output);
   Pico.Led.Set;

   loop
      null;
   end loop;
end Main;
