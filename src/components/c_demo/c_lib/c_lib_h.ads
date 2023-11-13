pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;

package c_lib_h is

  -- C-lib data type
   type c_data is record
      count : aliased unsigned;  -- c_lib.h:3
      limit : aliased unsigned;  -- c_lib.h:4
   end record
   with Convention => C_Pass_By_Copy;  -- c_lib.h:5

  -- C-lib function
   function increment (data : access c_data) return unsigned  -- c_lib.h:8
   with Import => True, 
        Convention => C, 
        External_Name => "increment";

end c_lib_h;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
