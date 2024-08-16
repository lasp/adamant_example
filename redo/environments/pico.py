# Import this file to change the default target for a directory to Pico instead of Linux.
from util import target
from os import environ, path

target.set_target_if_not_set("Pico")
try:
    adamant_dir = environ['ADAMANT_DIR']
except KeyError:
    adamant_dir = '/home/user/adamant'
environ["REMOVE_BUILD_PATH"] = path.join(adamant_dir, "src/components/ccsds_serial_interface/uart")
