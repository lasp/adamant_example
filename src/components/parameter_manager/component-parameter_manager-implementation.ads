--------------------------------------------------------------------------------
-- Parameter_Manager Component Implementation Spec
--------------------------------------------------------------------------------

-- Includes:
with Tick;
with Command;
with Parameters_Memory_Region_Release;
with Protected_Variables;
with Task_Synchronization;
with Memory_Region;

-- This component is responsible for managing the working, scratch, and default parameter tables. Its sole responsibility is to respond to commands to copy parameter tables from one region to another or to dump the scratch region.
package Component.Parameter_Manager.Implementation is

   -- The component class instance record:
   type Instance is new Parameter_Manager.Base_Instance with private;

   --------------------------------------------------
   -- Subprogram for implementation init method:
   --------------------------------------------------
   -- Initialization parameters for the Parameter Manager.
   --
   -- Init Parameters:
   -- parameter_Table_Length : Natural - The size of the parameter table in bytes. This must be known to the component so it can construct correct sized memory regions for the downstream components.
   -- ticks_Until_Timeout : Natural - The component will wait until it has received at least this many ticks before reporting a timeout error while waiting for a parameter update/fetch response from either the active or default parameter components. For example, if the component is attached to a 10Hz rate group and this value is set to 7, then the component will wait between 700 and 800 ms before declaring a timeout error from an unresponsive downstream component.
   --
   overriding procedure Init (Self : in out Instance; Parameter_Table_Length : in Natural; Ticks_Until_Timeout : in Natural);

private

   -- Create a protected object that holds a memory region release. This will be set synchronously
   -- by the responses from the active/default parameter components, and will be read by this
   -- component, so must be protected to prevent corruption.
   package Protected_Parameters_Memory_Region_Release is new Protected_Variables.Generic_Variable (Parameters_Memory_Region_Release.T);

   -- The component class instance record:
   type Instance is new Parameter_Manager.Base_Instance with record
      -- Memory region release protected variable, set by downstream components.
      Response : Protected_Parameters_Memory_Region_Release.Variable;
      -- Variables used for task synchronization and timeouts:
      Sync_Object : Task_Synchronization.Wait_Release_Timeout_Counter_Object;
      -- Other configuration:
      Parameter_Table_Length : Natural := 0;
      -- Temporary storage to allow safe copying between Default and Working.
      -- We declare this here, instead of as a temporary variable within a function
      -- because if a timeout error occurs, we have no gaurantee that the downstream
      -- component is not reading/writing from this data. If it is declared here, then
      -- at least only this data can be corrupted, and not the stack, which would be
      -- a much worse situation. The assembly should be designed that timeout errors
      -- never occur in order to fully prevent this issue.
      Parameter_Bytes : Basic_Types.Byte_Array_Access;
      -- Create a memory region that points to this buffer:
      Parameter_Bytes_Region : Memory_Region.T;
   end record;

   ---------------------------------------
   -- Set Up Procedure
   ---------------------------------------
   -- Null method which can be implemented to provide some component
   -- set up code. This method is generally called by the assembly
   -- main.adb after all component initialization and tasks have been started.
   -- Some activities need to only be run once at startup, but cannot be run
   -- safely until everything is up and running, ie. command registration, initial
   -- data product updates. This procedure should be implemented to do these things
   -- if necessary.
   overriding procedure Set_Up (Self : in out Instance) is null;

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The component should be attached to a periodic tick that is used to timeout waiting for a parameter update/fetch response. See the ticks_Until_Timeout initialization parameter.
   overriding procedure Timeout_Tick_Recv_Sync (Self : in out Instance; Arg : in Tick.T);
   -- The command receive connector.
   overriding procedure Command_T_Recv_Async (Self : in out Instance; Arg : in Command.T);
   -- This procedure is called when a Command_T_Recv_Async message is dropped due to a full queue.
   overriding procedure Command_T_Recv_Async_Dropped (Self : in out Instance; Arg : in Command.T);
   -- Parameter update/fetch responses are returned synchronously on this connector. The component waits internally for this response, or times out if the response is not received in time.
   overriding procedure Parameters_Memory_Region_Release_T_Recv_Sync (Self : in out Instance; Arg : in Parameters_Memory_Region_Release.T);

   ---------------------------------------
   -- Invoker connector primitives:
   ---------------------------------------
   -- This procedure is called when a Command_Response_T_Send message is dropped due to a full queue.
   overriding procedure Command_Response_T_Send_Dropped (Self : in out Instance; Arg : in Command_Response.T) is null;
   -- This procedure is called when a Working_Parameters_Memory_Region_Send message is dropped due to a full queue.
   overriding procedure Working_Parameters_Memory_Region_Send_Dropped (Self : in out Instance; Arg : in Parameters_Memory_Region.T) is null;
   -- This procedure is called when a Default_Parameters_Memory_Region_Send message is dropped due to a full queue.
   overriding procedure Default_Parameters_Memory_Region_Send_Dropped (Self : in out Instance; Arg : in Parameters_Memory_Region.T) is null;
   -- This procedure is called when a Event_T_Send message is dropped due to a full queue.
   overriding procedure Event_T_Send_Dropped (Self : in out Instance; Arg : in Event.T) is null;

   -----------------------------------------------
   -- Command handler primitives:
   -----------------------------------------------
   -- Description:
   --    These are the commands for the Parameter Store component.
   -- Copy parameter table from source to destination based on the enumeration provided.
   overriding function Copy_Parameter_Table (Self : in out Instance; Arg : in Packed_Parameter_Table_Copy_Type.T) return Command_Execution_Status.E;

   -- Invalid command handler. This procedure is called when a command's arguments are found to be invalid:
   overriding procedure Invalid_Command (Self : in out Instance; Cmd : in Command.T; Errant_Field_Number : in Unsigned_32; Errant_Field : in Basic_Types.Poly_Type);

end Component.Parameter_Manager.Implementation;
