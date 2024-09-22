with Basic_Types;
with Configuration;

-- Declaration of Parameter Manager types. This ensures that
-- it is NOT just a naked natural, giving the compiler
-- more information to help find errors.
package Parameter_Manager_Types is
   -- Length type:
   subtype Parameter_Manager_Buffer_Length_Type is Natural range 0 .. Configuration.Command_Buffer_Size - 8;
   subtype Parameter_Manager_Buffer_Index_Type is Parameter_Manager_Buffer_Length_Type range 0 .. Parameter_Manager_Buffer_Length_Type'Last - 1;
   -- Buffer type:
   subtype Parameter_Manager_Buffer_Type is Basic_Types.Byte_Array (Parameter_Manager_Buffer_Index_Type);
end Parameter_Manager_Types;
