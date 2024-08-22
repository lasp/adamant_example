--------------------------------------------------------------------------------
-- Parameter_Manager Tests Body
--------------------------------------------------------------------------------

with Ada.Real_Time;
with Basic_Assertions; use Basic_Assertions;
with Command_Enums; use Command_Enums.Command_Response_Status;
with Serializer_Types; use Serializer_Types;
with Smart_Assert;
with System; use System;
with Command;
with Command_Header.Assertion; use Command_Header.Assertion;
with Command_Response.Assertion; use Command_Response.Assertion;
with Parameters_Memory_Region;
with Interfaces; use Interfaces;
with Parameter_Enums; use Parameter_Enums.Parameter_Table_Update_Status;
with Basic_Types;
with Invalid_Command_Info.Assertion; use Invalid_Command_Info.Assertion;
with Parameter_Manager_Types;
with Parameter_Manager_Commands;
with Packed_Parameter_Table;
with Parameter_Manager_Table_Header;
with Parameter_Manager_Table_Header.Assertion; use Parameter_Manager_Table_Header.Assertion;
with Packed_Validation_Header;
with Packed_Validation; use Packed_Validation;

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
      Self.Tester.Init_Base (Queue_Size => Self.Tester.Component_Instance.Get_Max_Queue_Element_Size * 10);

      -- Make necessary connections between tester and component:
      Self.Tester.Connect;

      -- Call component init here.
      Self.Tester.Component_Instance.Init (Ticks_Until_Timeout => 3);

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

   Sim_Bytes : aliased Basic_Types.Byte_Array := [0 .. 246 => 12];
   Sim_Bytes_2 : aliased Basic_Types.Byte_Array := [0 .. 246 => 11];

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

   package Ser_Status_Assert is new Smart_Assert.Discrete (Serializer_Types.Serialization_Status, Serializer_Types.Serialization_Status'Image);

   package Validation_Status_Assert is new Smart_Assert.Discrete (Parameter_Enums.Parameter_Table_Update_Status.E, Parameter_Enums.Parameter_Table_Update_Status.E'Image);

   -- This unit test tests the nominal validation command.
   overriding procedure Test_Nominal_Validation (Self : in out Instance) is
      use Parameter_Manager_Table_Header;
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Task_Exit : aliased Boolean := False;
      Sim_Task : Simulator_Task (Self'Unchecked_Access, Task_Exit'Unchecked_Access);
      Table : aliased constant Basic_Types.Byte_Array := [0 .. 246 => 10];
      Packed_Table : constant Packed_Parameter_Table.T := (
         Header => (
            Table_Buffer_Length => Table'Length,
            Crc_Table => [0 .. 1 => 0],
            Version => 0.0
         ),
         Table_Buffer => Table
      );
      Cmd : Command.T;
      Assert_Header : Packed_Validation_Header.T;
      Assert_Region_Length : constant Integer := Packed_Table.Header.Table_Buffer_Length + Parameter_Manager_Table_Header.Crc_Table_Size_In_Bytes + Parameter_Manager_Table_Header.Version_Size_In_Bytes;
      Assert_Region : Parameters_Memory_Region.T;
      Assert_Data_Product : Packed_Validation.T;
   begin
      -- Send validate table command:
      Ser_Status_Assert.Eq (T.Commands.Validate_Parameter_Table (Packed_Table, Cmd), Success);
      T.Command_T_Send (Cmd);

      -- Execute the command and tell the task to respond.
      Task_Send_Response := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Table validation should have occurred now.
      -- Assert working parameters connector:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      -- Assert connector table region length:
      Assert_Region := T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (1);
      Natural_Assert.Eq (Assert_Region.Region.Length, Assert_Region_Length);
      -- Assert working connector address is not null:
      Address_Assert.Neq (Assert_Region.Region.Address, System.Null_Address);
      -- Assert table validation success:
      Natural_Assert.Eq (T.Table_Validation_Success_History.Get_Count, 1);
      -- Assert validation header:
      Assert_Header := T.Table_Validation_Success_History.Get (1);
      Parameter_Manager_Table_Header_Assert.Eq (Assert_Header.Last_Validation_Header, Packed_Table.Header);
      -- Assert last validation status:
      Validation_Status_Assert.Eq (Assert_Header.Last_Validation_Status, Success);
      -- Assert data product was produced:
      Natural_Assert.Eq (T.Data_Product_T_Recv_Sync_History.Get_Count, 1);
      Natural_Assert.Eq (T.Validation_Status_History.Get_Count, 1);
      -- Assert data product contents:
      Assert_Data_Product := T.Validation_Status_History.Get (1);
      Validation_Status_Assert.Eq (Assert_Data_Product.Last_Validation_Status, Success);

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Validate_Parameter_Table_Id, Status => Success));

      -- Kill our helper task.
      Task_Exit := True;
   end Test_Nominal_Validation;

   -- This unit test tests the component's response to a failed validation.
   overriding procedure Test_Validation_Failure (Self : in out Instance) is
      use Parameter_Manager_Table_Header;
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Task_Exit : aliased Boolean := False;
      Sim_Task : Simulator_Task (Self'Unchecked_Access, Task_Exit'Unchecked_Access);
      Table : aliased constant Basic_Types.Byte_Array := [0 .. 246 => 10];
      Packed_Table : constant Packed_Parameter_Table.T := (
         Header => (
            Table_Buffer_Length => Table'Length,
            Crc_Table => [0 .. 1 => 0],
            Version => 0.0
         ),
         Table_Buffer => Table
      );
      Cmd : Command.T;
      Assert_Header : Packed_Validation_Header.T;
      Assert_Region_Length : constant Integer := Packed_Table.Header.Table_Buffer_Length + Parameter_Manager_Table_Header.Crc_Table_Size_In_Bytes + Parameter_Manager_Table_Header.Version_Size_In_Bytes;
      Assert_Region : Parameters_Memory_Region.T;
      Assert_Data_Product : Packed_Validation.T;
   begin
      -- Set task response to something other than success:
      Task_Response := Parameter_Enums.Parameter_Table_Update_Status.Parameter_Error;
      -- Send validate table command:
      Ser_Status_Assert.Eq (T.Commands.Validate_Parameter_Table (Packed_Table, Cmd), Success);
      T.Command_T_Send (Cmd);

      -- Execute the command and tell the task to respond.
      Task_Send_Response := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Table validation should have occurred now.
      -- Assert working parameters connector:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      -- Assert connector table region length:
      Assert_Region := T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (1);
      Natural_Assert.Eq (Assert_Region.Region.Length, Assert_Region_Length);
      -- Assert working connector address is not null:
      Address_Assert.Neq (Assert_Region.Region.Address, System.Null_Address);
      -- Assert table validation failure:
      Natural_Assert.Eq (T.Table_Validation_Failure_History.Get_Count, 1);
      -- Assert validation header:
      Assert_Header := T.Table_Validation_Failure_History.Get (1);
      Parameter_Manager_Table_Header_Assert.Eq (Assert_Header.Last_Validation_Header, Packed_Table.Header);
      -- Assert last validation status:
      Validation_Status_Assert.Eq (Assert_Header.Last_Validation_Status, Parameter_Error);
      -- Assert data product was produced:
      Natural_Assert.Eq (T.Data_Product_T_Recv_Sync_History.Get_Count, 1);
      Natural_Assert.Eq (T.Validation_Status_History.Get_Count, 1);
      -- Assert data product contents:
      Assert_Data_Product := T.Validation_Status_History.Get (1);
      Validation_Status_Assert.Eq (Assert_Data_Product.Last_Validation_Status, Parameter_Error);

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Validate_Parameter_Table_Id, Status => Failure));

      -- Kill our helper task.
      Task_Exit := True;
   end Test_Validation_Failure;

   -- This unit test tests the component's response when the destination component
   -- does not respond to a validation command before a timeout occurs.
   overriding procedure Test_Validation_Timeout (Self : in out Instance) is
      use Parameter_Manager_Table_Header;
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Task_Exit : aliased Boolean := False;
      Sim_Task : Simulator_Task (Self'Unchecked_Access, Task_Exit'Unchecked_Access);
      Table : aliased constant Basic_Types.Byte_Array := [0 .. 246 => 10];
      Packed_Table : constant Packed_Parameter_Table.T := (
         Header => (
            Table_Buffer_Length => Table'Length,
            Crc_Table => [0 .. 1 => 0],
            Version => 0.0
         ),
         Table_Buffer => Table
      );
      Cmd : Command.T;
      Assert_Header : Packed_Validation_Header.T;
      Assert_Region_Length : constant Integer := Packed_Table.Header.Table_Buffer_Length + Parameter_Manager_Table_Header.Crc_Table_Size_In_Bytes + Parameter_Manager_Table_Header.Version_Size_In_Bytes;
      Assert_Region : Parameters_Memory_Region.T;
      Assert_Data_Product : Packed_Validation.T;
   begin
      -- First, send a normal validate table command:
      Ser_Status_Assert.Eq (T.Commands.Validate_Parameter_Table (Packed_Table, Cmd), Success);
      T.Command_T_Send (Cmd);

      -- Execute the command and tell the task to respond.
      Task_Send_Response := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Table validation should have occurred now.
      -- Assert working parameters connector:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      -- Assert connector table region length:
      Assert_Region := T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (1);
      Natural_Assert.Eq (Assert_Region.Region.Length, Assert_Region_Length);
      -- Assert working connector address is not null:
      Address_Assert.Neq (Assert_Region.Region.Address, System.Null_Address);
      -- Assert table validation success:
      Natural_Assert.Eq (T.Table_Validation_Success_History.Get_Count, 1);
      -- Assert validation header:
      Assert_Header := T.Table_Validation_Success_History.Get (1);
      Parameter_Manager_Table_Header_Assert.Eq (Assert_Header.Last_Validation_Header, Packed_Table.Header);
      -- Assert last validation status:
      Validation_Status_Assert.Eq (Assert_Header.Last_Validation_Status, Success);
      -- Assert data product was produced:
      Natural_Assert.Eq (T.Data_Product_T_Recv_Sync_History.Get_Count, 1);
      Natural_Assert.Eq (T.Validation_Status_History.Get_Count, 1);
      -- Assert data product contents:
      Assert_Data_Product := T.Validation_Status_History.Get (1);
      Validation_Status_Assert.Eq (Assert_Data_Product.Last_Validation_Status, Success);

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Validate_Parameter_Table_Id, Status => Success));

      -- Test validate table timeout:
      -- Send validate table command:
      Ser_Status_Assert.Eq (T.Commands.Validate_Parameter_Table (Packed_Table, Cmd), Success);
      T.Command_T_Send (Cmd);

      -- Execute the command and tell the task to respond.
      Task_Send_Timeout := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Table validation timeout should have occurred now.
      -- Assert working parameters connector:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 2);
      -- Assert connector table region length:
      Assert_Region := T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (2);
      Natural_Assert.Eq (Assert_Region.Region.Length, Assert_Region_Length);
      -- Assert working connector address is not null:
      Address_Assert.Neq (Assert_Region.Region.Address, System.Null_Address);
      -- Assert table validation failure:
      Natural_Assert.Eq (T.Table_Validation_Failure_History.Get_Count, 1);
      -- Assert validation header:
      Assert_Header := T.Table_Validation_Failure_History.Get (1);
      Parameter_Manager_Table_Header_Assert.Eq (Assert_Header.Last_Validation_Header, Packed_Table.Header);
      -- Assert last validation status:
      Validation_Status_Assert.Eq (Assert_Header.Last_Validation_Status, Success);
      -- Assert data product was produced:
      Natural_Assert.Eq (T.Data_Product_T_Recv_Sync_History.Get_Count, 2);
      Natural_Assert.Eq (T.Validation_Status_History.Get_Count, 2);
      -- Assert data product contents:
      Assert_Data_Product := T.Validation_Status_History.Get (2);
      Validation_Status_Assert.Eq (Assert_Data_Product.Last_Validation_Status, Success);

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 2);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (2), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Validate_Parameter_Table_Id, Status => Failure));

      -- Kill our helper task.
      Task_Exit := True;
   end Test_Validation_Timeout;

   -- This unit test tests the nominal update table command.
   overriding procedure Test_Nominal_Copy (Self : in out Instance) is
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Task_Exit : aliased Boolean := False;
      Sim_Task : Simulator_Task (Self'Unchecked_Access, Task_Exit'Unchecked_Access);
      Table : aliased constant Basic_Types.Byte_Array := [0 .. 246 => 10];
      Packed_Table : constant Packed_Parameter_Table.T := (
         Header => (
            Table_Buffer_Length => Table'Length,
            Crc_Table => [0 .. 1 => 0],
            Version => 0.0
         ),
         Table_Buffer => Table
      );
      Cmd : Command.T;
      Assert_Header : Parameter_Manager_Table_Header.T;
      Assert_Region_Length : constant Integer := Packed_Table.Header.Table_Buffer_Length + Parameter_Manager_Table_Header.Crc_Table_Size_In_Bytes + Parameter_Manager_Table_Header.Version_Size_In_Bytes;
      Assert_Region : Parameters_Memory_Region.T;
   begin
      -- Send update table command:
      Ser_Status_Assert.Eq (T.Commands.Update_Parameter_Table (Packed_Table, Cmd), Success);
      T.Command_T_Send (Cmd);

      -- Execute the command and tell the task to respond.
      Task_Send_Response_Twice := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Table update should have occurred now.
      -- Assert working parameters connector:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      -- Assert connector table region length:
      Assert_Region := T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (1);
      Natural_Assert.Eq (Assert_Region.Region.Length, Assert_Region_Length);
      -- Assert working connector address is not null:
      Address_Assert.Neq (Assert_Region.Region.Address, System.Null_Address);
      -- Assert primary parameters connector:
      Natural_Assert.Eq (T.Primary_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      -- Assert connector table region length:
      Assert_Region := T.Primary_Parameters_Memory_Region_Recv_Sync_History.Get (1);
      Natural_Assert.Eq (Assert_Region.Region.Length, Assert_Region_Length);
      -- Assert primary connector address is not null:
      Address_Assert.Neq (Assert_Region.Region.Address, System.Null_Address);

      -- Assert events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 2);
      -- Assert start copy header:
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 1);
      Assert_Header := T.Starting_Parameter_Table_Copy_History.Get (1);
      -- Assert start copy header address is not null:
      Address_Assert.Neq (Assert_Header.Crc_Table'Address, System.Null_Address);
      -- Assert start copy header length:
      Natural_Assert.Eq (Assert_Header.Table_Buffer_Length, Packed_Table.Header.Table_Buffer_Length);
      -- Assert no failure events:
      Natural_Assert.Eq (T.Working_Table_Update_Failure_History.Get_Count, 0);
      Natural_Assert.Eq (T.Primary_Table_Update_Failure_History.Get_Count, 0);
      -- Assert finished copy header:
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 1);
      Assert_Header := T.Finished_Parameter_Table_Copy_History.Get (1);
      -- Assert finished copy header address is not null:
      Address_Assert.Neq (Assert_Header.Crc_Table'Address, System.Null_Address);
      -- Assert finished copy header length:
      Natural_Assert.Eq (Assert_Header.Table_Buffer_Length, Packed_Table.Header.Table_Buffer_Length);

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Update_Parameter_Table_Id, Status => Success));

      -- Kill our helper task.
      Task_Exit := True;
   end Test_Nominal_Copy;

   -- This unit test tests the component's response to a failed parameter table copy.
   overriding procedure Test_Copy_Failure (Self : in out Instance) is
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Task_Exit : aliased Boolean := False;
      Sim_Task : Simulator_Task (Self'Unchecked_Access, Task_Exit'Unchecked_Access);
      Table : aliased constant Basic_Types.Byte_Array := [0 .. 246 => 10];
      Packed_Table : constant Packed_Parameter_Table.T := (
         Header => (
            Table_Buffer_Length => Table'Length,
            Crc_Table => [0 .. 1 => 0],
            Version => 0.0
         ),
         Table_Buffer => Table
      );
      Cmd : Command.T;
      Assert_Validation_Header : Packed_Validation_Header.T;
      Assert_Header : Parameter_Manager_Table_Header.T;
      Assert_Region_Length : constant Integer := Packed_Table.Header.Table_Buffer_Length + Parameter_Manager_Table_Header.Crc_Table_Size_In_Bytes + Parameter_Manager_Table_Header.Version_Size_In_Bytes;
      Assert_Region : Parameters_Memory_Region.T;
   begin
      -- Set task response to something other than success:
      Task_Response := Parameter_Enums.Parameter_Table_Update_Status.Parameter_Error;

      -- Send update table command:
      Ser_Status_Assert.Eq (T.Commands.Update_Parameter_Table (Packed_Table, Cmd), Success);
      T.Command_T_Send (Cmd);

      -- Execute the command and tell the task to respond.
      Task_Send_Response := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Working table update should have been attempted now.
      -- Assert working parameters connector:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      -- Assert connector table region length:
      Assert_Region := T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (1);
      Natural_Assert.Eq (Assert_Region.Region.Length, Assert_Region_Length);
      -- Assert working connector address is not null:
      Address_Assert.Neq (Assert_Region.Region.Address, System.Null_Address);
      -- Assert no primary primary connector after working parameter update failure:
      Natural_Assert.Eq (T.Primary_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);

      -- Assert events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 3);
      -- Assert start copy header:
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 1);
      Assert_Header := T.Starting_Parameter_Table_Copy_History.Get (1);
      -- Assert start copy header address is not null:
      Address_Assert.Neq (Assert_Header.Crc_Table'Address, System.Null_Address);
      -- Assert start copy header length:
      Natural_Assert.Eq (Assert_Header.Table_Buffer_Length, Packed_Table.Header.Table_Buffer_Length);
      -- Assert expected failure events:
      Natural_Assert.Eq (T.Parameter_Table_Copy_Failure_History.Get_Count, 1);
      Natural_Assert.Eq (T.Working_Table_Update_Failure_History.Get_Count, 1);
      Natural_Assert.Eq (T.Primary_Table_Update_Failure_History.Get_Count, 0);
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 0);
      Assert_Validation_Header := T.Working_Table_Update_Failure_History.Get (1);
      -- Assert working copy failure header address is not null:
      Address_Assert.Neq (Assert_Validation_Header.Last_Validation_Header.Crc_Table'Address, System.Null_Address);
      -- Assert working copy failure header length:
      Natural_Assert.Eq (Assert_Validation_Header.Last_Validation_Header.Table_Buffer_Length, Packed_Table.Header.Table_Buffer_Length);

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Update_Parameter_Table_Id, Status => Failure));

      -- Set working table task response to something other than success:
      Task_Response := Parameter_Enums.Parameter_Table_Update_Status.Parameter_Error;

      -- Send update table command:
      Ser_Status_Assert.Eq (T.Commands.Update_Parameter_Table (Packed_Table, Cmd), Success);
      T.Command_T_Send (Cmd);

      -- Execute the command and tell the task to respond.
      Task_Send_Response_Twice := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Primary table update should have been attempted now.
      -- Assert working parameters connector:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 2);
      -- Assert connector table region length:
      Assert_Region := T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (2);
      Natural_Assert.Eq (Assert_Region.Region.Length, Assert_Region_Length);
      -- Assert working connector address is not null:
      Address_Assert.Neq (Assert_Region.Region.Address, System.Null_Address);
      -- Assert primary parameters connector:
      Natural_Assert.Eq (T.Primary_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      -- Assert connector table region length:
      Assert_Region := T.Primary_Parameters_Memory_Region_Recv_Sync_History.Get (1);
      Natural_Assert.Eq (Assert_Region.Region.Length, Assert_Region_Length);
      -- Assert primary connector address is not null:
      Address_Assert.Neq (Assert_Region.Region.Address, System.Null_Address);

      -- Assert events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 6);
      -- Assert start copy header:
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 2);
      Assert_Header := T.Starting_Parameter_Table_Copy_History.Get (2);
      -- Assert start copy header address is not null:
      Address_Assert.Neq (Assert_Header.Crc_Table'Address, System.Null_Address);
      -- Assert start copy header length:
      Natural_Assert.Eq (Assert_Header.Table_Buffer_Length, Packed_Table.Header.Table_Buffer_Length);
      -- Assert expected failure events:
      Natural_Assert.Eq (T.Parameter_Table_Copy_Failure_History.Get_Count, 2);
      Natural_Assert.Eq (T.Working_Table_Update_Failure_History.Get_Count, 1);
      Natural_Assert.Eq (T.Primary_Table_Update_Failure_History.Get_Count, 1);
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 0);
      Assert_Validation_Header := T.Primary_Table_Update_Failure_History.Get (1);
      -- Assert primary copy failure header address is not null:
      Address_Assert.Neq (Assert_Validation_Header.Last_Validation_Header.Crc_Table'Address, System.Null_Address);
      -- Assert primary copy failure header length:
      Natural_Assert.Eq (Assert_Validation_Header.Last_Validation_Header.Table_Buffer_Length, Packed_Table.Header.Table_Buffer_Length);

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 2);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (2), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Update_Parameter_Table_Id, Status => Failure));

      -- Kill our helper task.
      Task_Exit := True;
   end Test_Copy_Failure;

   -- This unit test tests the component's response when the destination component
   -- does not respond to a copy command before a timeout occurs.
   overriding procedure Test_Copy_Timeout (Self : in out Instance) is
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Task_Exit : aliased Boolean := False;
      Sim_Task : Simulator_Task (Self'Unchecked_Access, Task_Exit'Unchecked_Access);
      Table : aliased constant Basic_Types.Byte_Array := [0 .. 246 => 10];
      Packed_Table : constant Packed_Parameter_Table.T := (
         Header => (
            Table_Buffer_Length => Table'Length,
            Crc_Table => [0 .. 1 => 0],
            Version => 0.0
         ),
         Table_Buffer => Table
      );
      Cmd : Command.T;
      Assert_Validation_Header : Packed_Validation_Header.T;
      Assert_Header : Parameter_Manager_Table_Header.T;
      Assert_Region_Length : constant Integer := Packed_Table.Header.Table_Buffer_Length + Parameter_Manager_Table_Header.Crc_Table_Size_In_Bytes + Parameter_Manager_Table_Header.Version_Size_In_Bytes;
      Assert_Region : Parameters_Memory_Region.T;
   begin
      -- Send update table command:
      Ser_Status_Assert.Eq (T.Commands.Update_Parameter_Table (Packed_Table, Cmd), Success);
      T.Command_T_Send (Cmd);

      -- Execute the command and tell the task to respond with timeout
      Task_Send_Timeout := True;
      Natural_Assert.Eq (T.Dispatch_All, 1);

      -- Table update should have been attempted now.
      -- Assert working parameters connector:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 1);
      -- Assert connector table region length:
      Assert_Region := T.Working_Parameters_Memory_Region_Recv_Sync_History.Get (1);
      Natural_Assert.Eq (Assert_Region.Region.Length, Assert_Region_Length);
      -- Assert working connector address is not null:
      Address_Assert.Neq (Assert_Region.Region.Address, System.Null_Address);
      -- Assert no primary primary connector after working parameter update timeout:
      Natural_Assert.Eq (T.Primary_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);

      -- Assert events:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 3);
      -- Assert start copy header:
      Natural_Assert.Eq (T.Starting_Parameter_Table_Copy_History.Get_Count, 1);
      Assert_Header := T.Starting_Parameter_Table_Copy_History.Get (1);
      -- Assert start copy header address is not null:
      Address_Assert.Neq (Assert_Header.Crc_Table'Address, System.Null_Address);
      -- Assert start copy header length:
      Natural_Assert.Eq (Assert_Header.Table_Buffer_Length, Packed_Table.Header.Table_Buffer_Length);
      -- Assert expected failure events:
      Natural_Assert.Eq (T.Parameter_Table_Copy_Timeout_History.Get_Count, 1);
      Natural_Assert.Eq (T.Working_Table_Update_Failure_History.Get_Count, 1);
      Natural_Assert.Eq (T.Primary_Table_Update_Failure_History.Get_Count, 0);
      Natural_Assert.Eq (T.Finished_Parameter_Table_Copy_History.Get_Count, 0);
      Assert_Validation_Header := T.Working_Table_Update_Failure_History.Get (1);
      -- Assert working copy failure header address is not null:
      Address_Assert.Neq (Assert_Validation_Header.Last_Validation_Header.Crc_Table'Address, System.Null_Address);
      -- Assert working copy failure header length:
      Natural_Assert.Eq (Assert_Validation_Header.Last_Validation_Header.Table_Buffer_Length, Packed_Table.Header.Table_Buffer_Length);

      -- Check command response:
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Update_Parameter_Table_Id, Status => Failure));

      -- Kill our helper task.
      Task_Exit := True;
   end Test_Copy_Timeout;

   -- This unit test tests a command or memory region being dropped due to a full
   -- queue.
   overriding procedure Test_Full_Queue (Self : in out Instance) is
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Cmd : Command.T;
   begin
      -- Send 10 commands to fill up queue.
      Cmd.Header.Arg_Buffer_Length := Cmd.Arg_Buffer'Length;
      for Index in 0 .. 9 loop
         T.Command_T_Send (Cmd);
      end loop;

      -- Assert queue usage is at maximum:
      Boolean_Assert.Eq (T.Component_Instance.Get_Queue_Current_Percent_Used = T.Component_Instance.Get_Queue_Maximum_Percent_Used, True);

      -- OK the next command should overflow the queue.
      T.Expect_Command_T_Send_Dropped := True;
      T.Command_T_Send (Cmd);

      -- Assert nothing received over connectors:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);
      Natural_Assert.Eq (T.Primary_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);

      -- Make sure event thrown:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 1);
      Natural_Assert.Eq (T.Command_Dropped_History.Get_Count, 1);
      Command_Header_Assert.Eq (T.Command_Dropped_History.Get (1), Cmd.Header);
   end Test_Full_Queue;

   -- This unit test exercises that an invalid command throws the appropriate event.
   overriding procedure Test_Invalid_Command (Self : in out Instance) is
      T : Component.Parameter_Manager.Implementation.Tester.Instance_Access renames Self.Tester;
      Task_Exit : aliased Boolean := False;
      Sim_Task : Simulator_Task (Self'Unchecked_Access, Task_Exit'Unchecked_Access);
      Table : aliased constant Basic_Types.Byte_Array := [0 .. 246 => 10];
      Packed_Table : constant Packed_Parameter_Table.T := (
         Header => (
            Table_Buffer_Length => Table'Length,
            Crc_Table => [0 .. 1 => 0],
            Version => 0.0
         ),
         Table_Buffer => Table
      );
      Cmd : Command.T;
      Invalid_Table : Packed_Parameter_Table.T;
   begin
      -- Send update table command:
      Ser_Status_Assert.Eq (T.Commands.Update_Parameter_Table (Packed_Table, Cmd), Success);
      -- Make the command invalid by setting the packed table
      -- header's table buffer length larger than the command
      -- header argument buffer length:
      Cmd.Arg_Buffer (1) := Table'Length + 1;

      -- Execute the command and tell the task to respond
      Task_Send_Response_Twice := True;
      T.Command_T_Send (Cmd);

      -- Send bad command and expect bad response:
      Natural_Assert.Eq (T.Dispatch_All, 1);
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 1);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (1), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Update_Parameter_Table_Id, Status => Length_Error));

      -- Assert nothing sent over memory region connectors:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);
      Natural_Assert.Eq (T.Primary_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);

      -- Make sure some events were thrown:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 1);
      Natural_Assert.Eq (T.Invalid_Command_Received_History.Get_Count, 1);
      Invalid_Command_Info_Assert.Eq (T.Invalid_Command_Received_History.Get (1), (Id => T.Commands.Get_Update_Parameter_Table_Id, Errant_Field_Number => Interfaces.Unsigned_32'Last, Errant_Field => [0, 0, 0, 0, 0, 0, 0, 255]));

      -- Send update table command:
      Ser_Status_Assert.Eq (T.Commands.Update_Parameter_Table (Packed_Table, Cmd), Success);
      -- Make the command invalid by setting the command header
      -- argument buffer length smaller than the packed table
      -- header's table buffer length:
      Cmd.Header.Arg_Buffer_Length := 1;

      -- Execute the command and tell the task to respond
      Task_Send_Response_Twice := True;
      T.Command_T_Send (Cmd);

      -- Send bad command and expect bad response:
      Natural_Assert.Eq (T.Dispatch_All, 1);
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 2);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (2), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Update_Parameter_Table_Id, Status => Length_Error));

      -- Assert nothing sent over memory region connectors:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);
      Natural_Assert.Eq (T.Primary_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);

      -- Make sure some events were thrown:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 2);
      Natural_Assert.Eq (T.Invalid_Command_Received_History.Get_Count, 2);
      Invalid_Command_Info_Assert.Eq (T.Invalid_Command_Received_History.Get (2), (Id => T.Commands.Get_Update_Parameter_Table_Id, Errant_Field_Number => Interfaces.Unsigned_32'Last, Errant_Field => [0, 0, 0, 0, 0, 0, 0, 1]));

      -- Send update table command:
      -- Make the command invalid by setting the packed table
      -- header's table buffer length out of range for the type:
      Invalid_Table.Header.Table_Buffer_Length := Parameter_Manager_Types.Parameter_Manager_Buffer_Length_Type'Last;
      Ser_Status_Assert.Eq (T.Commands.Update_Parameter_Table (Invalid_Table, Cmd), Success);

      -- Execute the command and tell the task to respond
      Task_Send_Response_Twice := True;
      T.Command_T_Send (Cmd);

      -- Send bad command and expect bad response:
      Natural_Assert.Eq (T.Dispatch_All, 1);
      Natural_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get_Count, 3);
      Command_Response_Assert.Eq (T.Command_Response_T_Recv_Sync_History.Get (3), (Source_Id => 0, Registration_Id => 0, Command_Id => T.Commands.Get_Update_Parameter_Table_Id, Status => Validation_Error));

      -- Assert nothing sent over memory region connectors:
      Natural_Assert.Eq (T.Working_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);
      Natural_Assert.Eq (T.Primary_Parameters_Memory_Region_Recv_Sync_History.Get_Count, 0);

      -- Make sure some events were thrown:
      Natural_Assert.Eq (T.Event_T_Recv_Sync_History.Get_Count, 3);
      Natural_Assert.Eq (T.Invalid_Command_Received_History.Get_Count, 3);
      Invalid_Command_Info_Assert.Eq (T.Invalid_Command_Received_History.Get (3), (Id => T.Commands.Get_Update_Parameter_Table_Id, Errant_Field_Number => 3, Errant_Field => [0, 0, 0, 0, 247, 0, 0, 0]));
   end Test_Invalid_Command;

end Parameter_Manager_Tests.Implementation;
