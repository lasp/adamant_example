--------------------------------------------------------------------------------
-- Parameter_Manager Component Tester Spec
--------------------------------------------------------------------------------

-- Includes:
with Component.Parameter_Manager_Reciprocal;
with Printable_History;
with Command_Response.Representation;
with Parameters_Memory_Region.Representation;
with Event.Representation;
with Sys_Time.Representation;
with Event;
with Packed_Parameter_Table_Copy_Type.Representation;
with Invalid_Command_Info.Representation;
with Parameters_Memory_Region_Release.Representation;
with Command_Header.Representation;

-- This component is responsible for managing a working and default parameter table. Its sole responsibility is to respond to commands to copy parameter tables from one region to another.
package Component.Parameter_Manager.Implementation.Tester is

   use Component.Parameter_Manager_Reciprocal;
   -- Invoker connector history packages:
   package Command_Response_T_Recv_Sync_History_Package is new Printable_History (Command_Response.T, Command_Response.Representation.Image);
   package Working_Parameters_Memory_Region_Recv_Sync_History_Package is new Printable_History (Parameters_Memory_Region.T, Parameters_Memory_Region.Representation.Image);
   package Default_Parameters_Memory_Region_Recv_Sync_History_Package is new Printable_History (Parameters_Memory_Region.T, Parameters_Memory_Region.Representation.Image);
   package Event_T_Recv_Sync_History_Package is new Printable_History (Event.T, Event.Representation.Image);
   package Sys_Time_T_Return_History_Package is new Printable_History (Sys_Time.T, Sys_Time.Representation.Image);

   -- Event history packages:
   package Starting_Parameter_Table_Copy_History_Package is new Printable_History (Packed_Parameter_Table_Copy_Type.T, Packed_Parameter_Table_Copy_Type.Representation.Image);
   package Finished_Parameter_Table_Copy_History_Package is new Printable_History (Packed_Parameter_Table_Copy_Type.T, Packed_Parameter_Table_Copy_Type.Representation.Image);
   package Invalid_Command_Received_History_Package is new Printable_History (Invalid_Command_Info.T, Invalid_Command_Info.Representation.Image);
   package Parameter_Table_Copy_Timeout_History_Package is new Printable_History (Natural, Natural'Image);
   package Parameter_Table_Copy_Failure_History_Package is new Printable_History (Parameters_Memory_Region_Release.T, Parameters_Memory_Region_Release.Representation.Image);
   package Command_Dropped_History_Package is new Printable_History (Command_Header.T, Command_Header.Representation.Image);

   -- Component class instance:
   type Instance is new Component.Parameter_Manager_Reciprocal.Base_Instance with record
      -- The component instance under test:
      Component_Instance : aliased Component.Parameter_Manager.Implementation.Instance;
      -- Connector histories:
      Command_Response_T_Recv_Sync_History : Command_Response_T_Recv_Sync_History_Package.Instance;
      Working_Parameters_Memory_Region_Recv_Sync_History : Working_Parameters_Memory_Region_Recv_Sync_History_Package.Instance;
      Default_Parameters_Memory_Region_Recv_Sync_History : Default_Parameters_Memory_Region_Recv_Sync_History_Package.Instance;
      Event_T_Recv_Sync_History : Event_T_Recv_Sync_History_Package.Instance;
      Sys_Time_T_Return_History : Sys_Time_T_Return_History_Package.Instance;
      -- Event histories:
      Starting_Parameter_Table_Copy_History : Starting_Parameter_Table_Copy_History_Package.Instance;
      Finished_Parameter_Table_Copy_History : Finished_Parameter_Table_Copy_History_Package.Instance;
      Invalid_Command_Received_History : Invalid_Command_Received_History_Package.Instance;
      Parameter_Table_Copy_Timeout_History : Parameter_Table_Copy_Timeout_History_Package.Instance;
      Parameter_Table_Copy_Failure_History : Parameter_Table_Copy_Failure_History_Package.Instance;
      Command_Dropped_History : Command_Dropped_History_Package.Instance;
      -- Booleans to control assertion if message is dropped on async queue:
      Expect_Command_T_Send_Dropped : Boolean := False;
      Command_T_Send_Dropped_Count : Natural := 0;
      -- Memory regions for simulation:
      Default : Basic_Types.Byte_Array (0 .. 99) := (others => 14);
      Working : Basic_Types.Byte_Array (0 .. 99) := (others => 14);
   end record;
   type Instance_Access is access all Instance;

   ---------------------------------------
   -- Initialize component heap variables:
   ---------------------------------------
   procedure Init_Base (Self : in out Instance; Queue_Size : in Natural);
   procedure Final_Base (Self : in out Instance);

   ---------------------------------------
   -- Test initialization functions:
   ---------------------------------------
   procedure Connect (Self : in out Instance);

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- This connector is used to send the command response back to the command router.
   overriding procedure Command_Response_T_Recv_Sync (Self : in out Instance; Arg : in Command_Response.T);
   -- Requests to update/fetch the working parameters are made on this connector.
   overriding procedure Working_Parameters_Memory_Region_Recv_Sync (Self : in out Instance; Arg : in Parameters_Memory_Region.T);
   -- Requests to update/fetch the default parameters are made on this connector.
   overriding procedure Default_Parameters_Memory_Region_Recv_Sync (Self : in out Instance; Arg : in Parameters_Memory_Region.T);
   -- The event send connector
   overriding procedure Event_T_Recv_Sync (Self : in out Instance; Arg : in Event.T);
   -- The system time is retrieved via this connector.
   overriding function Sys_Time_T_Return (Self : in out Instance) return Sys_Time.T;

   ---------------------------------------
   -- Invoker connector primitives:
   ---------------------------------------
   -- This procedure is called when a Command_T_Send message is dropped due to a full queue.
   overriding procedure Command_T_Send_Dropped (Self : in out Instance; Arg : in Command.T);

   -----------------------------------------------
   -- Event handler primitive:
   -----------------------------------------------
   -- Description:
   --    Events for the Parameter Manager component.
   -- Starting parameter table copy from source to destination.
   overriding procedure Starting_Parameter_Table_Copy (Self : in out Instance; Arg : in Packed_Parameter_Table_Copy_Type.T);
   -- Finished parameter table copy from source to destination, without errors.
   overriding procedure Finished_Parameter_Table_Copy (Self : in out Instance; Arg : in Packed_Parameter_Table_Copy_Type.T);
   -- A command was received with invalid parameters.
   overriding procedure Invalid_Command_Received (Self : in out Instance; Arg : in Invalid_Command_Info.T);
   -- A timeout occured while waiting for a parameter table copy operation to complete.
   overriding procedure Parameter_Table_Copy_Timeout (Self : in out Instance);
   -- A parameter table copy failed.
   overriding procedure Parameter_Table_Copy_Failure (Self : in out Instance; Arg : in Parameters_Memory_Region_Release.T);
   -- A command was dropped due to a full queue.
   overriding procedure Command_Dropped (Self : in out Instance; Arg : in Command_Header.T);

   -----------------------------------------------
   -- Special primitives for activating component
   -- queue:
   -----------------------------------------------
   -- Tell the component to dispatch all items off of its queue:
   not overriding function Dispatch_All (Self : in out Instance) return Natural;
   -- Tell the component to dispatch n items off of its queue:
   not overriding function Dispatch_N (Self : in out Instance; N : in Positive := 1) return Natural;

   -----------------------------------------------
   -- Custom white-box testing functions:
   -----------------------------------------------
   function Get_Parameter_Bytes_Region (Self : in out Instance) return Memory_Region.T;
end Component.Parameter_Manager.Implementation.Tester;
