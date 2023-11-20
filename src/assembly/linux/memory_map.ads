with Basic_Types;
with Linux_Example_Parameter_Table;

package Memory_Map is

   -- Define parameter store. This is declared as static memory address for linux assembly, but for
   -- an embedded assembly might reference a static address in a non-volatile memory region like MRAM.
   Parameter_Store_Bytes : aliased Basic_Types.Byte_Array := (0 .. Linux_Example_Parameter_Table.Parameter_Table_Size_In_Bytes - 1 => <>);
   Parameter_Store_Bytes_Access : constant Basic_Types.Byte_Array_Access := Parameter_Store_Bytes'Access;

end Memory_Map;
