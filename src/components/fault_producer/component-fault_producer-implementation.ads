--------------------------------------------------------------------------------
-- Fault_Producer Component Implementation Spec
--------------------------------------------------------------------------------

-- Includes:
with Command;

-- This is the fault producer component. It allows you to simulate a fault being triggered in the system by throwing a fault upon command.
package Component.Fault_Producer.Implementation is

   -- The component class instance record:
   type Instance is new Fault_Producer.Base_Instance with private;

private

   -- The component class instance record:
   type Instance is new Fault_Producer.Base_Instance with record
      null;
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
   -- The command receive connector.
   overriding procedure Command_T_Recv_Sync (Self : in out Instance; Arg : in Command.T);

   ---------------------------------------
   -- Invoker connector primitives:
   ---------------------------------------
   -- This procedure is called when a Command_Response_T_Send message is dropped due to a full queue.
   overriding procedure Command_Response_T_Send_Dropped (Self : in out Instance; Arg : in Command_Response.T) is null;
   -- This procedure is called when a Event_T_Send message is dropped due to a full queue.
   overriding procedure Event_T_Send_Dropped (Self : in out Instance; Arg : in Event.T) is null;
   -- This procedure is called when a Fault_T_Send message is dropped due to a full queue.
   overriding procedure Fault_T_Send_Dropped (Self : in out Instance; Arg : in Fault.T) is null;

   -----------------------------------------------
   -- Command handler primitives:
   -----------------------------------------------
   -- Description:
   --    Commands for the fault producer component
   -- Throw the first fault.
   overriding function Throw_Fault_1 (Self : in out Instance) return Command_Execution_Status.E;
   -- Throw the second fault.
   overriding function Throw_Fault_2 (Self : in out Instance) return Command_Execution_Status.E;

   -- Invalid command handler. This procedure is called when a command's arguments are found to be invalid:
   overriding procedure Invalid_Command (Self : in out Instance; Cmd : in Command.T; Errant_Field_Number : in Unsigned_32; Errant_Field : in Basic_Types.Poly_Type);

end Component.Fault_Producer.Implementation;
