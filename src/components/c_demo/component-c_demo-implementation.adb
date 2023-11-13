--------------------------------------------------------------------------------
-- C_Demo Component Implementation Body
--------------------------------------------------------------------------------
with Interfaces.C; use Interfaces.C; use Interfaces;

package body Component.C_Demo.Implementation is

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The schedule invokee connector
   overriding procedure Tick_T_Recv_Sync (Self : in out Instance; Arg : in Tick.T) is
      New_Count : constant unsigned := c_lib_h.increment (data => Self.My_C_Data'Access);
   begin
      Self.Event_T_Send_If_Connected (
         Self.Events.Current_Count (Self.Sys_Time_T_Get, (Value => Unsigned_32 (New_Count)))
      );
   end Tick_T_Recv_Sync;

end Component.C_Demo.Implementation;
