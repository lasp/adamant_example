--------------------------------------------------------------------------------
-- Counter Component Implementation Body
--------------------------------------------------------------------------------

with Counter_Action;

package body Component.Counter.Implementation is

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The schedule invokee connector
   overriding procedure Tick_T_Recv_Sync (Self : in out Instance; Arg : in Tick.T) is
      Ignore : Tick.T renames Arg;
      Ignore_2 : Natural;
      Timestamp : constant Sys_Time.T := Self.Sys_Time_T_Get;
   begin
      -- Service the queue for commands:
      Ignore_2 := Self.Dispatch_All;

      -- Increment the count and perform the counter action:
      Self.The_Count := Self.The_Count + 1;
      Counter_Action.Do_Action (Self.The_Count);

      -- Send the count value out:
      Self.Event_T_Send_If_Connected (Self.Events.Sending_Value (Timestamp, (Value => Self.The_Count)));
      Self.Packet_T_Send_If_Connected (Self.Packets.Counter_Value (Timestamp, (Value => Self.The_Count)));
   end Tick_T_Recv_Sync;

   -- The command receive connector
   overriding procedure Command_T_Recv_Async (Self : in out Instance; Arg : in Command.T) is
      -- Execute the command:
      Stat : constant Command_Response_Status.E := Self.Execute_Command (Arg);
   begin
      -- Send the return status:
      Self.Command_Response_T_Send_If_Connected ((Source_Id => Arg.Header.Source_Id, Registration_Id => Self.Command_Reg_Id, Command_Id => Arg.Header.Id, Status => Stat));
   end Command_T_Recv_Async;

   -- This procedure is called when a Command_T_Recv_Async message is dropped due to a full queue.
   overriding procedure Command_T_Recv_Async_Dropped (Self : in out Instance; Arg : in Command.T) is
   begin
      -- Throw event:
      Self.Event_T_Send_If_Connected (Self.Events.Dropped_Command (
         Self.Sys_Time_T_Get, Arg.Header
      ));
   end Command_T_Recv_Async_Dropped;

   -----------------------------------------------
   -- Command handler primitives:
   -----------------------------------------------
   -- Description:
   --    Commands for the counter component
   -- Change the current counter value in the counter component
   overriding function Set_Count (Self : in out Instance; Arg : in Packed_U32.T) return Command_Execution_Status.E is
      use Command_Execution_Status;
   begin
      Self.The_Count := Arg.Value;
      Self.Event_T_Send_If_Connected (Self.Events.Set_Count_Command_Received (Self.Sys_Time_T_Get, (Value => Self.The_Count)));
      return Success;
   end Set_Count;

   -- Reset the current counter value in the counter component to zero
   overriding function Reset_Count (Self : in out Instance) return Command_Execution_Status.E is
      use Command_Execution_Status;
   begin
      Self.The_Count := 0;
      Self.Event_T_Send_If_Connected (Self.Events.Reset_Count_Command_Received (Self.Sys_Time_T_Get));
      return Success;
   end Reset_Count;

   -- Change the current counter value in the counter component to the sum of the arguments
   overriding function Set_Count_Add (Self : in out Instance; Arg : in Operands.T) return Command_Execution_Status.E is
      use Command_Execution_Status;
   begin
      Self.The_Count := Unsigned_32 (Arg.Left) + Unsigned_32 (Arg.Right);
      Self.Event_T_Send_If_Connected (Self.Events.Set_Count_Add_Command_Received (Self.Sys_Time_T_Get, Arg));
      return Success;
   end Set_Count_Add;

   -- Invalid command handler. This procedure is called when a command's arguments are found to be invalid:
   overriding procedure Invalid_Command (Self : in out Instance; Cmd : in Command.T; Errant_Field_Number : in Unsigned_32; Errant_Field : in Basic_Types.Poly_Type) is
   begin
      Self.Event_T_Send_If_Connected (Self.Events.Invalid_Command_Received (
         Self.Sys_Time_T_Get,
         (Id => Cmd.Header.Id, Errant_Field_Number => Errant_Field_Number, Errant_Field => Errant_Field)
      ));
   end Invalid_Command;

end Component.Counter.Implementation;
