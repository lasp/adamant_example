########################################################################
# This script is designed to function with OpenC3 COSMOS's Script Runner
########################################################################
import struct, sys
sys.path.append('/plugins/DEFAULT/targets_modified')
import crc_16
import test_setup
import linux_example_parameter_table_record as Table_Record

if test_setup.test_setup():

    #########################################################################
    # If this point was reached then begin testing parameter update functions
    #########################################################################

    # Build a parameter table using the Adamant packed record definitions:
    record = Table_Record.Linux_Example_Parameter_Table_Record(
        Crc_Calculated=0,
        Header=Table_Record.Parameter_Table_Header(),
        Oscillator_A_Frequency=Table_Record.Packed_F32(0.30),
        Oscillator_A_Amplitude=Table_Record.Packed_F32(5.00),
        Oscillator_A_Offset=Table_Record.Packed_F32(2.50),
        Oscillator_B_Frequency=Table_Record.Packed_F32(0.30),
        Oscillator_B_Amplitude=Table_Record.Packed_F32(-5.00),
        Oscillator_B_Offset=Table_Record.Packed_F32(-2.50)
    )
    record_byte_array = record._to_byte_array().tobytes()
    record_len = len(record_byte_array[8:])
    record_crc = int.from_bytes(crc_16.crc_16(record_byte_array[4:]), 'big')

    # Send nominal Update_Parameter_Table command expecting success:
    cmd("Linux_Example", "Parameter_Manager_Instance-Update_Parameter_Table", {
          "Header.Table_Buffer_Length": record_len,
          "Header.Crc_Table": record_crc,
          "Table_Buffer": list(record_byte_array[8:])
      })
    # Check successful command count is 3 and that it was Update_Parameter_Table:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == 3", 3)
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == 5200")
    print("Update_Parameter_Table success OK")

    # Send test Update_Parameter_Table command with bad CRC expecting Memory_Region_Crc_Invalid, Parameter_Table_Copy_Failure,
    # Working_Table_Update_Failure, and Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Update_Parameter_Table", {
          "Header.Table_Buffer_Length": record_len,
          "Header.Crc_Table": 0,
          "Table_Buffer": list(record_byte_array[8:])
      })
    # Check last failed command count was 1 and that it was Update_Parameter_Table with Status FAILURE:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 1", 3)
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5200")
    print("Update_Parameter_Table failure OK")
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
    print("Update_Parameter_Table last Status FAILURE OK")

    # Send test Update_Parameter_Table command with bad length expecting Memory_Region_Length_Mismatch, Parameter_Table_Copy_Failure,
    # Working_Table_Update_Failure, and Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Update_Parameter_Table", {
          "Header.Table_Buffer_Length": record_len + 1,
          "Header.Crc_Table": record_crc,
          "Table_Buffer": list(record_byte_array[8:])
      })
    # Check last failed command count was 2 and that it was Update_Parameter_Table with Status FAILURE:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 2", 3)
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5200")
    print("Update_Parameter_Table failure OK")
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
    print("Update_Parameter_Table last Status FAILURE OK")

    # Send Dump_Parameters command and check against prepared parameter table:
    cmd("Linux_Example", "Parameters_Instance-Dump_Parameters")
    # Check successful command count is 4 and that it was Dump_Parameter_Store:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == 4", 3)
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == 30")
    Active_Parameters_Buffer = get_tlm_buffer("Linux_Example Active_Parameters")
    Buffer = Active_Parameters_Buffer['buffer']
    # Check CRC
    if list(Buffer[16:18]) == record_crc:
      print("Dump_Parameters CRC OK")
    # Check Active_Parameters table buffer:
    if Buffer[18:46] == list(record_byte_array[8:]):
      print("Dump_Parameters values OK")
