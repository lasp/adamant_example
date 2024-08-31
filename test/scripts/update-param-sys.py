########################################################################
# This script is designed to function with OpenC3 COSMOS's Script Runner
########################################################################
import struct, sys
sys.path.append('/plugins/DEFAULT/targets_modified')
import crc_16
import test_setup

if test_setup.test_setup():

    #########################################################################
    # If this point was reached then begin testing parameter update functions
    #########################################################################

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

    # Send nominal Update_Parameter_Table command expecting success:
    cmd("Linux_Example", "Parameter_Manager_Instance-Update_Parameter_Table", {
          "Header.Table_Buffer_Length": len(Test_Packed_Table),
          "Header.Crc_Table": 19692,
          "Table_Buffer": list(Test_Packed_Table)
      })
    # Check successful command count is 3 and that it was Update_Parameter_Table:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == 3", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == 5200", 3)
    print("Update_Parameter_Table success OK")

    # Send test Update_Parameter_Table command with bad CRC expecting Memory_Region_Crc_Invalid, Parameter_Table_Copy_Failure,
    # Working_Table_Update_Failure, and Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Update_Parameter_Table", {
          "Header.Table_Buffer_Length": len(Test_Packed_Table),
          "Header.Crc_Table": 0,
          "Table_Buffer": list(Test_Packed_Table)
      })
    # Check last failed command count was 2 and that it was Update_Parameter_Table with Status FAILURE:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 2", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5200", 3)
    print("Update_Parameter_Table failure OK")
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'", 3)
    print("Update_Parameter_Table last Status FAILURE OK")

    # Send test Update_Parameter_Table command with bad length expecting Memory_Region_Length_Mismatch, Parameter_Table_Copy_Failure,
    # Working_Table_Update_Failure, and Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Update_Parameter_Table", {
          "Header.Table_Buffer_Length": len(Test_Packed_Table) + 1,
          "Header.Crc_Table": 19692,
          "Table_Buffer": list(Test_Packed_Table)
      })
    # Check last failed command count was 3 and that it was Update_Parameter_Table with Status FAILURE:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 3", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5200", 3)
    print("Update_Parameter_Table failure OK")
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'", 3)
    print("Update_Parameter_Table last Status FAILURE OK")