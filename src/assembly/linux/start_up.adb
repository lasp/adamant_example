with Ada.Task_Termination; use Ada.Task_Termination;
with Ada.Text_IO; use Ada.Text_IO;

package body Start_Up is

   -- Print out task termination information to the user:
   protected body Task_Termination is
      procedure Handler (Cause : Ada.Task_Termination.Cause_Of_Termination; T : Ada.Task_Identification.Task_Id; X : Ada.Exceptions.Exception_Occurrence) is
         use Ada.Task_Identification;
         use Ada.Exceptions;
      begin
         Put ("Task: ");
         Put (Image (T));
         case Cause is
            when Normal =>
               null;
               Put_Line (" exited.");
            when Abnormal =>
               Put_Line (" exited abnormally.");
            when Unhandled_Exception =>
               Put_Line (" exited due to an unhandled exception:");
               Put_Line (Exception_Information (X));
         end case;
      end Handler;
   end Task_Termination;

begin
   -- Set up the fallback handler during elaboration to make sure that
   -- it gets set up before any tasks get started.
   Set_Dependents_Fallback_Handler (Task_Termination.Handler'Access);
end Start_Up;
