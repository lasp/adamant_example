from targets.linux import Linux_Debug


class Linux_Viewer(Linux_Debug):
    """Linux_Debug built against counted connectors for the Adamant Viewer."""
    def description(self):
        return ("Same as Linux_Debug. Build it with the counted connector directory in place of the "
                "framework's, through REMOVE_BUILD_PATH and EXTRA_BUILD_PATH.")
