########################################################################
# This script is designed to function with OpenC3 COSMOS's Script Runner
########################################################################
from openc3.script import *
import struct

# Clear counts and data products from prior tests:
cmd("Linux_Example Ccsds_Command_Depacketizer_Instance-Reset_Counts")
cmd("Linux_Example Command_Router_Instance-Reset_Data_Products")
wait(1.0)

# Send Noop_Arg command expecting success:
cmd("Linux_Example Command_Router_Instance-Noop_Arg with Value 1")
wait(1.0)
# Check succesful command count is 2 and that the last success was Noop_Arg with last Value 1:
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == '2'")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == '3'")
print("Noop_Arg success OK")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Noop_Arg_Last_Value.Value == '1'")
print("Noop_Arg last Value OK")

# Send Noop command expecting failure:
cmd("Linux_Example Command_Router_Instance-Noop_Arg with Value 868")
wait(1.0)
# Check last failed command count was 1 and that it was Noop_Arg with last Value 1:
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == '1'")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == '3'")
print("Noop_Arg failure OK")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Noop_Arg_Last_Value.Value == '868'")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
print("Noop_Arg last Value failure OK")

#############################################################################
# If this point was reached then begin testing parameter validation functions
#############################################################################

# Build a parameter table using bytearrays:
#Osc_A_Freq
Test_Packed_Table = bytearray(struct.pack(">f", 0.30))
#Osc_A_Amp
Test_Packed_Table += bytearray(struct.pack(">f", 5.00))
#Osc_A_Off
Test_Packed_Table += bytearray(struct.pack(">f", 2.50))
#Osc_B_Freq
Test_Packed_Table += bytearray(struct.pack(">f", 0.30))
#Osc_B_Amp
Test_Packed_Table += bytearray(struct.pack(">f", -5.00))
#Osc_B_Off
Test_Packed_Table += bytearray(struct.pack(">f", -2.50))
#Version
Test_Packed_Table += bytearray(struct.pack(">f", 0.0))
#Crc_Table
Test_Packed_Table += bytearray(struct.pack(">h", 0))
#Buffer_Length
Test_Packed_Table += bytearray(struct.pack(">h", 55))

# Send nominal Validate_Parameter_Table command expecting success:
cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", { "Header.Table_Buffer_Length": 24, "Header.Crc_Table": 19692, "Table_Buffer": list(Test_Packed_Table) })
wait(1.0)
# Check succesful command count is 3 and that it was Validate_Parameter_Table:
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == '3'")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == '5201'")
print("Validate_Parameter_Table success OK")

# Send test Validate_Parameter_Table command with bad CRC expecting Memory_Region_Crc_Invalid, Table_Validation_Failure, and Command_Execution_Failure:
cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", { "Header.Table_Buffer_Length": 24, "Header.Crc_Table": 0, "Table_Buffer": list(Test_Packed_Table) })
wait(1.0)
# Check last failed command count was 2 and that it was Validate_Parameter_Table with Status FAILURE:
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == '2'")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == '5201'")
print("Validate_Parameter_Table failure OK")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
print("Validate_Parameter_Table last Status FAILURE OK")

# Send test Validate_Parameter_Table command with bad length expecting Memory_Region_Length_Mismatch, Table_Validation_Failure, and Command_Execution_Failure:
cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", { "Header.Table_Buffer_Length": 26, "Header.Crc_Table": 19692, "Table_Buffer": list(Test_Packed_Table) })
wait(1.0)
# Check last failed command count was 3 and that it was Validate_Parameter_Table with Status FAILURE:
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == '3'")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == '5201'")
print("Validate_Parameter_Table failure OK")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
print("Validate_Parameter_Table last Status FAILURE OK")

# Send test Validate_Parameter_Table command with nominal values, and Osc_A_Freq = 999.0 to trigger the user implemented Validate_Parameters function,
# expecting Parameter_Validation_Failed, Parameter_Table_Copy_Failure, Table_Validation_Failure, and Command_Execution_Failure
# Rebuild the parameter table using known invalid Osc_A_Freq value:
#Osc_A_Freq
Test_Packed_Table = bytearray(struct.pack(">f", 999.0))
#Osc_A_Amp
Test_Packed_Table += bytearray(struct.pack(">f", 5.00))
#Osc_A_Off
Test_Packed_Table += bytearray(struct.pack(">f", 2.50))
#Osc_B_Freq
Test_Packed_Table += bytearray(struct.pack(">f", 0.30))
#Osc_B_Amp
Test_Packed_Table += bytearray(struct.pack(">f", -5.00))
#Osc_B_Off
Test_Packed_Table += bytearray(struct.pack(">f", -2.50))
#Version
Test_Packed_Table += bytearray(struct.pack(">f", 0.0))
#Crc_Table
Test_Packed_Table += bytearray(struct.pack(">h", 0))
#Buffer_Length
Test_Packed_Table += bytearray(struct.pack(">h", 55))

cmd("Linux_Example", "Parameter_Manager_Instance-Validate_Parameter_Table", { "Header.Table_Buffer_Length": 24, "Header.Crc_Table": 65043, "Table_Buffer": list(Test_Packed_Table) })
wait(1.0)
# Check last failed command count was 3 and that it was Validate_Parameter_Table with Status FAILURE:
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == '4'")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == '5201'")
print("Validate_Parameter_Table failure OK")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
print("Validate_Parameter_Table last Status FAILURE OK")
