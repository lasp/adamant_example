--------------------------------------------------------------------------------
-- Parameter_Manager Component Implementation Body
--------------------------------------------------------------------------------

with Parameter_Enums;

package body Component.Parameter_Manager.Implementation is

   --------------------------------------------------
   -- Subprogram for implementation init method:
   --------------------------------------------------
   -- Initialization parameters for the Parameter Manager.
   --
   -- Init Parameters:
   -- Ticks_Until_Timeout : Natural - The component will wait until it has received
   -- at least this many ticks before reporting a timeout error while waiting for a
   -- parameter update/fetch response from either the working or default parameter
   -- components. For example, if the component is attached to a 10Hz rate group and
   -- this value is set to 7, then the component will wait between 700 and 800 ms
   -- before declaring a timeout error from an unresponsive downstream component.
   --
   overriding procedure Init (Self : in out Instance; Ticks_Until_Timeout : in Natural) is
   begin
      -- Save the ticks until timeout.
      Self.Sync_Object.Set_Timeout_Limit (Ticks_Until_Timeout);
   end Init;

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The component should be attached to a periodic tick that is used to timeout
   -- waiting for a parameter update/fetch response. See the ticks_Until_Timeout
   -- initialization parameter.
   overriding procedure Timeout_Tick_Recv_Sync (Self : in out Instance; Arg : in Tick.T) is
      Ignore : Tick.T renames Arg;
   begin
      -- If the component is currently waiting on a response from a downstream component
      -- we need to implement the timeout logic. Otherwise reset our timeout counter.
      -- Increment the timeout counter on the sync object. This will only cause a timeout
      -- if the sync object is waiting and the timeout counter exceeds the timeout limit.
      Self.Sync_Object.Increment_Timeout_If_Waiting;
   end Timeout_Tick_Recv_Sync;

   -- The command receive connector.
   overriding procedure Command_T_Recv_Async (Self : in out Instance; Arg : in Command.T) is
      -- Execute the command:
      Stat : constant Command_Response_Status.E := Self.Execute_Command (Arg);
   begin
      -- Send the return status:
      Self.Command_Response_T_Send_If_Connected ((Source_Id => Arg.Header.Source_Id, Registration_Id => Self.Command_Reg_Id, Command_Id => Arg.Header.Id, Status => Stat));
   end Command_T_Recv_Async;

   -- Parameter update/fetch responses are returned synchronously on this connector.
   -- The component waits internally for this response, or times out if the response
   -- is not received in time.
   overriding procedure Parameters_Memory_Region_Release_T_Recv_Sync (Self : in out Instance; Arg : in Parameters_Memory_Region_Release.T) is
   begin
      -- First set the protected response with the response from the component.
      -- In this function we simply store whatever we get. The error handling based on the
      -- contents of this response are done by this component's task (executing the command).
      Self.Response.Set_Var (Arg);

      -- Ok we have stored the response for the component to look at later. Now we signal
      -- to the component that a response has been received and it can read it.
      Self.Sync_Object.Release;

      -- Note, there is a possible race condition here. Think, we could set the response
      -- within the component, and then release it to allow reading of this data. Before
      -- the component reads the data, however, we may receive another response, overwriting
      -- the data the component receives before it can read the old data. This sounds serious,
      -- but this behavior should never occur, since the downstream components should not ever
      -- return a response to this component unprovoked. If for some errant reason this condition
      -- does occur, it will likely be caught by the error handling in this component's task, which
      -- checks the virtual memory ID for correctness before handling the response.
      --
      -- Note, the protected buffer and the sync object are both protected objects, so there
      -- is no risk of data corruption (which would be a serious problem), there is just risk of
      -- out of order synchronization, which should not occur is the assembly is designed
      -- correctly, as described above. If the assembly is not designed correctly, this component's
      -- error handling will reveal the problem.
   end Parameters_Memory_Region_Release_T_Recv_Sync;

   -- This procedure is called when a Command_T_Recv_Async message is dropped due to a full queue.
   overriding procedure Command_T_Recv_Async_Dropped (Self : in out Instance; Arg : in Command.T) is
   begin
      -- Throw event:
      Self.Event_T_Send_If_Connected (Self.Events.Command_Dropped (Self.Sys_Time_T_Get, Arg.Header));
   end Command_T_Recv_Async_Dropped;

   ---------------------------------------
   -- Helper functions:
   ---------------------------------------
   -- Helper which waits for a response from a downstream component after an update/fetch request. This
   -- function waits for the response and then does the boiler plate error checking and event throwing
   -- that all copy commands must perform.
   function Wait_For_Response (Self : in out Instance) return Boolean is
      Wait_Timed_Out : Boolean;
      use Parameter_Enums;
   begin
      -- OK wait for the response.
      Self.Sync_Object.Wait (Wait_Timed_Out);

      -- Check the wait return value:
      if Wait_Timed_Out then
         -- Send info event:
         Self.Event_T_Send_If_Connected (Self.Events.Parameter_Table_Copy_Timeout (Self.Sys_Time_T_Get));
         return False;
      end if;

      -- Take a look at the response:
      declare
         use Parameter_Enums.Parameter_Table_Update_Status;
         -- Read the response from the protected variable:
         Release : constant Parameters_Memory_Region_Release.T := Self.Response.Get_Var;
      begin
         -- Check the status:
         if Release.Status /= Success then
            -- Send info event:
            Self.Event_T_Send_If_Connected (Self.Events.Parameter_Table_Copy_Failure (Self.Sys_Time_T_Get, Release));
            return False;
         end if;
      end;

      return True;
   end Wait_For_Response;

   -- Helper function which updates work parameter table data.
   function Update_Working_Table (Self : in out Instance; Arg : in Parameters_Memory_Region.T) return Command_Execution_Status.E is
      use Command_Execution_Status;
   begin
      -- First, clear the state of the synchronization
      -- object. This prevents us from just "falling through" the
      -- wait call below if some errant response was sent through
      -- to us while we were not listening.
      -- This also resets the timeout counter, so we start
      -- fresh.
      Self.Sync_Object.Reset;

      -- Send the request to the working component.
      Self.Working_Parameters_Memory_Region_Send_If_Connected (Arg);

      -- OK now we wait for and check the response.
      if not Self.Wait_For_Response then
         return Failure;
      end if;

      return Success;
   end Update_Working_Table;

   -- Helper function which updates default parameter table data.
   function Update_Primary_Table (Self : in out Instance; Arg : in Parameters_Memory_Region.T) return Command_Execution_Status.E is
      use Command_Execution_Status;
   begin
      -- First, clear the state of the synchronization
      -- object. This prevents us from just "falling through" the
      -- wait call below if some errant response was sent through
      -- to us while we were not listening.
      -- This also resets the timeout counter, so we start
      -- fresh.
      Self.Sync_Object.Reset;

      -- Send the request to the primary component.
      Self.Primary_Parameters_Memory_Region_Send_If_Connected (Arg);

      -- OK now we wait for and check the response.
      if not Self.Wait_For_Response then
         return Failure;
      end if;

      return Success;
   end Update_Primary_Table;

   -----------------------------------------------
   -- Command handler primitives:
   -----------------------------------------------
   -- Description:
   --    These are the commands for the Parameter Manager component.
   -- Send received parameter table to default and working regions.
   overriding function Update_Parameter_Table (Self : in out Instance; Arg : in Packed_Parameter_Table.T) return Command_Execution_Status.E is
      use Command_Execution_Status;
      -- The parameter table header includes the Table_Buffer_Length
      -- before the CRC table, so the region must be taken from the
      -- CRC table address instead of from the beginning. The region
      -- length must be the Table_Buffer_Length size in bytes plus
      -- the size in bytes of the CRC table and the version.
      Parameter_Table_Region : constant Parameters_Memory_Region.T := (
         Region => (
            Address => Arg.Header.Crc_Table'Address,
            Length => Arg.Header.Table_Buffer_Length + Parameter_Manager_Table_Header.Crc_Table_Size_In_Bytes + Parameter_Manager_Table_Header.Version_Size_In_Bytes
         ),
         Operation => (Parameter_Enums.Parameter_Table_Operation_Type.Set)
      );
   begin
      -- Info event:
      Self.Event_T_Send_If_Connected (Self.Events.Starting_Parameter_Table_Copy (Self.Sys_Time_T_Get, Arg.Header));

      if Self.Update_Working_Table (Parameter_Table_Region) /= Success
      then
         -- Info event:
         Self.Event_T_Send_If_Connected (Self.Events.Working_Table_Update_Failure (
            Timestamp => Self.Sys_Time_T_Get,
            Param => (
               Last_Validation_Header => Arg.Header,
               Last_Validation_Status => Self.Response.Get_Var.Status
            )
         ));
         return Failure;
      end if;
      if Self.Update_Primary_Table (Parameter_Table_Region) /= Success
      then
         -- Info event:
         Self.Event_T_Send_If_Connected (Self.Events.Primary_Table_Update_Failure (
            Timestamp => Self.Sys_Time_T_Get,
            Param => (
               Last_Validation_Header => Arg.Header,
               Last_Validation_Status => Self.Response.Get_Var.Status
            )
         ));
         return Failure;
      end if;
      -- Info event:
      Self.Event_T_Send_If_Connected (Self.Events.Finished_Parameter_Table_Copy (Self.Sys_Time_T_Get, Arg.Header));
      return Success;
   end Update_Parameter_Table;

   -- Validate a received parameter table.
   overriding function Validate_Parameter_Table (Self : in out Instance; Arg : in Packed_Parameter_Table.T) return Command_Execution_Status.E is
      use Command_Execution_Status;
      -- The parameter table header includes the Table_Buffer_Length
      -- before the CRC table, so the region must be taken from the
      -- CRC table address instead of from the beginning. The region
      -- length must be the Table_Buffer_Length size in bytes plus
      -- the size in bytes of the CRC table and the version.
      Parameter_Table_Region : constant Parameters_Memory_Region.T := (
         Region => (
            Address => Arg.Header.Crc_Table'Address,
            Length => Arg.Header.Table_Buffer_Length + Parameter_Manager_Table_Header.Crc_Table_Size_In_Bytes + Parameter_Manager_Table_Header.Version_Size_In_Bytes
         ),
         Operation => (Parameter_Enums.Parameter_Table_Operation_Type.Validate)
      );
   begin
      -- Validate argument table parameters:

      -- First, clear the state of the synchronization
      -- object. This prevents us from just "falling through" the
      -- wait call below if some errant response was sent through
      -- to us while we were not listening.
      -- This also resets the timeout counter, so we start
      -- fresh.
      Self.Sync_Object.Reset;

      -- Send the request to the working component.
      Self.Working_Parameters_Memory_Region_Send_If_Connected (Parameter_Table_Region);

      declare
         -- Update the response:
         Response : constant Boolean := Self.Wait_For_Response;
         -- Update the timestamp:
         Time : constant Sys_Time.T := Self.Sys_Time_T_Get;
         -- Update the validation status:
         Validation_Status : constant Parameter_Enums.Parameter_Table_Update_Status.E := Self.Response.Get_Var.Status;
      begin
         -- Send out the validation as a data product:
         Self.Data_Product_T_Send_If_Connected (Self.Data_Products.Validation_Status (
            Timestamp => Time,
            Item => (
               Last_Validation_Version => Arg.Header.Version,
               Crc_Table => Arg.Header.Crc_Table,
               Last_Validation_Status => Validation_Status
            )
         ));
         case Response is
            when False =>
               -- Throw event:
               Self.Event_T_Send_If_Connected (Self.Events.Table_Validation_Failure (
                  Timestamp => Time,
                  Param => (
                     Last_Validation_Header => Arg.Header,
                     Last_Validation_Status => Validation_Status
                  )
               ));
               return Failure;
            when True =>
               -- Throw event:
               Self.Event_T_Send_If_Connected (Self.Events.Table_Validation_Success (
                  Timestamp => Time,
                  Param => (
                     Last_Validation_Header => Arg.Header,
                     Last_Validation_Status => Validation_Status
                  )
               ));
               return Success;
         end case;
      end;
   end Validate_Parameter_Table;

   -- Invalid command handler. This procedure is called when a command's arguments are found to be invalid:
   overriding procedure Invalid_Command (Self : in out Instance; Cmd : in Command.T; Errant_Field_Number : in Unsigned_32; Errant_Field : in Basic_Types.Poly_Type) is
   begin
      -- Throw event:
      Self.Event_T_Send_If_Connected (Self.Events.Invalid_Command_Received (Self.Sys_Time_T_Get, (Id => Cmd.Header.Id, Errant_Field_Number => Errant_Field_Number, Errant_Field => Errant_Field)));
   end Invalid_Command;

end Component.Parameter_Manager.Implementation;
