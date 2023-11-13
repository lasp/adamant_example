--------------------------------------------------------------------------------
-- Counter Component Tester Spec
--------------------------------------------------------------------------------

-- Includes:
with Component.Counter_Reciprocal;
with Sys_Time;
with Printable_History;
with Command_Response.Representation;
with Packet.Representation;
with Event.Representation;
with Sys_Time.Representation;
with Packed_U32.Representation;
with Event;
with Operands.Representation;
with Command_Header.Representation;
with Invalid_Command_Info.Representation;

-- This is the counter component.
package Component.Counter.Implementation.Tester is

   use Component.Counter_Reciprocal;
   -- Invoker connector history packages:
   package Command_Response_T_Recv_Sync_History_Package is new Printable_History (Command_Response.T, Command_Response.Representation.Image);
   package Packet_T_Recv_Sync_History_Package is new Printable_History (Packet.T, Packet.Representation.Image);
   package Event_T_Recv_Sync_History_Package is new Printable_History (Event.T, Event.Representation.Image);
   package Sys_Time_T_Return_History_Package is new Printable_History (Sys_Time.T, Sys_Time.Representation.Image);

   -- Event history packages:
   package Set_Count_Command_Received_History_Package is new Printable_History (Packed_U32.T, Packed_U32.Representation.Image);
   package Reset_Count_Command_Received_History_Package is new Printable_History (Natural, Natural'Image);
   package Set_Count_Add_Command_Received_History_Package is new Printable_History (Operands.T, Operands.Representation.Image);
   package Sending_Value_History_Package is new Printable_History (Packed_U32.T, Packed_U32.Representation.Image);
   package Dropped_Command_History_Package is new Printable_History (Command_Header.T, Command_Header.Representation.Image);
   package Invalid_Command_Received_History_Package is new Printable_History (Invalid_Command_Info.T, Invalid_Command_Info.Representation.Image);

   -- Packet history packages:
   package Counter_Value_History_Package is new Printable_History (Packed_U32.T, Packed_U32.Representation.Image);

   -- Component class instance:
   type Instance is new Component.Counter_Reciprocal.Base_Instance with record
      -- The component instance under test:
      Component_Instance : aliased Component.Counter.Implementation.Instance;
      -- Connector histories:
      Command_Response_T_Recv_Sync_History : Command_Response_T_Recv_Sync_History_Package.Instance;
      Packet_T_Recv_Sync_History : Packet_T_Recv_Sync_History_Package.Instance;
      Event_T_Recv_Sync_History : Event_T_Recv_Sync_History_Package.Instance;
      Sys_Time_T_Return_History : Sys_Time_T_Return_History_Package.Instance;
      -- Event histories:
      Set_Count_Command_Received_History : Set_Count_Command_Received_History_Package.Instance;
      Reset_Count_Command_Received_History : Reset_Count_Command_Received_History_Package.Instance;
      Set_Count_Add_Command_Received_History : Set_Count_Add_Command_Received_History_Package.Instance;
      Sending_Value_History : Sending_Value_History_Package.Instance;
      Dropped_Command_History : Dropped_Command_History_Package.Instance;
      Invalid_Command_Received_History : Invalid_Command_Received_History_Package.Instance;
      -- Packet histories:
      Counter_Value_History : Counter_Value_History_Package.Instance;
      -- Booleans to control assertion if message is dropped on async queue:
      Expect_Command_T_Send_Dropped : Boolean := False;
      Command_T_Send_Dropped_Count : Natural := 0;
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
   -- This connector is used to register the components commands with the command router component.
   overriding procedure Command_Response_T_Recv_Sync (Self : in out Instance; Arg : in Command_Response.T);
   -- The packet invoker connector
   overriding procedure Packet_T_Recv_Sync (Self : in out Instance; Arg : in Packet.T);
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
   --    Events for the counter component
   -- Received a Set_Count command.
   overriding procedure Set_Count_Command_Received (Self : in out Instance; Arg : in Packed_U32.T);
   -- Received a Reset_Count command.
   overriding procedure Reset_Count_Command_Received (Self : in out Instance);
   -- Received a Set_Count_Add command.
   overriding procedure Set_Count_Add_Command_Received (Self : in out Instance; Arg : in Operands.T);
   -- Sending the current value out as data product.
   overriding procedure Sending_Value (Self : in out Instance; Arg : in Packed_U32.T);
   -- The component's queue overflowed and the command was dropped.
   overriding procedure Dropped_Command (Self : in out Instance; Arg : in Command_Header.T);
   -- A command was received with invalid parameters.
   overriding procedure Invalid_Command_Received (Self : in out Instance; Arg : in Invalid_Command_Info.T);

   -----------------------------------------------
   -- Packet handler primitives:
   -----------------------------------------------
   -- Description:
   --    Packets for the counter component
   -- The counter value 1.
   overriding procedure Counter_Value (Self : in out Instance; Arg : in Packed_U32.T);

   -----------------------------------------------
   -- Special primitives for activating component
   -- queue:
   -----------------------------------------------
   -- Tell the component to dispatch all items off of its queue:
   not overriding function Dispatch_All (Self : in out Instance) return Natural;
   -- Tell the component to dispatch n items off of its queue:
   not overriding function Dispatch_N (Self : in out Instance; N : in Positive := 1) return Natural;

   ---------------------------------------
   -- Auxillery test functions:
   ---------------------------------------
   function Check_Count (Self : in Instance; Value : in Unsigned_32) return Boolean;

end Component.Counter.Implementation.Tester;
