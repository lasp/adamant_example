########################################################################
# This script is designed to function with OpenC3 COSMOS's Script Runner
########################################################################
from openc3.script import *

# Clear counts and data products from prior tests:
cmd("Linux_Example Ccsds_Command_Depacketizer_Instance-Reset_Counts")
cmd("Linux_Example Command_Router_Instance-Reset_Data_Products")
wait(0.5)

# Send Noop_Arg command expecting success:
cmd("Linux_Example Command_Router_Instance-Noop_Arg with Value 1")
# Get received Software_Status_Packet:
wait(0.5)
sw_Status = get_tlm_packet("Linux_Example Software_Status_Packet", type='FORMATTED')
# Check succesful command count is 2 and that the last success was Noop_Arg with last Value 1:
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == '2'")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == '3'")
print("Noop_Arg success OK")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Noop_Arg_Last_Value.Value == '1'")
print("Noop_Arg last Value OK")

# Send Noop command expecting failure:
cmd("Linux_Example Command_Router_Instance-Noop_Arg with Value 868")
# Get received Software_Status_Packet:
wait(0.5)
sw_Status = get_tlm_packet("Linux_Example Software_Status_Packet", type='FORMATTED')
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

# Send nominal Validate_Parameter_Table command expecting success:
cmd("Linux_Example Parameter_Manager_Instance-Validate_Parameter_Table with Header.Table_Buffer_Length 24, Header.Crc_Table 33845, Table_Buffer [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]")
# Get received Software_Status_Packet:
wait(0.5)
sw_Status = get_tlm_packet("Linux_Example Software_Status_Packet", type='FORMATTED')
# Check succesful command count is 3 and that it was Validate_Parameter_Table:
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == '3'")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == '5201'")
print("Validate_Parameter_Table success OK")

# Send test Validate_Parameter_Table command with bad CRC expecting Table_Validation_Failure and Memory_Region_Crc_Invalid:
cmd("Linux_Example Parameter_Manager_Instance-Validate_Parameter_Table with Header.Table_Buffer_Length 24, Header.Crc_Table 0, Table_Buffer [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]")
# Get received Software_Status_Packet:
wait(0.5)
sw_Status = get_tlm_packet("Linux_Example Software_Status_Packet", type='FORMATTED')
# Check last failed command count was 2 and that the last success was Validate_Parameter_Table with Status FAILURE:
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == '2'")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == '5201'")
print("Validate_Parameter_Table failure OK")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
print("Validate_Parameter_Table last Status FAILURE OK")

# Send test Validate_Parameter_Table command with bad CRC and length expecting Memory_Region_Length_Mismatch:
cmd("Linux_Example Parameter_Manager_Instance-Validate_Parameter_Table with Header.Table_Buffer_Length 26, Header.Crc_Table 0, Table_Buffer []")
# Get received Software_Status_Packet:
wait(0.5)
sw_Status = get_tlm_packet("Linux_Example Software_Status_Packet", type='FORMATTED')
# Check last failed command count was 3 and that it was Validate_Parameter_Table with Status FAILURE:
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == '3'")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == '5201'")
print("Validate_Parameter_Table failure OK")
check_formatted("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
print("Validate_Parameter_Table last Status FAILURE OK")
