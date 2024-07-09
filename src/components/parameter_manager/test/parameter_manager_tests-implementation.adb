--------------------------------------------------------------------------------
-- Parameter_Manager Tests Body
--------------------------------------------------------------------------------

with Ada.Real_Time;
with Basic_Assertions; use Basic_Assertions;
with Command_Response.Assertion; use Command_Response.Assertion;
with Command_Enums; use Command_Enums.Command_Response_Status;
with Command;
with Interfaces; use Interfaces;
with Memory_Region;
with Parameters_Memory_Region.Assertion; use Parameters_Memory_Region.Assertion;
with Parameters_Memory_Region_Release.Assertion; use Parameters_Memory_Region_Release.Assertion;
with Parameter_Enums;
with Parameter_Manager_Enums; use Parameter_Manager_Enums.Parameter_Table_Copy_Type;
with Basic_Types;
with Invalid_Command_Info.Assertion; use Invalid_Command_Info.Assertion;
with Command_Header.Assertion; use Command_Header.Assertion;
with Packed_Parameter_Table_Copy_Type.Assertion; use Packed_Parameter_Table_Copy_Type.Assertion;
use Parameter_Enums.Parameter_Table_Update_Status;
use Parameter_Enums.Parameter_Table_Operation_Type;

package body Parameter_Manager_Tests.Implementation is

   -- Globals to control task behavior. There is no thread safety here... but this
   -- is testing code.
   Task_Send_Response : Boolean := False;
   Task_Send_Response_Twice : Boolean := False;
   Task_Send_Timeout : Boolean := False;
   Task_Response : Parameter_Enums.Parameter_Table_Update_Status.E := Parameter_Enums.Parameter_Table_Update_Status.Success;
   Task_Response2 : Parameter_Enums.Parameter_Table_Update_Status.E := Parameter_Enums.Parameter_Table_Update_Status.Success;

   -------------------------------------------------------------------------
   -- Fixtures:
   -------------------------------------------------------------------------

   overriding procedure Set_Up_Test (Self : in out Instance) is
   begin
      -- Reset globals:
      Task_Send_Response := False;
      Task_Send_Response_Twice := False;
      Task_Send_Timeout := False;
      Task_Response := Parameter_Enums.Parameter_Table_Update_Status.Success;
      Task_Response2 := Parameter_Enums.Parameter_Table_Update_Status.Success;

      -- Allocate heap memory to component:
      Self.Tester.Init_Base (Queue_Size => Self.Tester.Component_Instance.Get_Max_Queue_Element_Size * 3);

      -- Make necessary connections between tester and component:
      Self.Tester.Connect;

      -- Call component init here.
      Self.Tester.Component_Instance.Init (Parameter_Table_Length => 100, Ticks_Until_Timeout => 3);

      -- Call the component set up method that the assembly would normally call.
      Self.Tester.Component_Instance.Set_Up;
   end Set_Up_Test;

   overriding procedure Tear_Down_Test (Self : in out Instance) is
   begin
      -- Free component heap:
      Self.Tester.Final_Base;
   end Tear_Down_Test;

   -------------------------------------------------------------------------
   -- Task used to simulate downstream components:
   -------------------------------------------------------------------------

   procedure Sleep (Ms : in Natural := 5) is
      use Ada.Real_Time;
      Sleep_Time : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (Ms);
      Wake_Time : constant Ada.Real_Time.Time := Ada.Real_Time.Clock + Sleep_Time;
   begin
      delay until Wake_Time;
   end Sleep;

   -- Task type for active components:
   type Boolean_Access is access all Boolean;
   task type Simulator_Task (
      Class_Self : Class_Access;
      Task_Exit : Boolean_Access
   );

   Sim_Bytes : aliased Basic_Types.Byte_Array := [0 .. 99 => 12];
   Sim_Bytes_2 : aliased Basic_Types.Byte_Array := [0 .. 99 => 11];

   task body Simulator_Task is
      Ignore : Natural;
      Count : Natural := 0;
      Tick_Count : Natural := 0;
   begin
      while not Task_Exit.all and then Count < 2000 loop

         -- Increment variables:
         Count := Count + 1;

         if Task_Send_Response then
            -- Send a valid response:
            Sleep (4);
            Class_Self.all.Tester.Parameters_Memory_Region_Release_T_Send ((
               Region => (Address => Sim_Bytes'Address, Length => Sim_Bytes'Length),
               Status => Task_Response
            ));
            Task_Send_Response := False;
         elsif Task_Send_Response_Twice then
            -- Send a valid response:
            Sleep (4);
            Class_Self.all.Tester.Parameters_Memory_Region_Release_T_Send ((
               Region => (Address => Sim_Bytes_2'Address, Length => Sim_Bytes_2'Length),
               Status => Task_Response2
            ));
            Task_Send_Response_Twice := False;
            Task_Send_Response := True;
         elsif Task_Send_Timeout then
            -- Send a valid response:
            Sleep (4);
            Class_Self.all.Tester.Timeout_Tick_Send (((0, 0), 0));
            Tick_Count := Tick_Count + 1;
            if Tick_Count > 4 then
               Tick_Count := 0;
               Task_Send_Timeout := False;
            end if;
         else
            -- Sleep:
            Sleep (2);
         end if;
      end loop;
   end Simulator_Task;

   -------------------------------------------------------------------------
   -- Tests:
   -------------------------------------------------------------------------
   overriding procedure Test_Nominal_Copy_Default_To_Working (Self : in out Instance) is
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Task_Exit : aliased Boolean := False;
      Sim_Task : Simulator_Task (Self'Unchecked_Access, Task_Exit'Unchecked_Access);
   begin
      -- Send copy command:
      T.Command_T_Send (T.Commands.Copy_Parameter_Table ((Copy_Type => Default_To_Working)));

      -- Execute the command and tell the task to respond.
      Task_Send_Response_Twice := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Copy to working should have occurred now. Check data:
      Natural_Assert.Eq (T.Default_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      Parameters_Memory_Region_Assert.Eq (
         T.Default_Parameters_Memory_Region_Recv_Sync_History.Get (1),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Get)
      );
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      Parameters_Memory_Region_Assert.Eq (
         T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (1),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Set)
      );

      -- Check region data:
      declare
         Region : constant Memory_Region.T := T.Get_Parameter_Bytes_Region;
         subtype Safe_Byte_Array_Type is Basic_Types.Byte_Array (0 .. Region.Length - 1);
         Safe_Byte_Array : Safe_Byte_Array_Type with Import, Convention => Ada, Address => Region.Address;
      begin
         Byte_Array_Assert.Eq (Safe_Byte_Array, T.Default);
      end;

      -- Check events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 2);
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 1);
      Packed_Parameter_Table_Copy_Type_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get (1), (Copy_Type => Default_To_Working));
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 1);
      Packed_Parameter_Table_Copy_Type_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get (1), (Copy_Type => Default_To_Working));

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Copy_Parameter_Table_Id, Status => Success));

      -- Kill our helper task.
      Task_Exit := True;
   end Test_Nominal_Copy_Default_To_Working;

   overriding procedure Test_Nominal_Copy_Working_To_Default (Self : in out Instance) is
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Task_Exit : aliased Boolean := False;
      Sim_Task : Simulator_Task (Self'Unchecked_Access, Task_Exit'Unchecked_Access);
   begin
      -- Send copy command:
      T.Command_T_Send (T.Commands.Copy_Parameter_Table ((Copy_Type => Working_To_Default)));

      -- Execute the command and tell the task to respond.
      Task_Send_Response_Twice := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Copy to working should have occurred now. Check data:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      Parameters_Memory_Region_Assert.Eq (
         T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (1),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Get)
      );
      Natural_Assert.Eq (T.Default_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      Parameters_Memory_Region_Assert.Eq (
         T.Default_Parameters_Memory_Region_Recv_Sync_History.Get (1),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Set)
      );

      -- Check region data:
      declare
         Region : constant Memory_Region.T := T.Get_Parameter_Bytes_Region;
         subtype Safe_Byte_Array_Type is Basic_Types.Byte_Array (0 .. Region.Length - 1);
         Safe_Byte_Array : Safe_Byte_Array_Type with Import, Convention => Ada, Address => Region.Address;
      begin
         Byte_Array_Assert.Eq (Safe_Byte_Array, T.Working);
      end;

      -- Check events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 2);
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 1);
      Packed_Parameter_Table_Copy_Type_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get (1), (Copy_Type => Working_To_Default));
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 1);
      Packed_Parameter_Table_Copy_Type_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get (1), (Copy_Type => Working_To_Default));

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Copy_Parameter_Table_Id, Status => Success));

      -- Kill our helper task.
      Task_Exit := True;
   end Test_Nominal_Copy_Working_To_Default;

   overriding procedure Test_Copy_Failure (Self : in out Instance) is
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Task_Exit : aliased Boolean := False;
      Sim_Task : Simulator_Task (Self'Unchecked_Access, Task_Exit'Unchecked_Access);
   begin
      -- Set task response to something other than success:
      Task_Response := Parameter_Enums.Parameter_Table_Update_Status.Parameter_Error;

      -- Send copy command:
      T.Command_T_Send (T.Commands.Copy_Parameter_Table ((Copy_Type => Working_To_Default)));

      -- Execute the command and tell the task to respond.
      Task_Send_Response := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Copy from working should have occurred now. Check data:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      Parameters_Memory_Region_Assert.Eq (
         T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (1),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Get)
      );
      -- No copy to default:
      Natural_Assert.Eq (T.Default_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);

      -- Check events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 2);
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 1);
      Packed_Parameter_Table_Copy_Type_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get (1), (Copy_Type => Working_To_Default));
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 0);
      Natural_Assert.Eq (T.Parameter_Table_Copy_Failure_History.Get_Count, 1);
      Parameters_Memory_Region_Release_Assert.Eq (T.Parameter_Table_Copy_Failure_History.Get (1), (
         Region => (Address => Sim_Bytes'Address, Length => Sim_Bytes'Length),
         Status => Parameter_Enums.Parameter_Table_Update_Status.Parameter_Error
      ));

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Copy_Parameter_Table_Id, Status => Failure));

      -- Set task response 2 to something other than success:
      Task_Response := Parameter_Enums.Parameter_Table_Update_Status.Crc_Error;
      Task_Response2 := Parameter_Enums.Parameter_Table_Update_Status.Success;

      -- Send copy command:
      T.Command_T_Send (T.Commands.Copy_Parameter_Table ((Copy_Type => Working_To_Default)));

      -- Execute the command and tell the task to respond.
      Task_Send_Response_Twice := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Copy from working should have occurred now. Check data:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 2);
      Parameters_Memory_Region_Assert.Eq (
         T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (2),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Get)
      );
      -- Copy to default:
      Natural_Assert.Eq (T.Default_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      Parameters_Memory_Region_Assert.Eq (
         T.Default_Parameters_Memory_Region_Recv_Sync_History.Get (1),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Set)
      );

      -- Check events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 4);
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 2);
      Packed_Parameter_Table_Copy_Type_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get (2), (Copy_Type => Working_To_Default));
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 0);
      Natural_Assert.Eq (T.Parameter_Table_Copy_Failure_History.Get_Count, 2);
      Parameters_Memory_Region_Release_Assert.Eq (T.Parameter_Table_Copy_Failure_History.Get (2), (
         Region => (Address => Sim_Bytes'Address, Length => Sim_Bytes'Length),
         Status => Parameter_Enums.Parameter_Table_Update_Status.Crc_Error
      ));

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 2);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (2), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Copy_Parameter_Table_Id, Status => Failure));

      -- Set task response 2 to something other than success:
      Task_Response := Parameter_Enums.Parameter_Table_Update_Status.Crc_Error;
      Task_Response2 := Parameter_Enums.Parameter_Table_Update_Status.Success;

      -- Send copy command:
      T.Command_T_Send (T.Commands.Copy_Parameter_Table ((Copy_Type => Default_To_Working)));

      -- Execute the command and tell the task to respond.
      Task_Send_Response_Twice := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Copy from working should have occurred now. Check data:
      Natural_Assert.Eq (T.Default_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 2);
      Parameters_Memory_Region_Assert.Eq (
         T.Default_Parameters_Memory_Region_Recv_Sync_History.Get (2),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Get)
      );
      -- Copy to default:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 3);
      Parameters_Memory_Region_Assert.Eq (
         T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (3),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Set)
      );

      -- Check events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 6);
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 3);
      Packed_Parameter_Table_Copy_Type_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get (3), (Copy_Type => Default_To_Working));
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 0);
      Natural_Assert.Eq (T.Parameter_Table_Copy_Failure_History.Get_Count, 3);
      Parameters_Memory_Region_Release_Assert.Eq (T.Parameter_Table_Copy_Failure_History.Get (3), (
         Region => (Address => Sim_Bytes'Address, Length => Sim_Bytes'Length),
         Status => Parameter_Enums.Parameter_Table_Update_Status.Crc_Error
      ));

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 3);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (3), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Copy_Parameter_Table_Id, Status => Failure));

      -- Set task response 2 to something other than success:
      Task_Response := Parameter_Enums.Parameter_Table_Update_Status.Length_Error;
      Task_Response2 := Parameter_Enums.Parameter_Table_Update_Status.Success;

      -- Send copy command:
      T.Command_T_Send (T.Commands.Copy_Parameter_Table ((Copy_Type => Default_To_Working)));

      -- Execute the command and tell the task to respond.
      Task_Send_Response := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Copy from working should have occurred now. Check data:
      Natural_Assert.Eq (T.Default_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 3);
      Parameters_Memory_Region_Assert.Eq (
         T.Default_Parameters_Memory_Region_Recv_Sync_History.Get (3),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Get)
      );
      -- Copy to default:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 3);

      -- Check events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 8);
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 4);
      Packed_Parameter_Table_Copy_Type_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get (3), (Copy_Type => Default_To_Working));
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 0);
      Natural_Assert.Eq (T.Parameter_Table_Copy_Failure_History.Get_Count, 4);
      Parameters_Memory_Region_Release_Assert.Eq (T.Parameter_Table_Copy_Failure_History.Get (4), (
         Region => (Address => Sim_Bytes'Address, Length => Sim_Bytes'Length),
         Status => Parameter_Enums.Parameter_Table_Update_Status.Length_Error
      ));

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 4);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (4), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Copy_Parameter_Table_Id, Status => Failure));

      -- Kill our helper task.
      Task_Exit := True;
   end Test_Copy_Failure;

   overriding procedure Test_Copy_Timeout (Self : in out Instance) is
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Task_Exit : aliased Boolean := False;
      Sim_Task : Simulator_Task (Self'Unchecked_Access, Task_Exit'Unchecked_Access);
   begin
      -- Send copy command:
      T.Command_T_Send (T.Commands.Copy_Parameter_Table ((Copy_Type => Working_To_Default)));

      -- Execute the command and tell the task to respond with timeout
      Task_Send_Timeout := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Copy from working should have occurred now. Check data:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      Parameters_Memory_Region_Assert.Eq (
         T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (1),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Get)
      );
      -- No copy to default:
      Natural_Assert.Eq (T.Default_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);

      -- Check events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 2);
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 1);
      Packed_Parameter_Table_Copy_Type_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get (1), (Copy_Type => Working_To_Default));
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 0);
      Natural_Assert.Eq (T.Parameter_Table_Copy_Timeout_History.Get_Count, 1);

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Copy_Parameter_Table_Id, Status => Failure));

      -- Send copy command:
      T.Command_T_Send (T.Commands.Copy_Parameter_Table ((Copy_Type => Default_To_Working)));

      -- Execute the command and tell the task to respond with timeout
      -- Wait a bit to make sure our simulator task is reset and ready to go
      Sleep (50);
      Task_Send_Timeout := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Copy from working should have occurred now. Check data:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      -- No copy to default:
      Natural_Assert.Eq (T.Default_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      Parameters_Memory_Region_Assert.Eq (
         T.Default_Parameters_Memory_Region_Recv_Sync_History.Get (1),
         (Region => T.Get_Parameter_Bytes_Region, Operation => Get)
      );

      -- Check events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 4);
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 2);
      Packed_Parameter_Table_Copy_Type_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get (2), (Copy_Type => Default_To_Working));
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 0);
      Natural_Assert.Eq (T.Parameter_Table_Copy_Timeout_History.Get_Count, 2);

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 2);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (2), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Copy_Parameter_Table_Id, Status => Failure));

      -- Kill our helper task.
      Task_Exit := True;
   end Test_Copy_Timeout;

   overriding procedure Test_Full_Queue (Self : in out Instance) is
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Cmd : Command.T;
   begin
      -- Send 3 commands to fill up queue.
      Cmd.Header.Arg_Buffer_Length := Cmd.Arg_Buffer'Length;
      T.Command_T_Send (Cmd);
      T.Command_T_Send (Cmd);
      T.Command_T_Send (Cmd);

      -- OK the next command should overflow the queue.
      T.Expect_Command_T_Send_Dropped := True;
      T.Command_T_Send (Cmd);

      -- Make sure event thrown:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 1);
      Natural_Assert.Eq (T.Command_Dropped_History.Get_Count, 1);
      Command_Header_Assert.Eq (T.Command_Dropped_History.Get (1), Cmd.Header);
   end Test_Full_Queue;

   overriding procedure Test_Invalid_Command (Self : in out Instance) is
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Cmd : Command.T := T.Commands.Copy_Parameter_Table ((Copy_Type => Working_To_Default));
   begin
      -- Make the command invalid by modifying its length.
      Cmd.Header.Arg_Buffer_Length := 22;

      -- Send bad command and expect bad response:
      T.Command_T_Send (Cmd);
      Natural_Assert.Eq (T.Dispatch_All, 1);
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Copy_Parameter_Table_Id, Status => Length_Error));

      -- Make sure some events were thrown:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 1);
      Natural_Assert.Eq (T.Invalid_Command_Received_History.Get_Count, 1);
      Invalid_Command_Info_Assert.Eq (T.Invalid_Command_Received_History.Get (1), (Id => T.Commands.Get_Copy_Parameter_Table_Id, Errant_Field_Number => Interfaces.Unsigned_32'Last, Errant_Field => [0, 0, 0, 0, 0, 0, 0, 22]));
   end Test_Invalid_Command;

end Parameter_Manager_Tests.Implementation;
