with Ada.Text_IO; use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Exceptions; use Ada.Exceptions;
with Linux_Example;
with Last_Chance_Handler;
pragma Unreferenced (Last_Chance_Handler);

procedure Main is
   Wait_Time : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Microseconds (1000000);
   Start_Time : constant Ada.Real_Time.Time := Ada.Real_Time.Clock + Wait_Time;
begin
   ---- Set up the assembly:
   Linux_Example.Init_Base;
   Linux_Example.Set_Id_Bases;
   Linux_Example.Connect_Components;
   Linux_Example.Init_Components;

   -- Start the assembly:
   Put_Line ("Starting Linux demo... Use Ctrl+C to exit.");
   delay until Start_Time;
   Linux_Example.Start_Components;
   Linux_Example.Set_Up_Components;

   -- Loop forever:
   loop
      delay until Clock + Milliseconds (500);
   end loop;

exception
   when Error : others =>
      Put ("Unhandled exception occurred in main: ");
      Put_Line (Exception_Information (Error));
end Main;
