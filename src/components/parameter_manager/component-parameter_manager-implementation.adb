--------------------------------------------------------------------------------
-- Parameter_Manager Component Implementation Body
--------------------------------------------------------------------------------

with Crc_16;
with Parameter_Enums;
with Parameter_Manager_Enums;
with Packet_Types;

package body Component.Parameter_Manager.Implementation is

   --------------------------------------------------
   -- Subprogram for implementation init method:
   --------------------------------------------------
   -- Initialization parameters for the Parameter Manager.
   --
   -- Init Parameters:
   -- parameter_Table_Length : Natural - The size of the parameter table in bytes. This must be known to the component so it can construct correct sized memory regions for the downstream components.
   -- ticks_Until_Timeout : Natural - The component will wait until it has received at least this many ticks before reporting a timeout error while waiting for a parameter update/fetch response from either the active or default parameter components. For example, if the component is attached to a 10Hz rate group and this value is set to 7, then the component will wait between 700 and 800 ms before declaring a timeout error from an unresponsive downstream component.
   --
   overriding procedure Init (Self : in out Instance; Parameter_Table_Length : in Natural; Ticks_Until_Timeout : in Natural) is
   begin
      -- Just save off the init parameters so we can use them later.
      -- The implementation of this component assumes that the parameter table length fits cleanly in a maximum sized packet.
      pragma Assert (Self.Parameter_Table_Length + Crc_16.Crc_16_Type'Length <= Packet_Types.Packet_Buffer_Type'Length, "The parameter table must not be larger than the maximum size packet!");
      Self.Parameter_Table_Length := Parameter_Table_Length;
      -- Save the ticks until timeout.
      Self.Sync_Object.Set_Timeout_Limit (Ticks_Until_Timeout);

      -- Allocate our temporary storage region. See more details in the .ads for why this is needed.
      Self.Parameter_Bytes := new Basic_Types.Byte_Array (0 .. Self.Parameter_Table_Length - 1);
      -- Create a memory region that points to this buffer:
      Self.Parameter_Bytes_Region := (Address => Self.Parameter_Bytes.all'Address, Length => Self.Parameter_Bytes.all'Length);
   end Init;

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The component should be attached to a periodic tick that is used to timeout waiting for a parameter update/fetch response. See the ticks_Until_Timeout initialization parameter.
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

   -- Parameter update/fetch responses are returned synchronously on this connector. The component waits internally for this response, or times out if the response is not received in time.
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

   -- Helper which sends a memory region request (set/get) to the default store.
   function Copy_To_From_Default (Self : in out Instance; Request : in Parameters_Memory_Region.T) return Boolean is
   begin
      -- First, clear the state of the synchronization
      -- object. This prevents us from just "falling through" the
      -- wait call below if some errant response was sent through
      -- to us while we were not listening.
      -- This also resets the timeout counter, so we start
      -- fresh.
      Self.Sync_Object.Reset;

      -- Send the request to the default component.
      Self.Default_Parameters_Memory_Region_Send (Request);

      -- OK now we wait for and check the response.
      if not Self.Wait_For_Response then
         return False;
      end if;

      return True;
   end Copy_To_From_Default;

   -- Helper which sends a memory region request (set/get) to the default store.
   function Copy_To_From_Working (Self : in out Instance; Request : in Parameters_Memory_Region.T) return Boolean is
   begin
      -- First, clear the state of the synchronization
      -- object. This prevents us from just "falling through" the
      -- wait call below if some errant response was sent through
      -- to us while we were not listening.
      -- This also resets the timeout counter, so we start
      -- fresh.
      Self.Sync_Object.Reset;

      -- Send the request to the default component.
      Self.Working_Parameters_Memory_Region_Send (Request);

      -- OK now we wait for and check the response.
      if not Self.Wait_For_Response then
         return False;
      end if;

      return True;
   end Copy_To_From_Working;

   -- Helper function which copies parameter table data from default to working.
   function Copy_Default_To_Working (Self : in out Instance) return Command_Execution_Status.E is
      use Command_Execution_Status;
      use Parameter_Enums.Parameter_Table_Operation_Type;
   begin
      -- Send a get request to default:
      if not Self.Copy_To_From_Default ((Region => Self.Parameter_Bytes_Region, Operation => Get)) then
         return Failure;
      end if;

      --
      -- Ok, now we have valid parameter data from the source component. Time to send
      -- it to the destination.
      --

      -- Send a set request to working:
      if not Self.Copy_To_From_Working ((Region => Self.Parameter_Bytes_Region, Operation => Set)) then
         return Failure;
      end if;

      return Success;
   end Copy_Default_To_Working;

   -- Helper function which copies parameter table data from working to default.
   function Copy_Working_To_Default (Self : in out Instance) return Command_Execution_Status.E is
      use Command_Execution_Status;
      use Parameter_Enums.Parameter_Table_Operation_Type;
   begin
      -- Send a get request to default:
      if not Self.Copy_To_From_Working ((Region => Self.Parameter_Bytes_Region, Operation => Get)) then
         return Failure;
      end if;

      --
      -- Ok, now we have valid parameter data from the source component. Time to send
      -- it to the destination.
      --

      -- Send a set request to working:
      if not Self.Copy_To_From_Default ((Region => Self.Parameter_Bytes_Region, Operation => Set)) then
         return Failure;
      end if;

      return Success;
   end Copy_Working_To_Default;

   -----------------------------------------------
   -- Command handler primitives:
   -----------------------------------------------
   -- Description:
   --    These are the commands for the Parameter Store component.
   -- Copy parameter table from source to destination based on the enumeration provided.
   overriding function Copy_Parameter_Table (Self : in out Instance; Arg : in Packed_Parameter_Table_Copy_Type.T) return Command_Execution_Status.E is
      use Command_Execution_Status;
      use Parameter_Manager_Enums.Parameter_Table_Copy_Type;
      To_Return : Command_Execution_Status.E;
   begin
      -- Info event:
      Self.Event_T_Send_If_Connected (Self.Events.Starting_Parameter_Table_Copy (Self.Sys_Time_T_Get, Arg));

      -- Determine the copy source and destination and perform copy:
      case Arg.Copy_Type is
         when Default_To_Working =>
            To_Return := Self.Copy_Default_To_Working;
         when Working_To_Default =>
            To_Return := Self.Copy_Working_To_Default;
      end case;

      -- Check the return status:
      if To_Return /= Success then
         -- An error event will have already been sent.
         return To_Return;
      end if;

      -- Info event:
      Self.Event_T_Send_If_Connected (Self.Events.Finished_Parameter_Table_Copy (Self.Sys_Time_T_Get, Arg));

      return Success;
   end Copy_Parameter_Table;

   -- Invalid command handler. This procedure is called when a command's arguments are found to be invalid:
   overriding procedure Invalid_Command (Self : in out Instance; Cmd : in Command.T; Errant_Field_Number : in Unsigned_32; Errant_Field : in Basic_Types.Poly_Type) is
   begin
      -- Throw event:
      Self.Event_T_Send_If_Connected (Self.Events.Invalid_Command_Received (Self.Sys_Time_T_Get, (Id => Cmd.Header.Id, Errant_Field_Number => Errant_Field_Number, Errant_Field => Errant_Field)));
   end Invalid_Command;

end Component.Parameter_Manager.Implementation;
