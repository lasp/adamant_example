--------------------------------------------------------------------------------
-- Counter Tests Body
--------------------------------------------------------------------------------

-- Custom Includes:
with Component.Counter.Implementation.Tester;
with Counter_Commands;
with Interfaces; use Interfaces;
with Basic_Assertions; use Basic_Assertions;
with Operands.Assertion; use Operands.Assertion;
with Packed_U32.Assertion; use Packed_U32.Assertion;
with AUnit.Assertions; use AUnit.Assertions;

package body Tests.Implementation is

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

   -- This unit test excersizes the counter component and makes sure it, well, counts!
   overriding procedure Test_1 (Self : in out Instance) is
      Value : Packed_U32.T;
   begin
      -- Invoke the schedule port on the counter and make sure it sends out data products:
      Self.Tester.Tick_T_Send ((Time => (1, 1), Count => 1));
      Assert (Self.Tester.Check_Count (1), "Count = 1 failed.");
      Self.Tester.Tick_T_Send ((Time => (1, 1), Count => 2));
      Assert (Self.Tester.Check_Count (2), "Count = 2 failed.");
      Self.Tester.Tick_T_Send ((Time => (1, 1), Count => 3));
      Assert (Self.Tester.Check_Count (3), "Count = 3 failed.");

      -- Check history and make sure expected data product was sent out by component:
      Natural_Assert.Eq (Self.Tester.Packet_T_Recv_Sync_History.Get_Count, 3);
      Natural_Assert.Eq (Self.Tester.Counter_Value_History.Get_Count, 3);
      Value := Self.Tester.Counter_Value_History.Get (1);
      Packed_U32_Assert.Eq (Value, (Value => 1));
      Value := Self.Tester.Counter_Value_History.Get (2);
      Packed_U32_Assert.Eq (Value, (Value => 2));
      Value := Self.Tester.Counter_Value_History.Get (3);
      Packed_U32_Assert.Eq (Value, (Value => 3));
   end Test_1;

   -- This unit test tests all the commands for the counter component
   overriding procedure Test_Commands (Self : in out Instance) is
      -- Helper function which sends arbitraty numbers times.
      procedure Go is
      begin
         Self.Tester.Tick_T_Send ((Time => (1, 1), Count => 1));
      end Go;

      -- Helper function which checks 3 values in the history
      procedure Check_Val (Val : in Unsigned_32) is
         Value : Packed_U32.T;
      begin
         Assert (Self.Tester.Check_Count (Val), "Count = " & Unsigned_32'Image (Val) & " failed.");
         Value := Self.Tester.Counter_Value_History.Get (1);
         Packed_U32_Assert.Eq (Value, (Value => Val));
      end Check_Val;

      Commands : Counter_Commands.Instance renames Self.Tester.Commands;
   begin
      -- Set Count:
      Self.Tester.Packet_T_Recv_Sync_History.Clear;
      Self.Tester.Counter_Value_History.Clear;
      Natural_Assert.Eq (Self.Tester.Set_Count_Command_Received_History.Get_Count, 0);
      Self.Tester.Command_T_Send (Commands.Set_Count ((Value => 10)));
      Assert (Self.Tester.Check_Count (0), "Count = 1 failed.");
      Go;
      Check_Val (11);
      Natural_Assert.Eq (Self.Tester.Set_Count_Command_Received_History.Get_Count, 1);
      Packed_U32_Assert.Eq (Self.Tester.Set_Count_Command_Received_History.Get (1), (Value => 10));

      -- Set Count Add:
      Self.Tester.Packet_T_Recv_Sync_History.Clear;
      Self.Tester.Counter_Value_History.Clear;
      Natural_Assert.Eq (Self.Tester.Set_Count_Add_Command_Received_History.Get_Count, 0);
      Self.Tester.Command_T_Send (Commands.Set_Count_Add (Arg => (10, 11)));
      Assert (Self.Tester.Check_Count (11), "Count = 11 failed.");
      Go;
      Check_Val (22);
      Natural_Assert.Eq (Self.Tester.Set_Count_Add_Command_Received_History.Get_Count, 1);
      Operands_Assert.Eq (Self.Tester.Set_Count_Add_Command_Received_History.Get (1), (10, 11));

      -- Reset:
      Self.Tester.Packet_T_Recv_Sync_History.Clear;
      Self.Tester.Counter_Value_History.Clear;
      Natural_Assert.Eq (Self.Tester.Reset_Count_Command_Received_History.Get_Count, 0);
      Self.Tester.Command_T_Send (Commands.Reset_Count);
      Assert (Self.Tester.Check_Count (22), "Count = 0 failed.");
      Go;
      Check_Val (1);
      Natural_Assert.Eq (Self.Tester.Reset_Count_Command_Received_History.Get_Count, 1);
   end Test_Commands;

end Tests.Implementation;
