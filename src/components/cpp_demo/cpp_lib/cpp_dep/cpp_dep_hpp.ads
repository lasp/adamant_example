pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;

package cpp_dep_hpp is

   package Class_Container is
      type Container is limited record
         value : aliased unsigned;  -- /home/user/example/src/components/cpp_demo/cpp_lib/cpp_dep/cpp_dep.hpp:4
      end record
      with Import => True,
           Convention => CPP;

      function New_Container return Container;  -- /home/user/example/src/components/cpp_demo/cpp_lib/cpp_dep/cpp_dep.hpp:7
      pragma CPP_Constructor (New_Container, "_ZN9ContainerC1Ev");

      function get (this : access Container) return unsigned  -- /home/user/example/src/components/cpp_demo/cpp_lib/cpp_dep/cpp_dep.hpp:8
      with Import => True, 
           Convention => CPP, 
           External_Name => "_ZN9Container3getEv";

      procedure set (this : access Container; newValue : unsigned)  -- /home/user/example/src/components/cpp_demo/cpp_lib/cpp_dep/cpp_dep.hpp:9
      with Import => True, 
           Convention => CPP, 
           External_Name => "_ZN9Container3setEj";
   end;
   use Class_Container;
end cpp_dep_hpp;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
