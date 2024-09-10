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
    table_length = len(Test_Packed_Table)
    # Append table to Version and get CRC
    CRC_Packed_Table = bytearray(struct.pack(">f", 0.0))
    CRC_Packed_Table += Test_Packed_Table
    Test_CRC = crc_16.crc_16(CRC_Packed_Table)
    Int_CRC = int.from_bytes(Test_CRC, 'big')

    # Send nominal Update_Parameter_Table command expecting success:
    cmd("Linux_Example", "Parameter_Manager_Instance-Update_Parameter_Table", {
          "Header.Table_Buffer_Length": table_length,
          "Header.Crc_Table": Int_CRC,
          "Table_Buffer": list(Test_Packed_Table)
      })
    # Check successful command count is 3 and that it was Update_Parameter_Table:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == 3", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == 5200", 3)
    print("Update_Parameter_Table success OK")

    # Send test Update_Parameter_Table command with bad CRC expecting Memory_Region_Crc_Invalid, Parameter_Table_Copy_Failure,
    # Working_Table_Update_Failure, and Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Update_Parameter_Table", {
          "Header.Table_Buffer_Length": table_length,
          "Header.Crc_Table": 0,
          "Table_Buffer": list(Test_Packed_Table)
      })
    # Check last failed command count was 1 and that it was Update_Parameter_Table with Status FAILURE:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 1", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5200", 3)
    print("Update_Parameter_Table failure OK")
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'", 3)
    print("Update_Parameter_Table last Status FAILURE OK")

    # Send test Update_Parameter_Table command with bad length expecting Memory_Region_Length_Mismatch, Parameter_Table_Copy_Failure,
    # Working_Table_Update_Failure, and Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Update_Parameter_Table", {
          "Header.Table_Buffer_Length": table_length + 1,
          "Header.Crc_Table": Int_CRC,
          "Table_Buffer": list(Test_Packed_Table)
      })
    # Check last failed command count was 2 and that it was Update_Parameter_Table with Status FAILURE:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 2", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5200", 3)
    print("Update_Parameter_Table failure OK")
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'", 3)
    print("Update_Parameter_Table last Status FAILURE OK")

    # Send Dump_Parameters command and check against prepared parameter table:
    cmd("Linux_Example", "Parameters_Instance-Dump_Parameters")
    # Check successful command count is 4 and that it was Dump_Parameter_Store:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == 4", 3)
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == 30", 3)
    Active_Parameters_Buffer = get_tlm_buffer("Linux_Example Active_Parameters")
    Buffer = Active_Parameters_Buffer['buffer']
    # Check CRC
    if list(Buffer[16:18]) == Test_CRC:
      print("Dump_Parameters CRC OK")
    # Check Active_Parameters table buffer:
    if Buffer[18:46] == CRC_Packed_Table:
      print("Dump_Parameters values OK")
