; This script handles setting some default values during startup
; that are specific to the Example mission:

echo "Setting up Hydra for the Example Assembly."

; Set the CCSDS Header:
set Ccsds_Ground_Command_Header-Ccsds_Primary_Header-Apid = 7
set Ccsds_Ground_Command_Header-Ccsds_Primary_Header-Packet_Type = 1
set Ccsds_Ground_Command_Header-Ccsds_Primary_Header-Secondary_Header = 1

; Send the NOOP command to the assembly to make sure things are working
command_Router_Instance-Noop

echo "Setup complete."
