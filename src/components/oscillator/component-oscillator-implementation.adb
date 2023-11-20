--------------------------------------------------------------------------------
-- Oscillator Component Implementation Body
--------------------------------------------------------------------------------

with Packed_F32;
with Ada.Numerics.Generic_Elementary_Functions;
with Sys_Time.Arithmetic;
with Ada.Real_Time;

package body Component.Oscillator.Implementation is

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The schedule invokee connector
   overriding procedure Tick_T_Recv_Sync (Self : in out Instance; Arg : in Tick.T) is
      use Ada.Numerics;
      use Sys_Time;
      use Sys_Time.Arithmetic;
      use Ada.Real_Time;

      Float_Time : Short_Float;
      Data : Packed_F32.T;
      Time_Diff : Time_Span;
      Ignore : Natural;
      package Float_Functions is new Generic_Elementary_Functions (Short_Float);
   begin
      -- Update the parameters:
      Self.Update_Parameters;

      -- Service the queue for commands:
      Ignore := Self.Dispatch_All;

      -- Set the epoch if this is the first time receiving a tick:
      if Self.Epoch = (0, 0) then
         Self.Epoch := Arg.Time;
      end if;

      -- Calculate the time delta since the epoch:
      Time_Diff := Arg.Time - Self.Epoch;
      Float_Time := Short_Float (To_Duration (Time_Diff));

      -- Calculate the value of the oscillator based on the timestamp given in the tick:
      Data.Value := Self.Offset.Value + Self.Amplitude.Value * Float_Functions.Sin (2.0 * Pi * Self.Frequency.Value * Float_Time);

      -- Send the value out as data product:
      Self.Data_Product_T_Send (Self.Data_Products.Oscillator_Value (Self.Sys_Time_T_Get, Data));
   end Tick_T_Recv_Sync;

   -- The command receive connector
   overriding procedure Command_T_Recv_Async (Self : in out Instance; Arg : in Command.T) is
      -- Execute the command:
      Stat : constant Command_Response_Status.E := Self.Execute_Command (Arg);
   begin
      -- Send the return status:
      Self.Command_Response_T_Send_If_Connected ((Source_Id => Arg.Header.Source_Id, Registration_Id => Self.Command_Reg_Id, Command_Id => Arg.Header.Id, Status => Stat));
   end Command_T_Recv_Async;

   -- The parameter update connector.
   overriding procedure Parameter_Update_T_Modify (Self : in out Instance; Arg : in out Parameter_Update.T) is
   begin
      -- Process the parameter update, staging or fetching parameters as requested.
      Self.Process_Parameter_Update (Arg);
   end Parameter_Update_T_Modify;

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
   --    Commands for the Oscillator component
   -- Set the frequency of the oscillator in Hz
   overriding function Set_Frequency (Self : in out Instance; Arg : in Packed_F32.T) return Command_Execution_Status.E is use Command_Execution_Status;
   begin
      Self.Frequency.Value := Arg.Value;
      Self.Event_T_Send (Self.Events.Frequency_Value_Set (Self.Sys_Time_T_Get, Arg));
      return Success;
   end Set_Frequency;

   -- Set the amplitude of the oscillator
   overriding function Set_Amplitude (Self : in out Instance; Arg : in Packed_F32.T) return Command_Execution_Status.E is
      use Command_Execution_Status;
   begin
      Self.Amplitude.Value := Arg.Value;
      Self.Event_T_Send (Self.Events.Amplitude_Value_Set (Self.Sys_Time_T_Get, Arg));
      return Success;
   end Set_Amplitude;

   -- Set the Y offset of the oscillator
   overriding function Set_Offset (Self : in out Instance; Arg : in Packed_F32.T) return Command_Execution_Status.E is
      use Command_Execution_Status;
   begin
      Self.Offset.Value := Arg.Value;
      Self.Event_T_Send (Self.Events.Offset_Value_Set (Self.Sys_Time_T_Get, Arg));
      return Success;
   end Set_Offset;

   -- Invalid command handler. This procedure is called when a command's arguments are found to be invalid:
   overriding procedure Invalid_Command (Self : in out Instance; Cmd : in Command.T; Errant_Field_Number : in Unsigned_32; Errant_Field : in Basic_Types.Poly_Type) is
   begin
      -- Throw event:
      Self.Event_T_Send_If_Connected (Self.Events.Invalid_Command_Received (
         Self.Sys_Time_T_Get,
         (Id => Cmd.Header.Id, Errant_Field_Number => Errant_Field_Number, Errant_Field => Errant_Field)
      ));
   end Invalid_Command;

   -----------------------------------------------
   -- Parameter handlers:
   -----------------------------------------------
   -- Description:
   --    Parameters for the Oscillator component
   -- Invalid Parameter handler. This procedure is called when a parameter's type is found to be invalid:
   overriding procedure Invalid_Parameter (Self : in out Instance; Par : in Parameter.T; Errant_Field_Number : in Unsigned_32; Errant_Field : in Basic_Types.Poly_Type) is
   begin
      -- Throw event:
      Self.Event_T_Send_If_Connected (Self.Events.Invalid_Parameter_Received (
         Self.Sys_Time_T_Get,
         (Id => Par.Header.Id, Errant_Field_Number => Errant_Field_Number, Errant_Field => Errant_Field)
      ));
   end Invalid_Parameter;

end Component.Oscillator.Implementation;
