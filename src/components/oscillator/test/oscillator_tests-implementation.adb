--------------------------------------------------------------------------------
-- Oscillator Tests Body
--------------------------------------------------------------------------------

with Parameter_Enums.Assertion;
use Parameter_Enums.Parameter_Update_Status;
use Parameter_Enums.Assertion;
with Parameter.Assertion; use Parameter.Assertion;
with Parameter_Update;
with Packed_F32.Assertion; use Packed_F32.Assertion;

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

   -- This unit test exercises the implementable validation function
   overriding procedure Test_Parameter_Validation (Self : in out Instance) is
      T : Component.Oscillator.Implementation.Tester.Instance_Access renames Self.Tester;

      procedure Check_Frequency (Frequency : in Short_Float) is
         Param_Frequency : constant Parameter.T := T.Parameters.Frequency ((Value => Frequency));
         Param : Parameter.T;
      begin
         Parameter_Update_Status_Assert.Eq (T.Fetch_Parameter (T.Parameters.Get_Frequency_Id, Param), Success);
         Parameter_Assert.Eq (Param, Param_Frequency);
      end Check_Frequency;
      Test_Param_Update : Parameter_Update.T := (
         Table_Id => 1,
         Operation => Parameter_Enums.Parameter_Operation_Type.Update,
         Status => Success,
         Param => ((0, 0), [others => 0])
      );
   begin
      -- Validate the frequency:
      Test_Param_Update.Operation := Parameter_Enums.Parameter_Operation_Type.Validate;
      -- Set to a valid value and assert:
      Parameter_Update_Status_Assert.Eq (T.Stage_Parameter (T.Parameters.Frequency ((Value => 5.1))), Success);
      T.Component_Instance.Parameter_Update_T_Modify (Test_Param_Update);
      Parameter_Update_Status_Assert.Eq (Test_Param_Update.Status, Success);

      -- Send a tick:
      Self.Tester.Tick_T_Send ((Time => (0, 0), Count => 0));
      -- Fetch should return the active parameter, since we haven't sent update.
      Check_Frequency (0.175);
      -- Make sure working frequency parameter hasn't changed from default:
      Packed_F32_Assert.Eq (T.Get_Component_Frequency, (Value => 0.175));

      -- Update the frequency:
      Test_Param_Update.Operation := Parameter_Enums.Parameter_Operation_Type.Update;
      T.Component_Instance.Parameter_Update_T_Modify (Test_Param_Update);
      -- Check status:
      Parameter_Update_Status_Assert.Eq (Test_Param_Update.Status, Success);
      -- Fetch should return the staged parameter, since we have sent update.
      Check_Frequency (5.1);
      -- Make sure working frequency parameter still hasn't changed from default:
      Packed_F32_Assert.Eq (T.Get_Component_Frequency, (Value => 0.175));
      -- Send a tick to update parameters:
      Self.Tester.Tick_T_Send ((Time => (0, 0), Count => 0));
      -- Make sure frequency parameter changed:
      Packed_F32_Assert.Eq (T.Get_Component_Frequency, (Value => 5.1));
      Check_Frequency (5.1);

      -- Set to an invalid value (arbitrarily forced 999.0 invalid in implementation)
      -- Validate a parameter:
      Test_Param_Update.Operation := Parameter_Enums.Parameter_Operation_Type.Validate;
      -- assert:
      Parameter_Update_Status_Assert.Eq (T.Stage_Parameter (T.Parameters.Frequency ((Value => 999.0))), Success);
      T.Component_Instance.Parameter_Update_T_Modify (Test_Param_Update);
      Parameter_Update_Status_Assert.Eq (Test_Param_Update.Status, Validation_Error);
      -- Fetch should return the working parameter.
      Check_Frequency (5.1);

      -- Send a tick:
      Self.Tester.Tick_T_Send ((Time => (0, 0), Count => 0));
      -- Fetch should return the working parameter.
      Check_Frequency (5.1);
      -- Make sure working frequency parameter hasn't changed:
      Packed_F32_Assert.Eq (T.Get_Component_Frequency, (Value => 5.1));

      -- Update the frequency:
      Test_Param_Update.Operation := Parameter_Enums.Parameter_Operation_Type.Update;
      T.Component_Instance.Parameter_Update_T_Modify (Test_Param_Update);
      -- Check status:
      Parameter_Update_Status_Assert.Eq (Test_Param_Update.Status, Success);
      -- Fetch should return the staged parameter.
      Check_Frequency (999.0);
      -- Send a tick to update parameters:
      Self.Tester.Tick_T_Send ((Time => (0, 0), Count => 0));
      -- Make sure frequency parameter changed:
      Packed_F32_Assert.Eq (T.Get_Component_Frequency, (Value => 999.0));
      -- Fetch should return the working parameter.
      Check_Frequency (999.0);
   end Test_Parameter_Validation;

end Oscillator_Tests.Implementation;
