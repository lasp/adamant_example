# Linux Demo

 ![`Adamant running on Linux`](img/linux_cmd_line.png "Adamant running on Linux")

This demo will walk you through how to build and run an [Adamant](https://github.com/lasp/adamant) assembly inside the
Linux development environment. Running Adamant on Linux can aid in designing and troubleshooting many problems before deploying
on more demanding hardware, like the [Raspberry Pi Pico](../../pico/main/README.md).

## First Things First

 1. Make sure you have your Adamant Linux build [environment](../../../../docker/README.md) set up.
 2. Explore the [design](../doc/linux_example.pdf) of the Linux assembly.
 3. Make sure you are familiar with the Adamant [architecture design](https://github.com/lasp/adamant/blob/main/doc/architecture_description_document/architecture_description_document.pdf) and know where to find the [user guide](https://github.com/lasp/adamant/blob/main/doc/user_guide/user_guide.pdf).

## Building and running the Binary

From this directory in your Adamant Linux environment run:

```
$ redo run
```

This will compile the assembly and create the Linux binary at `build/bin/Linux/main.elf`. After compilation is complete
the binary will automatically be started in the terminal. You should begin to see the software output events periodically
as it runs, like:

```
Starting Linux demo... Use Ctrl+C to exit.
0000168822.872929071 - Ccsds_Socket_Interface_Instance.Socket_Connected (0x00000085) : (Ip_Address = [C0 A8 41 02], Port = 2003)
0000168823.861770448 - Counter_Instance.Sending_Value (0x00000091) : (Value = 1)
0000168825.862075414 - Counter_Instance.Sending_Value (0x00000091) : (Value = 2)
0000168827.862054941 - Counter_Instance.Sending_Value (0x00000091) : (Value = 3)
...
```

## Commanding and Telemetry with Hydra

 ![`Commanding and Telemetry with Hydra`](../../pico/main/img/hydra.jpg "Commanding and Telemetry with Hydra")

*Note that Hydra is not yet publicly available, but will be made so in the future. The instructions below serve as an example of how you could interact with this assembly with any ground system.*

To best interact with the Linux assembly, we need to use a ground system interface, such as Hydra. Before running
Hydra we need to build the Hydra configuration files. This will allow Hydra to decode telemetry from the Linux assembly and properly format
outgoing commands.

From this directory in your Adamant environment run:

```
$ redo hydra_config
```

You can also translate the produced Hydra configuration files to work with another ground system.

Hydra will listen on a network socket for connections on port 2003 of your host machine. The Linux assembly will periodically try to
connect to Hydra on this port.

With the Linux assembly running, see the previous section, open Hydra on your host machine and select your project directory as
`src/assembly/linux/main/hydra`.

Hydra will start up and you should see events being received every two seconds from the Linux assembly over the socket in the main panel.

With Hydra running, here are some interesting things you can try:

 1. View events generated from the Linux assembly in the main panel.
 2. View telemetry from the Counter and Oscillator components by opening the `Display Page -> custom -> plots` panel.
 3. Send any command by double clicking a line in the `View -> All Commands` panel. Try sending a NOOP or changing the Oscillator frequencies.
 4. View the queue usage for each component by opening the `Display Page -> linux_example -> linux_example_queue_monitor` panel.
 5. Send an interrupt to the running assembly by running `sh send_interrupt.sh` from a new SSH session within within the Linux environment. You should see the software respond by printing out `Interrupt received` with a time stamp in the terminal where `redo run` was started.

## What's Next

Now that you have Adamant running on Linux, it is time to make it your own. Try modifying or adding a component. Follow the tutorials
in the [user guide](https://github.com/lasp/adamant/blob/main/doc/user_guide/user_guide.pdf) to get going.

Other things to look at:

 * Check out the example running on the [Raspberry Pi Pico](../../pico/main/README.md)
 * [Learn more about Ada](https://learn.adacore.com/)
