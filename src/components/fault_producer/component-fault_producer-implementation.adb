--------------------------------------------------------------------------------
-- Fault_Producer Component Implementation Body
--------------------------------------------------------------------------------

package body Component.Fault_Producer.Implementation is

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The command receive connector.
   overriding procedure Command_T_Recv_Sync (Self : in out Instance; Arg : in Command.T) is
      -- Execute the command:
      Stat : constant Command_Response_Status.E := Self.Execute_Command (Arg);
   begin
      -- Send the return status:
      Self.Command_Response_T_Send_If_Connected ((Source_Id => Arg.Header.Source_Id, Registration_Id => Self.Command_Reg_Id, Command_Id => Arg.Header.Id, Status => Stat));
   end Command_T_Recv_Sync;

   -----------------------------------------------
   -- Command handler primitives:
   -----------------------------------------------
   -- Description:
   --    Commands for the fault producer component
   -- Throw the first fault.
   overriding function Throw_Fault_1 (Self : in out Instance) return Command_Execution_Status.E is
      use Command_Execution_Status;
   begin
      -- Send event and fault:
      Self.Event_T_Send_If_Connected (Self.Events.Sending_Fault_1 (Self.Sys_Time_T_Get));
      Self.Fault_T_Send_If_Connected (Self.Faults.Fault_1 (Self.Sys_Time_T_Get));
      return Success;
   end Throw_Fault_1;

   -- Throw the second fault.
   overriding function Throw_Fault_2 (Self : in out Instance) return Command_Execution_Status.E is
      use Command_Execution_Status;
   begin
      -- Send event and fault:
      Self.Event_T_Send_If_Connected (Self.Events.Sending_Fault_2 (Self.Sys_Time_T_Get));
      Self.Fault_T_Send_If_Connected (Self.Faults.Fault_2 (Self.Sys_Time_T_Get, (Value => 99)));
      return Success;
   end Throw_Fault_2;

   -- Invalid command handler. This procedure is called when a command's arguments are found to be invalid:
   overriding procedure Invalid_Command (Self : in out Instance; Cmd : in Command.T; Errant_Field_Number : in Unsigned_32; Errant_Field : in Basic_Types.Poly_Type) is
   begin
      -- Throw event:
      Self.Event_T_Send_If_Connected (Self.Events.Invalid_Command_Received (
         Self.Sys_Time_T_Get,
         (Id => Cmd.Header.Id, Errant_Field_Number => Errant_Field_Number, Errant_Field => Errant_Field)
      ));
   end Invalid_Command;

end Component.Fault_Producer.Implementation;
