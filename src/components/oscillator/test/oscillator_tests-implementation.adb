--------------------------------------------------------------------------------
-- Oscillator Tests Body
--------------------------------------------------------------------------------

with Parameter_Enums.Assertion;
use Parameter_Enums.Parameter_Update_Status;
use Parameter_Enums.Assertion;
with Parameter.Assertion; use Parameter.Assertion;

package body Oscillator_Tests.Implementation is

   -------------------------------------------------------------------------
   -- Fixtures:
   -------------------------------------------------------------------------

   overriding procedure Set_Up_Test (Self : in out Instance) is
   begin
      -- Allocate heap memory to component:
      Self.Tester.Init_Base (Queue_Size => Self.Tester.Component_Instance.Get_Max_Queue_Element_Size * 10);

      -- Make necessary connections between tester and component:
      Self.Tester.Connect;

      -- Call the component set up method that the assembly would normally call.
      Self.Tester.Component_Instance.Set_Up;
   end Set_Up_Test;

   overriding procedure Tear_Down_Test (Self : in out Instance) is
   begin
      -- Free component heap:
      Self.Tester.Final_Base;
   end Tear_Down_Test;

   -------------------------------------------------------------------------
   -- Tests:
   -------------------------------------------------------------------------

   -- This unit test exercises the parameters within the component
   overriding procedure Test_Parameters (Self : in out Instance) is
      T : Component.Oscillator.Implementation.Tester.Instance_Access renames Self.Tester;

      procedure Check_Parameters (Frequency : in Short_Float; Amplitude : in Short_Float; Offset : in Short_Float) is
         Param_Frequency : constant Parameter.T := T.Parameters.Frequency ((Value => Frequency));
         Param_Amplitude : constant Parameter.T := T.Parameters.Amplitude ((Value => Amplitude));
         Param_Offset : constant Parameter.T := T.Parameters.Offset ((Value => Offset));
         Param : Parameter.T;
      begin
         Parameter_Update_Status_Assert.Eq (T.Fetch_Parameter (T.Parameters.Get_Frequency_Id, Param), Success);
         Parameter_Assert.Eq (Param, Param_Frequency);
         Parameter_Update_Status_Assert.Eq (T.Fetch_Parameter (T.Parameters.Get_Amplitude_Id, Param), Success);
         Parameter_Assert.Eq (Param, Param_Amplitude);
         Parameter_Update_Status_Assert.Eq (T.Fetch_Parameter (T.Parameters.Get_Offset_Id, Param), Success);
         Parameter_Assert.Eq (Param, Param_Offset);
      end Check_Parameters;
   begin
      -- Make sure parameter values are set to their defaults:
      Check_Parameters (0.175, 5.0, 0.0);

      -- Set new parameters:
      Parameter_Update_Status_Assert.Eq (T.Stage_Parameter (T.Parameters.Frequency ((Value => 2.9))), Success);
      Parameter_Update_Status_Assert.Eq (T.Stage_Parameter (T.Parameters.Amplitude ((Value => 7.8))), Success);
      Parameter_Update_Status_Assert.Eq (T.Stage_Parameter (T.Parameters.Offset ((Value => 0.4))), Success);
      Parameter_Update_Status_Assert.Eq (T.Update_Parameters, Success);

      -- Make sure parameters changed:
      Check_Parameters (2.9, 7.8, 0.4);
   end Test_Parameters;

end Oscillator_Tests.Implementation;
