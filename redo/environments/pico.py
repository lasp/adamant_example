# Import this file to change the default target for a directory to Pico instead of Linux.
from environments import modify_build_path
from util import target
from os import path, environ

target.set_target_if_not_set("Pico")
try:
    adamant_dir = environ['ADAMANT_DIR']
except KeyError:
    adamant_dir = '/home/user/adamant'
modify_build_path.remove_from_build_path(path.join(adamant_dir, "src/components/ccsds_serial_interface/uart"))
