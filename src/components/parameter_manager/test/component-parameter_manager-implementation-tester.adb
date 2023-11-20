--------------------------------------------------------------------------------
-- Parameter_Manager Component Tester Body
--------------------------------------------------------------------------------

with String_Util;
with Parameter_Enums;

package body Component.Parameter_Manager.Implementation.Tester is

   ---------------------------------------
   -- Initialize heap variables:
   ---------------------------------------
   procedure Init_Base (Self : in out Instance; Queue_Size : in Natural) is
   begin
      -- Initialize component heap:
      Self.Component_Instance.Init_Base (Queue_Size => Queue_Size);

      -- Initialize tester heap:
      -- Connector histories:
      Self.Command_Response_T_Recv_Sync_History.Init (Depth => 100);
      Self.Working_Parameters_Memory_Region_Recv_Sync_History.Init (Depth => 100);
      Self.Default_Parameters_Memory_Region_Recv_Sync_History.Init (Depth => 100);
      Self.Event_T_Recv_Sync_History.Init (Depth => 100);
      Self.Sys_Time_T_Return_History.Init (Depth => 100);
      -- Event histories:
      Self.Starting_Parameter_Table_Copy_History.Init (Depth => 100);
      Self.Finished_Parameter_Table_Copy_History.Init (Depth => 100);
      Self.Invalid_Command_Received_History.Init (Depth => 100);
      Self.Parameter_Table_Copy_Timeout_History.Init (Depth => 100);
      Self.Parameter_Table_Copy_Failure_History.Init (Depth => 100);
      Self.Command_Dropped_History.Init (Depth => 100);
   end Init_Base;

   procedure Final_Base (Self : in out Instance) is
   begin
      -- Destroy tester heap:
      -- Connector histories:
      Self.Command_Response_T_Recv_Sync_History.Destroy;
      Self.Working_Parameters_Memory_Region_Recv_Sync_History.Destroy;
      Self.Default_Parameters_Memory_Region_Recv_Sync_History.Destroy;
      Self.Event_T_Recv_Sync_History.Destroy;
      Self.Sys_Time_T_Return_History.Destroy;
      -- Event histories:
      Self.Starting_Parameter_Table_Copy_History.Destroy;
      Self.Finished_Parameter_Table_Copy_History.Destroy;
      Self.Invalid_Command_Received_History.Destroy;
      Self.Parameter_Table_Copy_Timeout_History.Destroy;
      Self.Parameter_Table_Copy_Failure_History.Destroy;
      Self.Command_Dropped_History.Destroy;

      -- Destroy component heap:
      Self.Component_Instance.Final_Base;
   end Final_Base;

   ---------------------------------------
   -- Test initialization functions:
   ---------------------------------------
   procedure Connect (Self : in out Instance) is
   begin
      Self.Component_Instance.Attach_Command_Response_T_Send (To_Component => Self'Unchecked_Access, Hook => Self.Command_Response_T_Recv_Sync_Access);
      Self.Component_Instance.Attach_Working_Parameters_Memory_Region_Send (To_Component => Self'Unchecked_Access, Hook => Self.Working_Parameters_Memory_Region_Recv_Sync_Access);
      Self.Component_Instance.Attach_Default_Parameters_Memory_Region_Send (To_Component => Self'Unchecked_Access, Hook => Self.Default_Parameters_Memory_Region_Recv_Sync_Access);
      Self.Component_Instance.Attach_Event_T_Send (To_Component => Self'Unchecked_Access, Hook => Self.Event_T_Recv_Sync_Access);
      Self.Component_Instance.Attach_Sys_Time_T_Get (To_Component => Self'Unchecked_Access, Hook => Self.Sys_Time_T_Return_Access);
      Self.Attach_Timeout_Tick_Send (To_Component => Self.Component_Instance'Unchecked_Access, Hook => Self.Component_Instance.Timeout_Tick_Recv_Sync_Access);
      Self.Attach_Command_T_Send (To_Component => Self.Component_Instance'Unchecked_Access, Hook => Self.Component_Instance.Command_T_Recv_Async_Access);
      Self.Attach_Parameters_Memory_Region_Release_T_Send (To_Component => Self.Component_Instance'Unchecked_Access, Hook => Self.Component_Instance.Parameters_Memory_Region_Release_T_Recv_Sync_Access);
   end Connect;

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- This connector is used to send the command response back to the command router.
   overriding procedure Command_Response_T_Recv_Sync (Self : in out Instance; Arg : in Command_Response.T) is
   begin
      -- Push the argument onto the test history for looking at later:
      Self.Command_Response_T_Recv_Sync_History.Push (Arg);
   end Command_Response_T_Recv_Sync;

   -- Requests to update/fetch the working parameters are made on this connector.
   overriding procedure Working_Parameters_Memory_Region_Recv_Sync (Self : in out Instance; Arg : in Parameters_Memory_Region.T) is
      use Parameter_Enums.Parameter_Table_Operation_Type;
   begin
      -- If it is a get then fill in the data:
      if Arg.Operation = Get then
         declare
            subtype Safe_Byte_Array_Type is Basic_Types.Byte_Array (0 .. Arg.Region.Length - 1);
            Safe_Byte_Array : Safe_Byte_Array_Type with Import, Convention => Ada, Address => Arg.Region.Address;
         begin
            Safe_Byte_Array := Self.Working;
         end;
      end if;

      -- Push the argument onto the test history for looking at later:
      Self.Working_Parameters_Memory_Region_Recv_Sync_History.Push (Arg);
   end Working_Parameters_Memory_Region_Recv_Sync;

   -- Requests to update/fetch the default parameters are made on this connector.
   overriding procedure Default_Parameters_Memory_Region_Recv_Sync (Self : in out Instance; Arg : in Parameters_Memory_Region.T) is
      use Parameter_Enums.Parameter_Table_Operation_Type;
   begin
      -- If it is a get then fill in the data:
      if Arg.Operation = Get then
         declare
            subtype Safe_Byte_Array_Type is Basic_Types.Byte_Array (0 .. Arg.Region.Length - 1);
            Safe_Byte_Array : Safe_Byte_Array_Type with Import, Convention => Ada, Address => Arg.Region.Address;
         begin
            Safe_Byte_Array := Self.Default;
         end;
      end if;

      -- Push the argument onto the test history for looking at later:
      Self.Default_Parameters_Memory_Region_Recv_Sync_History.Push (Arg);
   end Default_Parameters_Memory_Region_Recv_Sync;

   -- The event send connector
   overriding procedure Event_T_Recv_Sync (Self : in out Instance; Arg : in Event.T) is
   begin
      -- Push the argument onto the test history for looking at later:
      Self.Event_T_Recv_Sync_History.Push (Arg);
      -- Dispatch the event to the correct handler:
      Self.Dispatch_Event (Arg);
   end Event_T_Recv_Sync;

   -- The system time is retrieved via this connector.
   overriding function Sys_Time_T_Return (Self : in out Instance) return Sys_Time.T is
      -- Return the system time:
      To_Return : constant Sys_Time.T := Self.System_Time;
   begin
      -- Push the argument onto the test history for looking at later:
      Self.Sys_Time_T_Return_History.Push (To_Return);
      return To_Return;
   end Sys_Time_T_Return;

   ---------------------------------------
   -- Invoker connector primitives:
   ---------------------------------------
   -- This procedure is called when a Command_T_Send message is dropped due to a full queue.
   overriding procedure Command_T_Send_Dropped (Self : in out Instance; Arg : in Command.T) is
      Ignore : Command.T renames Arg;
   begin
      if not Self.Expect_Command_T_Send_Dropped then
         pragma Assert (False, "The component's queue filled up when Command_T_Send was called!");
      else
         Self.Command_T_Send_Dropped_Count := Self.Command_T_Send_Dropped_Count + 1;
         Self.Expect_Command_T_Send_Dropped := False;
      end if;
   end Command_T_Send_Dropped;

   -----------------------------------------------
   -- Event handler primitive:
   -----------------------------------------------
   -- Description:
   --    Events for the Parameter Manager component.
   -- Starting parameter table copy from source to destination.
   overriding procedure Starting_Parameter_Table_Copy (Self : in out Instance; Arg : in Packed_Parameter_Table_Copy_Type.T) is
   begin
      -- Push the argument onto the test history for looking at later:
      Self.Starting_Parameter_Table_Copy_History.Push (Arg);
   end Starting_Parameter_Table_Copy;

   -- Finished parameter table copy from source to destination, without errors.
   overriding procedure Finished_Parameter_Table_Copy (Self : in out Instance; Arg : in Packed_Parameter_Table_Copy_Type.T) is
   begin
      -- Push the argument onto the test history for looking at later:
      Self.Finished_Parameter_Table_Copy_History.Push (Arg);
   end Finished_Parameter_Table_Copy;

   -- A command was received with invalid parameters.
   overriding procedure Invalid_Command_Received (Self : in out Instance; Arg : in Invalid_Command_Info.T) is
   begin
      -- Push the argument onto the test history for looking at later:
      Self.Invalid_Command_Received_History.Push (Arg);
   end Invalid_Command_Received;

   -- A timeout occured while waiting for a parameter table copy operation to complete.
   overriding procedure Parameter_Table_Copy_Timeout (Self : in out Instance) is
      Arg : constant Natural := 0;
   begin
      -- Push the argument onto the test history for looking at later:
      Self.Parameter_Table_Copy_Timeout_History.Push (Arg);
   end Parameter_Table_Copy_Timeout;

   -- A parameter table copy failed.
   overriding procedure Parameter_Table_Copy_Failure (Self : in out Instance; Arg : in Parameters_Memory_Region_Release.T) is
   begin
      -- Push the argument onto the test history for looking at later:
      Self.Parameter_Table_Copy_Failure_History.Push (Arg);
   end Parameter_Table_Copy_Failure;

   -- A command was dropped due to a full queue.
   overriding procedure Command_Dropped (Self : in out Instance; Arg : in Command_Header.T) is
   begin
      -- Push the argument onto the test history for looking at later:
      Self.Command_Dropped_History.Push (Arg);
   end Command_Dropped;

   -----------------------------------------------
   -- Special primitives for activating component
   -- queues:
   -----------------------------------------------
   -- Force the component to drain the entire queue
   not overriding function Dispatch_All (Self : in out Instance) return Natural is
      Num_Dispatched : Natural;
   begin
      Self.Log ("    Dispatching all items off queue.");
      Num_Dispatched := Self.Component_Instance.Dispatch_All;
      Self.Log ("    Dispatched " & String_Util.Trim_Both (Natural'Image (Num_Dispatched)) & " items from queue.");
      return Num_Dispatched;
   end Dispatch_All;

   not overriding function Dispatch_N (Self : in out Instance; N : in Positive := 1) return Natural is
      Num_Dispatched : Natural;
   begin
      Self.Log ("    Dispatching up to " & String_Util.Trim_Both (Positive'Image (N)) & " items from queue.");
      Num_Dispatched := Self.Component_Instance.Dispatch_N (N);
      Self.Log ("    Dispatched " & String_Util.Trim_Both (Natural'Image (Num_Dispatched)) & " items from queue.");
      return Num_Dispatched;
   end Dispatch_N;

   -----------------------------------------------
   -- Custom white-box testing functions:
   -----------------------------------------------
   function Get_Parameter_Bytes_Region (Self : in out Instance) return Memory_Region.T is
   begin
      return Self.Component_Instance.Parameter_Bytes_Region;
   end Get_Parameter_Bytes_Region;

end Component.Parameter_Manager.Implementation.Tester;
