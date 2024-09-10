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
    # Get table length:
    Table_Length = len(Test_Packed_Table)
    # Append table to Version and get CRC
    CRC_Packed_Table = bytearray(struct.pack(">f", 0.0))
    CRC_Packed_Table += Test_Packed_Table
    Test_CRC = crc_16.crc_16(CRC_Packed_Table)
    Int_CRC = int.from_bytes(Test_CRC, 'big')

    # Send nominal Validate_Parameter_Table command expecting success:
    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": Table_Length,
          "Header.Crc_Table": Int_CRC,
          "Table_Buffer": list(Test_Packed_Table)
    })
    # Check successful command count is 3 and that it was Validate_Parameter_Table with Status SUCCESS:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == 3", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == 5201", 3)
    wait_check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Status == 'SUCCESS'", 3)
    print("Validate_Parameter_Table SUCCESS OK")

    # Send test Validate_Parameter_Table command with bad CRC expecting Memory_Region_Crc_Invalid, Table_Validation_Failure, and
    # Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": Table_Length,
          "Header.Crc_Table": 0,
          "Table_Buffer": list(Test_Packed_Table)
    })
    # Check last failed command count was 1 and that it was Validate_Parameter_Table with Status CRC_ERROR:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 1", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5201", 3)
    print("Validate_Parameter_Table failure OK")
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'", 3)
    wait_check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Status == 'CRC_ERROR'", 3)
    print("Validate_Parameter_Table last Status CRC_ERROR OK")

    # Send test Validate_Parameter_Table command with bad length expecting Memory_Region_Length_Mismatch, Table_Validation_Failure, and
    # Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": Table_Length + 1,
          "Header.Crc_Table": Int_CRC,
          "Table_Buffer": list(Test_Packed_Table)
    })
    # Check last failed command count was 2 and that it was Validate_Parameter_Table with Status LENGTH_ERROR:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 2", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5201", 3)
    print("Validate_Parameter_Table failure OK")
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'", 3)
    wait_check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Status == 'LENGTH_ERROR'", 3)
    print("Validate_Parameter_Table last Status LENGTH_ERROR OK")

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
    # Get table length:
    Table_Length = len(Test_Packed_Table)
    # Version
    CRC_Packed_Table = bytearray(struct.pack(">f", 0.0))
    # Append rest of Test_Packed_Table
    CRC_Packed_Table += Test_Packed_Table

    Test_CRC = crc_16.crc_16(CRC_Packed_Table)
    Int_CRC = int.from_bytes(Test_CRC, 'big')

    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": Table_Length,
          "Header.Crc_Table": Int_CRC,
          "Table_Buffer": list(Test_Packed_Table)
    })
    # Check last failed command count was 3 and that it was Validate_Parameter_Table with Status PARAMETER_ERROR:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 3", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5201", 3)
    print("Validate_Parameter_Table failure OK")
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'", 3)
    wait_check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Status == 'PARAMETER_ERROR'", 3)
    print("Validate_Parameter_Table last Status PARAMETER_ERROR OK")
