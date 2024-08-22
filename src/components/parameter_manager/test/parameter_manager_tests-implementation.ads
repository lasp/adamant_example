--------------------------------------------------------------------------------
-- Parameter_Manager Tests Spec
--------------------------------------------------------------------------------

-- This is a unit test suite for the Parameter Manager component.
package Parameter_Manager_Tests.Implementation is

   -- Test data and state:
   type Instance is new Parameter_Manager_Tests.Base_Instance with private;
   type Class_Access is access all Instance'Class;

private
   -- Fixture procedures:
   overriding procedure Set_Up_Test (Self : in out Instance);
   overriding procedure Tear_Down_Test (Self : in out Instance);

   -- This unit test tests the nominal validation command.
   overriding procedure Test_Nominal_Validation (Self : in out Instance);
   -- This unit test tests the component's response to a failed validation.
   overriding procedure Test_Validation_Failure (Self : in out Instance);
   -- This unit test tests the component's response when the destination component
   -- does not respond to a validation command before a timeout occurs.
   overriding procedure Test_Validation_Timeout (Self : in out Instance);
   -- This unit test tests the nominal copy command.
   overriding procedure Test_Nominal_Copy (Self : in out Instance);
   -- This unit test tests the component's response to a failed parameter table copy.
   overriding procedure Test_Copy_Failure (Self : in out Instance);
   -- This unit test tests the component's response when the destination component
   -- does not respond to a copy command before a timeout occurs.
   overriding procedure Test_Copy_Timeout (Self : in out Instance);
   -- This unit test tests a command or memory region being dropped due to a full
   -- queue.
   overriding procedure Test_Full_Queue (Self : in out Instance);
   -- This unit test exercises that an invalid command throws the appropriate event.
   overriding procedure Test_Invalid_Command (Self : in out Instance);

   -- Test data and state:
   type Instance is new Parameter_Manager_Tests.Base_Instance with record
      null;
   end record;
end Parameter_Manager_Tests.Implementation;
