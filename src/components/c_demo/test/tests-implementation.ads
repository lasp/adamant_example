--------------------------------------------------------------------------------
-- C_Demo Tests Spec
--------------------------------------------------------------------------------

-- This is a unit test suite for the c_demo component.
package Tests.Implementation is

   -- Test data and state:
   type Instance is new Tests.Base_Instance with private;
   type Class_Access is access all Instance'Class;

private
   -- Fixture procedures:
   overriding procedure Set_Up_Test (Self : in out Instance);
   overriding procedure Tear_Down_Test (Self : in out Instance);

   -- This unit test exercises the c_demo component and makes sure it works
   -- correctly.
   overriding procedure Test_C (Self : in out Instance);

   -- Test data and state:
   type Instance is new Tests.Base_Instance with record
      null;
   end record;
end Tests.Implementation;
