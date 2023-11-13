--------------------------------------------------------------------------------
-- Oscillator Tests Spec
--------------------------------------------------------------------------------

-- This is a unit test suite for the oscillator component
package Oscillator_Tests.Implementation is

   -- Test data and state:
   type Instance is new Oscillator_Tests.Base_Instance with private;
   type Class_Access is access all Instance'Class;

private
   -- Fixture procedures:
   overriding procedure Set_Up_Test (Self : in out Instance);
   overriding procedure Tear_Down_Test (Self : in out Instance);

   -- This unit test excersizes the parameters within the component
   overriding procedure Test_Parameters (Self : in out Instance);

   -- Test data and state:
   type Instance is new Oscillator_Tests.Base_Instance with record
      null;
   end record;
end Oscillator_Tests.Implementation;
