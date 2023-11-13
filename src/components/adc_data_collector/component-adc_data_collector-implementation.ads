--------------------------------------------------------------------------------
-- Adc_Data_Collector Component Implementation Spec
--------------------------------------------------------------------------------

-- Includes:
with Tick;

-- This is the ADC data collector component. It periodically collects data values from the Raspberry Pi Pico's ADC and reports them as data products.
package Component.Adc_Data_Collector.Implementation is

   -- The component class instance record:
   type Instance is new Adc_Data_Collector.Base_Instance with private;

private

   -- The component class instance record:
   type Instance is new Adc_Data_Collector.Base_Instance with record
      null;
   end record;

   ---------------------------------------
   -- Set Up Procedure
   ---------------------------------------
   -- Null method which can be implemented to provide some component
   -- set up code. This method is generally called by the assembly
   -- main.adb after all component initialization and tasks have been started.
   -- Some activities need to only be run once at startup, but cannot be run
   -- safely until everything is up and running, ie. command registration, initial
   -- data product updates. This procedure should be implemented to do these things
   -- if necessary.
   overriding procedure Set_Up (Self : in out Instance) is null;

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The schedule invokee connector
   overriding procedure Tick_T_Recv_Sync (Self : in out Instance; Arg : in Tick.T);

   ---------------------------------------
   -- Invoker connector primitives:
   ---------------------------------------
   -- This procedure is called when a Data_Product_T_Send message is dropped due to a full queue.
   overriding procedure Data_Product_T_Send_Dropped (Self : in out Instance; Arg : in Data_Product.T) is null;

end Component.Adc_Data_Collector.Implementation;
