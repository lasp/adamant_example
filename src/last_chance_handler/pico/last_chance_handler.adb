-- with Ada.Exceptions.Traceback; use Ada.Exceptions.Traceback;
-- with Stack_Trace_Addresses;
-- with Packed_Address;
-- with GNAT.Debug_Utilities;       use GNAT.Debug_Utilities;
with Pico_Uart;
with Ccsds_Space_Packet;
with Ccsds_Primary_Header; use Ccsds_Primary_Header;
with Ccsds_Enums;
with Interfaces; use Interfaces;
with Ada.Unchecked_Conversion;
with Crc_16; use Crc_16;
with Sys_Time;
with Packed_Exception_Occurrence;
with Basic_Types;
with Component.Ccsds_Serial_Interface.Implementation; -- grab sync pattern from here
with System.Storage_Elements; use System.Storage_Elements;
with Pico;

--
-- Info on Ada Exception_Occurence type:
-- https://www.radford.edu/~nokie/classes/320/std_lib_html/ada-exceptions.html#49
--

package body Last_Chance_Handler is

   -- This helper function creates a packed record which holds all the information
   -- related to the exception_occurance.
   function Form_Exception_Data (Error : in Exception_Occurrence) return Packed_Exception_Occurrence.T is
      -- Function to convert a character to a byte:
      function Char_To_Byte is new Ada.Unchecked_Conversion (Source => Character, Target => Unsigned_8);

      -- Grab some information from the Error data structure:
      Name : constant String := Exception_Name (Error);
      Msg : constant String := Exception_Message (Error);

      -- Exception data packed record:
      Packed_Exception_Data : Packed_Exception_Occurrence.T := (
         Exception_Name => [others => 0],
         Exception_Message => [others => 0],
         Stack_Trace_Depth => 0,
         Stack_Trace => [others => (Address => To_Address (Integer_Address (0)))]
      );
   begin
      -- Copy the name into the first section.
      declare
         Copy_Idx : Natural := Packed_Exception_Data.Exception_Name'First;
      begin
         for Char of Name loop
            -- Copy each character:
            Packed_Exception_Data.Exception_Name (Copy_Idx) := Char_To_Byte (Char);

            -- Don't overflow.
            Copy_Idx := Copy_Idx + 1;
            if Copy_Idx > Packed_Exception_Data.Exception_Name'Last then
               exit;
            end if;
         end loop;
      end;

      -- Copy the message into the next section.
      declare
         Copy_Idx : Natural := Packed_Exception_Data.Exception_Message'First;
      begin
         for Char of Msg loop
            -- Copy each character:
            Packed_Exception_Data.Exception_Message (Copy_Idx) := Char_To_Byte (Char);

            -- Don't overflow.
            Copy_Idx := Copy_Idx + 1;
            if Copy_Idx > Packed_Exception_Data.Exception_Message'Last then
               exit;
            end if;
         end loop;
      end;

      -- Copy the stack trace into the next section:
      declare
         -- Copy_Idx : Stack_Trace_Addresses.Unconstrained_Index_Type := Packed_Exception_Data.Stack_Trace'First;
         -- Stack_Depth_Count : constant Interfaces.Unsigned_32 := 0;
         Stack_Depth_Count : constant Interfaces.Unsigned_32 := 0;
      begin
         -- Call to Tracebacks not currently working on the Pico
         -- for Call_Stack_Address of Tracebacks (Error) loop
         --    declare
         --       Addr : constant Packed_Address.T := (Address => Call_Stack_Address);
         --    begin
         --       Packed_Exception_Data.Stack_Trace (Copy_Idx) := Addr;
         --    end;

         --    -- Increment stack depth counter:
         --    Stack_Depth_Count := Stack_Depth_Count + 1;

         --    -- Don't overflow:
         --    Copy_Idx := Copy_Idx + 1;
         --    if Copy_Idx > Packed_Exception_Data.Stack_Trace'Last then
         --       exit;
         --    end if;
         -- end loop;

         -- Save off the stack depth:
         Packed_Exception_Data.Stack_Trace_Depth := Stack_Depth_Count;
      end;

      return Packed_Exception_Data;
   end Form_Exception_Data;

   procedure Last_Wishes (Error : Exception_Occurrence) is
   begin
      -- Set the LED:
      Pico.LED.Set;

      No_Exceptions_Propagated :
      begin
         -- Print the exception information to serial port. This will
         -- likely get dropped by the ground system, since this is a malformed
         -- packet. But if we are not running a ground system, and are just
         -- looking at the serial port in ASCII view, then this will
         -- be a valuable print out.
         -- Pico_Uart.Put_Line (Exception_Information (Error));

         -- We don't need to call these since the Exception_Information
         -- function above prints all these details, but leaving them
         -- here as documentation on what is possible.
         -- Pico_Uart.Put_Line (Exception_Name(Error));
         -- Pico_Uart.Put_Line ("Exception_Message: ");
         -- Pico_Uart.Put_Line (Exception_Message(Error));
         -- Pico_Uart.Put_Line ("Call Stack Addresses: ");
         -- for Call_Stack_Address of Tracebacks (Error) loop
         --      Pico_Uart.Put_Line (Image_C (Call_Stack_Address));
         -- end loop;

         -- Create packet for diagnostic serial port.
         declare
            -- Generate the exception data packed record:
            Packed_Exception_Data : constant Packed_Exception_Occurrence.T := Form_Exception_Data (Error);
            -- Packed_Exception_Data : Packed_Exception_Occurrence.T;
            Packed_Exception_Data_Bytes : constant Packed_Exception_Occurrence.Serialization.Byte_Array
               with Import, Convention => Ada, Address => Packed_Exception_Data'Address;
         begin
            -- Now create telemetry packet:
            declare
               use Basic_Types;

               -- Declare packet:
               Pkt : Ccsds_Space_Packet.T := (
                  Header => (
                     Version => 0,
                     Packet_Type => Ccsds_Enums.Ccsds_Packet_Type.Telemetry,
                     Secondary_Header => Ccsds_Enums.Ccsds_Secondary_Header_Indicator.Secondary_Header_Present,
                     Apid => 97, -- This matches definition in example.assembly.yaml
                     Sequence_Flag => Ccsds_Enums.Ccsds_Sequence_Flag.Unsegmented,
                     Sequence_Count => 0,
                     Packet_Length => Unsigned_16 (Sys_Time.Size_In_Bytes + Packed_Exception_Data_Bytes'Length + Crc_16_Type'Length - 1)
                  ),
                  Data => [others => 0]
               );
               -- Sequence count:
               Cnt : Ccsds_Primary_Header.Ccsds_Sequence_Count_Type := 0;

               -- Overlay a byte array with the Ccsds_Packet:
               pragma Warnings (Off, "overlay changes scalar storage order");
               Pkt_Bytes : Basic_Types.Byte_Array (0 .. Natural (Pkt.Header.Packet_Length) + Ccsds_Primary_Header.Size_In_Bytes)
                  with Import, Convention => Ada, Address => Pkt'Address;
               pragma Warnings (On, "overlay changes scalar storage order");
            begin
               -- Fill packet with exception data (skip timestamp location):
               Pkt.Data (
                  Pkt.Data'First + Sys_Time.Size_In_Bytes ..
                  Pkt.Data'First + Sys_Time.Size_In_Bytes + Packed_Exception_Data_Bytes'Length - 1
               ) := Packed_Exception_Data_Bytes;

               -- Send out packet continuously over serial port and 1553:
               loop
                  -- Flash LED rapidly:
                  Pico.LED.Toggle;

                  -- Set sequence count:
                  Pkt.Header.Sequence_Count := Cnt;

                  -- Compute and fill in crc:
                  declare
                     -- Overlay a byte array with the Ccsds_Packet:
                     pragma Warnings (Off, "overlay changes scalar storage order");
                     Overlay : Basic_Types.Byte_Array (0 .. Natural (Pkt.Header.Packet_Length) + Ccsds_Primary_Header.Size_In_Bytes - Crc_16_Type'Length)
                        with Import, Convention => Ada, Address => Pkt'Address;
                     pragma Warnings (On, "overlay changes scalar storage order");
                     Crc : constant Crc_16_Type := Compute_Crc_16 (Overlay);
                  begin
                     Pkt.Data (
                        Pkt.Data'First + Natural (Pkt.Header.Packet_Length) - Crc_16_Type'Length + 1 ..
                        Pkt.Data'First + Natural (Pkt.Header.Packet_Length)
                     ) := Crc;
                  end;

                  -- Send the packet over serial:
                  Pico_Uart.Send_Byte_Array (Component.Ccsds_Serial_Interface.Implementation.Sync_Pattern & Pkt_Bytes);

                  -- Increment sequence count:
                  Cnt := Cnt + 1;
               end loop;
            end;
         end;

      exception
         when others =>
            null;
      end No_Exceptions_Propagated;

      loop
         -- Loop forever...
         null;
      end loop;
   end Last_Wishes;

end Last_Chance_Handler;
