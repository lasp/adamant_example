########################################################################
# This script is designed to function with OpenC3 COSMOS's Script Runner
########################################################################
import struct, sys
sys.path.append('/plugins/DEFAULT/targets_modified')
import crc_16
import test_setup

if test_setup.test_setup():

    #############################################################################
    # If this point was reached then begin testing parameter validation functions
    #############################################################################

    # Build a parameter table using bytearrays:
    # Osc_A_Freq
    Test_Packed_Table = bytearray(struct.pack(">f", 0.30))
    # Osc_A_Amp
    Test_Packed_Table += bytearray(struct.pack(">f", 5.00))
    # Osc_A_Off
    Test_Packed_Table += bytearray(struct.pack(">f", 2.50))
    # Osc_B_Freq
    Test_Packed_Table += bytearray(struct.pack(">f", 0.30))
    # Osc_B_Amp
    Test_Packed_Table += bytearray(struct.pack(">f", -5.00))
    # Osc_B_Off
    Test_Packed_Table += bytearray(struct.pack(">f", -2.50))
    table_length = len(Test_Packed_Table)
    # Version
    #Test_Packed_Table += bytearray(struct.pack(">f", 0.0))
    # Crc_Table
    #Test_Packed_Table += bytearray(struct.pack(">h", 0))
    # Buffer_Length
    #Test_Packed_Table += bytearray(struct.pack(">h", 0))

    #test_crc = crc_16.crc_16(Test_Packed_Table)
    #int_crc = int.from_bytes(test_crc, 'big')
    #print(int_crc) # Remove if CRC fully functional

    # Send nominal Validate_Parameter_Table command expecting success:
    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": table_length,
          "Header.Crc_Table": 19692,
          "Table_Buffer": list(Test_Packed_Table)
    })
    # Check successful command count is 3 and that it was Validate_Parameter_Table:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == 3", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == 5201", 3)
    print("Validate_Parameter_Table success OK")

    # Send test Validate_Parameter_Table command with bad CRC expecting Memory_Region_Crc_Invalid, Table_Validation_Failure, and
    # Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": table_length,
          "Header.Crc_Table": 0,
          "Table_Buffer": list(Test_Packed_Table)
    })
    # Check last failed command count was 2 and that it was Validate_Parameter_Table with Status FAILURE:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 2", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5201", 3)
    print("Validate_Parameter_Table failure OK")
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'", 3)
    print("Validate_Parameter_Table last Status FAILURE OK")

    # Send test Validate_Parameter_Table command with bad length expecting Memory_Region_Length_Mismatch, Table_Validation_Failure, and
    # Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": table_length + 1,
          "Header.Crc_Table": 19692,
          "Table_Buffer": list(Test_Packed_Table)
    })
    # Check last failed command count was 3 and that it was Validate_Parameter_Table with Status FAILURE:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 3", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5201", 3)
    print("Validate_Parameter_Table failure OK")
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'", 3)
    print("Validate_Parameter_Table last Status FAILURE OK")

    # Send test Validate_Parameter_Table command with nominal values, and Osc_A_Freq = 999.0 to trigger the user implemented Validate_Parameters
    # function, expecting Parameter_Validation_Failed, Parameter_Table_Copy_Failure, Table_Validation_Failure, and Command_Execution_Failure
    # Rebuild the parameter table using known invalid Osc_A_Freq value:
    # Osc_A_Freq
    Test_Packed_Table = bytearray(struct.pack(">f", 999.0))
    # Osc_A_Amp
    Test_Packed_Table += bytearray(struct.pack(">f", 5.00))
    # Osc_A_Off
    Test_Packed_Table += bytearray(struct.pack(">f", 2.50))
    # Osc_B_Freq
    Test_Packed_Table += bytearray(struct.pack(">f", 0.30))
    # Osc_B_Amp
    Test_Packed_Table += bytearray(struct.pack(">f", -5.00))
    # Osc_B_Off
    Test_Packed_Table += bytearray(struct.pack(">f", -2.50))
    table_length = len(Test_Packed_Table)
    # Version
    #Test_Packed_Table += bytearray(struct.pack(">f", 0.0))
    # Crc_Table
    #Test_Packed_Table += bytearray(struct.pack(">h", 0))
    # Buffer_Length
    #Test_Packed_Table += bytearray(struct.pack(">h", 55))

    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": table_length,
          "Header.Crc_Table": 65043,
          "Table_Buffer": list(Test_Packed_Table)
    })
    # Check last failed command count was 4 and that it was Validate_Parameter_Table with Status FAILURE:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 4", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5201", 3)
    print("Validate_Parameter_Table failure OK")
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'", 3)
    print("Validate_Parameter_Table last Status FAILURE OK")
