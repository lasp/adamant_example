from targets.arm_bare_board import arm_bare_board
import os.path

#
# This file contains the cross compile build targets for the
# Raspberry Pi Pico microprocessor. It utilizes the embedded-rpi-pico
# runtime provided in the gnat_arm_elf Alire crate.
#


class Pico_Base(arm_bare_board):
    def path_files(self):
        return list(set(super(Pico_Base, self).path_files() + ["Pico"]))


class Pico_Production(Pico_Base):
    def description(self):
        return ("This target compiles for the Raspberry Pi Pico microprocessor. It has optimization enabled and "
                "only enforces the Ada Reference Manual validation checks.")

    def gpr_project_file(self):
        return os.path.join(
            os.environ["EXAMPLE_DIR"],
            "redo"
            + os.sep
            + "targets"
            + os.sep
            + "gpr"
            + os.sep
            + "pico_production.gpr",
        )


class Pico_Development(Pico_Base):
    def description(self):
        return ("This target compiles for the Raspberry Pi Pico microprocessor. It has optimization enabled and "
                "enforces all possible validation checks with pragma Initialize_Scalars enabled.")

    def gpr_project_file(self):
        return os.path.join(
            os.environ["EXAMPLE_DIR"],
            "redo"
            + os.sep
            + "targets"
            + os.sep
            + "gpr"
            + os.sep
            + "pico_development.gpr",
        )


class Pico(Pico_Development):
    def description(self):
        return ("This is the default Raspberry Pi Pico microprocessor cross compile target. This is simply a "
                "rename of Pico_Development.")


class Pico_Debug(Pico_Base):
    def description(self):
        return ("This target compiles for the Raspberry Pi Pico microprocessor. It has optimization disabled in "
                "both the Adamant code and the runtime code. It enforces all possible validation checks with "
                "pragma Initialize_Scalars enabled.")

    def gpr_project_file(self):
        return os.path.join(
            os.environ["EXAMPLE_DIR"],
            "redo" + os.sep + "targets" + os.sep + "gpr" + os.sep + "pico_debug.gpr",
        )


class Pico_Safe(Pico_Base):
    def description(self):
        return """This target compiles for the Raspberry Pi Pico microprocessor. This is the
               last resort image compilation. It has all runtime checks and assertions
               disabled. It has optimization disabled. This is meant to create a different
               binary than the Pico_Production target in order to possibly circumvent any compiler
               bugs or runtime check bugs."""

    def gpr_project_file(self):
        return os.path.join(
            os.environ["EXAMPLE_DIR"],
            "redo"
            + os.sep
            + "targets"
            + os.sep
            + "gpr"
            + os.sep
            + "pico_safe.gpr",
        )


class Pico_Analyze(Pico_Base):
    """Analyze target which runs GNAT SAS in deep mode."""
    def description(self):
        return ("Same as Pico_Debug except it adds deep mode switch for GNAT SAS.")

    def gpr_project_file(self):
        return os.path.join(
            os.environ["EXAMPLE_DIR"],
            "redo"
            + os.sep
            + "targets"
            + os.sep
            + "gpr"
            + os.sep
            + "pico_analyze.gpr",
        )
