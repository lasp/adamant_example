from openc3.script import *

def clear_counts():
    # Clear counts and data products from prior tests:
    cmd("Linux_Example Fault_Correction_Instance-Reset_Data_Products")
    cmd("Linux_Example Command_Router_Instance-Reset_Data_Products")
    cmd("Linux_Example Ccsds_Command_Depacketizer_Instance-Reset_Counts")

def test_setup():
    clear_counts()
    wait(1)

    # Send Noop_Arg command expecting success:
    cmd("Linux_Example Command_Router_Instance-Noop_Arg with Value 1")
    # Check successful command count is 3 and that the last success was Noop_Arg with last Value 1:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Success_Count.Value == 3", 3)
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Successful_Command.Id == 3")
    print("Noop_Arg success OK")
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Noop_Arg_Last_Value.Value == 1")
    print("Noop_Arg last Value OK")

    # Send Noop command expecting failure:
    cmd("Linux_Example Command_Router_Instance-Noop_Arg with Value 868")
    # Check last failed command count was 1 and that it was Noop_Arg with last Value 1:
    wait_check("Linux_Example Software_Status_Packet Command_Router_Instance.Command_Failure_Count.Value == 1", 3)
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.ID == 3")
    print("Noop_Arg failure OK")
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Noop_Arg_Last_Value.Value == 868")
    check("Linux_Example Software_Status_Packet Command_Router_Instance.Last_Failed_Command.Status == 'FAILURE'")
    print("Noop_Arg last Value failure OK")

    # Clear counts and data products to finish the test setup:
    clear_counts()

    return True
