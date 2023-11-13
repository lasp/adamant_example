pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;
with cpp_dep_hpp;

package cpp_lib_hpp is

   package Class_Counter is
      type Counter is limited record
         count : aliased unsigned;  -- /home/user/example/src/components/cpp_demo/cpp_lib/cpp_lib.hpp:5
         limit : aliased cpp_dep_hpp.Class_Container.Container;  -- /home/user/example/src/components/cpp_demo/cpp_lib/cpp_lib.hpp:6
      end record
      with Import => True,
           Convention => CPP;

      function New_Counter return Counter;  -- /home/user/example/src/components/cpp_demo/cpp_lib/cpp_lib.hpp:9
      pragma CPP_Constructor (New_Counter, "_ZN7CounterC1Ev");

      procedure initialize
        (this : access Counter;
         initialCount : unsigned;
         maxLimit : unsigned)  -- /home/user/example/src/components/cpp_demo/cpp_lib/cpp_lib.hpp:10
      with Import => True, 
           Convention => CPP, 
           External_Name => "_ZN7Counter10initializeEjj";

      function increment (this : access Counter) return unsigned  -- /home/user/example/src/components/cpp_demo/cpp_lib/cpp_lib.hpp:11
      with Import => True, 
           Convention => CPP, 
           External_Name => "_ZN7Counter9incrementEv";
   end;
   use Class_Counter;
end cpp_lib_hpp;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
