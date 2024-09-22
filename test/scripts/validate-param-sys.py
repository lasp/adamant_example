########################################################################
# This script is designed to function with OpenC3 COSMOS's Script Runner
########################################################################
import struct, sys
sys.path.append('/plugins/DEFAULT/targets_modified')
import crc_16
import test_setup
import linux_example_parameter_table_record as Table_Record

if test_setup.test_setup():

    #############################################################################
    # If this point was reached then begin testing parameter validation functions
    #############################################################################

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
    record.Crc_Calculated = int.from_bytes(crc_16.crc_16(record_byte_array[4:]))
    record.Header.Crc_Table = record.Crc_Calculated
    record_len = len(record_byte_array[8:])

    # Send nominal Validate_Parameter_Table command expecting success:
    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": record_len,
          "Header.Crc_Table": record.Crc_Calculated,
          "Table_Buffer": list(record_byte_array[8:])
    })
    # Check successful command count is 3 and that it was Validate_Parameter_Table with Status SUCCESS:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == 3", 3)
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == 5201")
    #  Check Last_Validation_Version, Crc_Table, and Last_Validation_Status:
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Status == 'SUCCESS'")
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Version == 0.00")
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Crc_Table == " + str(record.Crc_Calculated))
    print("Validate_Parameter_Table SUCCESS OK")

    # Send test Validate_Parameter_Table command with bad CRC expecting Memory_Region_Crc_Invalid, Table_Validation_Failure, and
    # Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": record_len,
          "Header.Crc_Table": 0,
          "Table_Buffer": list(record_byte_array[8:])
    })
    # Check last failed command count was 1 and that it was Validate_Parameter_Table with Status CRC_ERROR:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 1", 3)
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5201")
    print("Validate_Parameter_Table failure OK")
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
    #  Check Last_Validation_Version, Crc_Table, and Last_Validation_Status:
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Status == 'CRC_ERROR'")
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Version == 0.00")
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Crc_Table == 0")
    print("Validate_Parameter_Table last Status CRC_ERROR OK")

    # Send test Validate_Parameter_Table command with bad length expecting Memory_Region_Length_Mismatch, Table_Validation_Failure, and
    # Command_Execution_Failure:
    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": record_len + 1,
          "Header.Crc_Table": record.Crc_Calculated,
          "Table_Buffer": list(record_byte_array[8:])
    })
    # Check last failed command count was 2 and that it was Validate_Parameter_Table with Status LENGTH_ERROR:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 2", 3)
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5201")
    print("Validate_Parameter_Table failure OK")
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
    #  Check Last_Validation_Version, Crc_Table, and Last_Validation_Status:
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Status == 'LENGTH_ERROR'")
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Version == 0.00")
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Crc_Table == " + str(record.Crc_Calculated))
    print("Validate_Parameter_Table last Status LENGTH_ERROR OK")

    # Send test Validate_Parameter_Table command with nominal values, and Osc_A_Freq = 999.0 to trigger the user implemented Validate_Parameters
    # function, expecting Parameter_Validation_Failed, Parameter_Table_Copy_Failure, Table_Validation_Failure, and Command_Execution_Failure
    # Rebuild the parameter table using known invalid Osc_A_Freq value:
    # Build a parameter table using the Adamant packed record definitions:
    record = Table_Record.Linux_Example_Parameter_Table_Record(
        Crc_Calculated=0,
        Header=Table_Record.Parameter_Table_Header(),
        Oscillator_A_Frequency=Table_Record.Packed_F32(999.0),
        Oscillator_A_Amplitude=Table_Record.Packed_F32(5.00),
        Oscillator_A_Offset=Table_Record.Packed_F32(2.50),
        Oscillator_B_Frequency=Table_Record.Packed_F32(0.30),
        Oscillator_B_Amplitude=Table_Record.Packed_F32(-5.00),
        Oscillator_B_Offset=Table_Record.Packed_F32(-2.50)
    )
    record_byte_array = record._to_byte_array().tobytes()
    record.Crc_Calculated = int.from_bytes(crc_16.crc_16(record_byte_array[4:]))
    record.Header.Crc_Table = record.Crc_Calculated
    record_len = len(record_byte_array[8:])

    cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", {
          "Header.Table_Buffer_Length": record_len,
          "Header.Crc_Table": record.Crc_Calculated,
          "Table_Buffer": list(record_byte_array[8:])
    })
    # Check last failed command count was 3 and that it was Validate_Parameter_Table with Status PARAMETER_ERROR:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 3", 3)
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 5201")
    print("Validate_Parameter_Table failure OK")
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
    #  Check Last_Validation_Version, Crc_Table, and Last_Validation_Status:
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Status == 'PARAMETER_ERROR'")
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Last_Validation_Version == 0.00")
    check("Linux_Example Software_Status_Packet Parameter_Manager_Instance.Validation_Status.Crc_Table == " + str(record.Crc_Calculated))
    print("Validate_Parameter_Table last Status PARAMETER_ERROR OK")
