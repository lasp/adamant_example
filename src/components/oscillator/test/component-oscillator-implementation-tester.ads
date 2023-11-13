--------------------------------------------------------------------------------
-- Oscillator Component Tester Spec
--------------------------------------------------------------------------------

-- Includes:
with Component.Oscillator_Reciprocal;
with Sys_Time;
with Printable_History;
with Command_Response.Representation;
with Data_Product.Representation;
with Event.Representation;
with Sys_Time.Representation;
with Data_Product;
with Packed_F32.Representation;
with Event;
with Command_Header.Representation;
with Invalid_Command_Info.Representation;
with Invalid_Parameter_Info.Representation;

-- This is the oscillator component.
package Component.Oscillator.Implementation.Tester is

   use Component.Oscillator_Reciprocal;
   -- Invoker connector history packages:
   package Command_Response_T_Recv_Sync_History_Package is new Printable_History (Command_Response.T, Command_Response.Representation.Image);
   package Data_Product_T_Recv_Sync_History_Package is new Printable_History (Data_Product.T, Data_Product.Representation.Image);
   package Event_T_Recv_Sync_History_Package is new Printable_History (Event.T, Event.Representation.Image);
   package Sys_Time_T_Return_History_Package is new Printable_History (Sys_Time.T, Sys_Time.Representation.Image);

   -- Event history packages:
   package Frequency_Value_Set_History_Package is new Printable_History (Packed_F32.T, Packed_F32.Representation.Image);
   package Amplitude_Value_Set_History_Package is new Printable_History (Packed_F32.T, Packed_F32.Representation.Image);
   package Offset_Value_Set_History_Package is new Printable_History (Packed_F32.T, Packed_F32.Representation.Image);
   package Dropped_Command_History_Package is new Printable_History (Command_Header.T, Command_Header.Representation.Image);
   package Invalid_Command_Received_History_Package is new Printable_History (Invalid_Command_Info.T, Invalid_Command_Info.Representation.Image);
   package Invalid_Parameter_Received_History_Package is new Printable_History (Invalid_Parameter_Info.T, Invalid_Parameter_Info.Representation.Image);

   -- Data product history packages:
   package Oscillator_Value_History_Package is new Printable_History (Packed_F32.T, Packed_F32.Representation.Image);

   -- Component class instance:
   type Instance is new Component.Oscillator_Reciprocal.Base_Instance with record
      -- The component instance under test:
      Component_Instance : aliased Component.Oscillator.Implementation.Instance;
      -- Connector histories:
      Command_Response_T_Recv_Sync_History : Command_Response_T_Recv_Sync_History_Package.Instance;
      Data_Product_T_Recv_Sync_History : Data_Product_T_Recv_Sync_History_Package.Instance;
      Event_T_Recv_Sync_History : Event_T_Recv_Sync_History_Package.Instance;
      Sys_Time_T_Return_History : Sys_Time_T_Return_History_Package.Instance;
      -- Event histories:
      Frequency_Value_Set_History : Frequency_Value_Set_History_Package.Instance;
      Amplitude_Value_Set_History : Amplitude_Value_Set_History_Package.Instance;
      Offset_Value_Set_History : Offset_Value_Set_History_Package.Instance;
      Dropped_Command_History : Dropped_Command_History_Package.Instance;
      Invalid_Command_Received_History : Invalid_Command_Received_History_Package.Instance;
      Invalid_Parameter_Received_History : Invalid_Parameter_Received_History_Package.Instance;
      -- Data product histories:
      Oscillator_Value_History : Oscillator_Value_History_Package.Instance;
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
   -- The data product invoker connector
   overriding procedure Data_Product_T_Recv_Sync (Self : in out Instance; Arg : in Data_Product.T);
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
   --    Events for the oscillator component
   -- A new frequency value was set by command
   overriding procedure Frequency_Value_Set (Self : in out Instance; Arg : in Packed_F32.T);
   -- A new amplitude value was set by command
   overriding procedure Amplitude_Value_Set (Self : in out Instance; Arg : in Packed_F32.T);
   -- A new offset value was set by command
   overriding procedure Offset_Value_Set (Self : in out Instance; Arg : in Packed_F32.T);
   -- The component's queue overflowed and the command was dropped.
   overriding procedure Dropped_Command (Self : in out Instance; Arg : in Command_Header.T);
   -- A command was received with invalid parameters.
   overriding procedure Invalid_Command_Received (Self : in out Instance; Arg : in Invalid_Command_Info.T);
   -- A parameter was received with invalid parameters.
   overriding procedure Invalid_Parameter_Received (Self : in out Instance; Arg : in Invalid_Parameter_Info.T);

   -----------------------------------------------
   -- Data product handler primitives:
   -----------------------------------------------
   -- Description:
   --    Data products for the Oscillator component
   -- The current value of the oscillator.
   overriding procedure Oscillator_Value (Self : in out Instance; Arg : in Packed_F32.T);

   -----------------------------------------------
   -- Special primitives for activating component
   -- queue:
   -----------------------------------------------
   -- Tell the component to dispatch all items off of its queue:
   not overriding function Dispatch_All (Self : in out Instance) return Natural;
   -- Tell the component to dispatch n items off of its queue:
   not overriding function Dispatch_N (Self : in out Instance; N : in Positive := 1) return Natural;

   -----------------------------------------------
   -- Special primitives for aiding in the staging,
   -- fetching, and updating of parameters
   -----------------------------------------------
   -- Stage a parameter value within the component
   not overriding function Stage_Parameter (Self : in out Instance; Par : in Parameter.T) return Parameter_Update_Status.E;
   -- Fetch the value of a parameter with the component
   not overriding function Fetch_Parameter (Self : in out Instance; Id : in Parameter_Types.Parameter_Id; Par : out Parameter.T) return Parameter_Update_Status.E;
   -- Tell the component it is OK to atomically update all of its
   -- working parameter values with the staged values.
   not overriding function Update_Parameters (Self : in out Instance) return Parameter_Update_Status.E;

end Component.Oscillator.Implementation.Tester;
