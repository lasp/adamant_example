--------------------------------------------------------------------------------
-- C_Demo Component Tester Spec
--------------------------------------------------------------------------------

-- Includes:
with Component.C_Demo_Reciprocal;
with Printable_History;
with Event.Representation;
with Sys_Time.Representation;
with Event;
with Packed_U32.Representation;

-- This component demonstrates how to include and use a C library within an
-- Adamant component.
package Component.C_Demo.Implementation.Tester is

   use Component.C_Demo_Reciprocal;
   -- Invoker connector history packages:
   package Event_T_Recv_Sync_History_Package is new Printable_History (Event.T, Event.Representation.Image);
   package Sys_Time_T_Return_History_Package is new Printable_History (Sys_Time.T, Sys_Time.Representation.Image);

   -- Event history packages:
   package Current_Count_History_Package is new Printable_History (Packed_U32.T, Packed_U32.Representation.Image);

   -- Component class instance:
   type Instance is new Component.C_Demo_Reciprocal.Base_Instance with record
      -- The component instance under test:
      Component_Instance : aliased Component.C_Demo.Implementation.Instance;
      -- Connector histories:
      Event_T_Recv_Sync_History : Event_T_Recv_Sync_History_Package.Instance;
      Sys_Time_T_Return_History : Sys_Time_T_Return_History_Package.Instance;
      -- Event histories:
      Current_Count_History : Current_Count_History_Package.Instance;
   end record;
   type Instance_Access is access all Instance;

   ---------------------------------------
   -- Initialize component heap variables:
   ---------------------------------------
   procedure Init_Base (Self : in out Instance);
   procedure Final_Base (Self : in out Instance);

   ---------------------------------------
   -- Test initialization functions:
   ---------------------------------------
   procedure Connect (Self : in out Instance);

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The event send connector
   overriding procedure Event_T_Recv_Sync (Self : in out Instance; Arg : in Event.T);
   -- The system time is retrieved via this connector.
   overriding function Sys_Time_T_Return (Self : in out Instance) return Sys_Time.T;

   -----------------------------------------------
   -- Event handler primitive:
   -----------------------------------------------
   -- Description:
   --    Events for the c_demo component
   -- Sending the current value out as data product.
   overriding procedure Current_Count (Self : in out Instance; Arg : in Packed_U32.T);

end Component.C_Demo.Implementation.Tester;
