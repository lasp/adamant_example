--------------------------------------------------------------------------------
-- Counter Tests Spec
--------------------------------------------------------------------------------

-- This is a unit test suite for the counter component
package Tests.Implementation is

   -- Test data and state:
   type Instance is new Tests.Base_Instance with private;
   type Class_Access is access all Instance'Class;

private
   -- Fixture procedures:
   overriding procedure Set_Up_Test (Self : in out Instance);
   overriding procedure Tear_Down_Test (Self : in out Instance);

   -- This unit test excersizes the counter component and makes sure it, well, counts!
   overriding procedure Test_1 (Self : in out Instance);
   -- This unit test tests all the commands for the counter component
   overriding procedure Test_Commands (Self : in out Instance);

   -- Test data and state:
   type Instance is new Tests.Base_Instance with record
      null;
   end record;
end Tests.Implementation;
