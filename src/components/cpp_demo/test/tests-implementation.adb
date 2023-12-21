--------------------------------------------------------------------------------
-- Cpp_Demo Tests Body
--------------------------------------------------------------------------------

with Packed_U32.Assertion; use Packed_U32.Assertion;
with Basic_Assertions; use Basic_Assertions;

package body Tests.Implementation is

   -------------------------------------------------------------------------
   -- Fixtures:
   -------------------------------------------------------------------------

   overriding procedure Set_Up_Test (Self : in out Instance) is
   begin
      -- Allocate heap memory to component:
      Self.Tester.Init_Base;

      -- Make necessary connections between tester and component:
      Self.Tester.Connect;

      -- Call component init here.
      Self.Tester.Component_Instance.Init (Limit => 3);

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

   -- This unit test exercises the c_demo component and makes sure it works
   -- correctly.
   overriding procedure Test_Cpp (Self : in out Instance) is
      T : Component.Cpp_Demo.Implementation.Tester.Instance_Access renames Self.Tester;
   begin
      -- Send tick and verify increment
      T.Tick_T_Send ((Time => (1, 1), Count => 1));
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 1);
      Natural_Assert.Eq (T.Current_Count_History.Get_Count, 1);
      Packed_U32_Assert.Eq (T.Current_Count_History.Get (1), (Value => 1));

      -- Send tick and verify increment
      T.Tick_T_Send ((Time => (1, 1), Count => 2));
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 2);
      Natural_Assert.Eq (T.Current_Count_History.Get_Count, 2);
      Packed_U32_Assert.Eq (T.Current_Count_History.Get (2), (Value => 2));

      -- Send tick and verify increment
      T.Tick_T_Send ((Time => (1, 1), Count => 2));
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 3);
      Natural_Assert.Eq (T.Current_Count_History.Get_Count, 3);
      Packed_U32_Assert.Eq (T.Current_Count_History.Get (3), (Value => 3));

      -- Send tick and verify increment
      T.Tick_T_Send ((Time => (1, 1), Count => 2));
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 4);
      Natural_Assert.Eq (T.Current_Count_History.Get_Count, 4);
      Packed_U32_Assert.Eq (T.Current_Count_History.Get (4), (Value => 0));
   end Test_Cpp;

end Tests.Implementation;
