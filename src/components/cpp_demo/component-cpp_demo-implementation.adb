--------------------------------------------------------------------------------
-- Cpp_Demo Component Implementation Body
--------------------------------------------------------------------------------
with Interfaces.C; use Interfaces.C; use Interfaces;

package body Component.Cpp_Demo.Implementation is

   --------------------------------------------------
   -- Subprogram for implementation init method:
   --------------------------------------------------
   -- The init subprogram used to set the rollover limit for the C++ counter class.
   --
   -- Init Parameters:
   -- Limit : Interfaces.Unsigned_32 - The limit at which to roll the counter back to
   -- zero.
   --
   overriding procedure Init (Self : in out Instance; Limit : in Interfaces.Unsigned_32) is
   begin
      cpp_lib_hpp.Class_Counter.initialize (
         this => Self.Counter'Access,
         initialCount => 0,
         maxLimit  => unsigned (Limit)
      );
   end Init;

   ---------------------------------------
   -- Invokee connector primitives:
   ---------------------------------------
   -- The schedule invokee connector
   overriding procedure Tick_T_Recv_Sync (Self : in out Instance; Arg : in Tick.T) is
      New_Count : constant unsigned := cpp_lib_hpp.Class_Counter.increment (
         this => Self.Counter'Access
      );
   begin
      Self.Event_T_Send_If_Connected (
         Self.Events.Current_Count (Self.Sys_Time_T_Get, (Value => Unsigned_32 (New_Count)))
      );
   end Tick_T_Recv_Sync;

end Component.Cpp_Demo.Implementation;
