# Raspberry Pi Pico Demo

 ![`Adamant on the Raspberry Pi Pico`](img/pico.jpg "Adamant on the Raspberry Pi Pico")

This demo will walk you through how to build and deploy an [Adamant](https://github.com/lasp/adamant) assembly onto the
[Raspberry Pi Pico](https://www.raspberrypi.com/products/raspberry-pi-pico/). The
Raspberry Pi Pico is a tiny development board that utilizes the RP2040 microcontroller
with 264kB of SRAM. It is a great platform to demonstrate how Adamant
can be used effectively, even on deeply embedded systems.

## First Things First

 1. Make sure you have your Adamant build [environment](../../../../docker/README.md) set up.
 2. Explore the [design](../doc/pico_example.pdf) of the Pico assembly.
 3. Make sure you are familiar with the Adamant [architecture design](https://github.com/lasp/adamant/blob/main/doc/architecture_description_document/architecture_description_document.pdf) and know where to find the [user guide](https://github.com/lasp/adamant/blob/main/doc/user_guide/user_guide.pdf).

## Board Setup

This demo was prepared using the [Raspberry Pi Pico H](https://www.raspberrypi.com/documentation/microcontrollers/raspberry-pi-pico.html),
although any board in the Pico family should work, a breadboard, micro-USB cable, and the
[Raspberry Pi Debug Probe](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html) or a USB to TTL serial cable.
Two setups are possible: 1) with the Raspberry Pi Debug Probe, which allows for debugging via OpenOCD and GDB or 2) with a USB to TTL serial cable,
which does not allow for debugging.

### With the Debug Probe (Recommended)

 ![`Pico with Debug Probe`](img/pico_probe.jpg "Pico with Debug Probe")

Setup the Pico as shown above with the following connections ([detailed pinout](https://datasheets.raspberrypi.com/pico/Pico-R3-A4-Pinout.pdf)):

 1. USB from PC to Pico Micro-USB connector
 2. USB from PC to Debug Probe Micro-USB connector
 3. Debug Probe "D" connector to Pico SWD JST (DEBUG) connector
 4. Debug Probe "U" connector breaks out to three pins (male)
     * Probe RX (yellow) connected to Pico UART0 TX pin 21
     * Probe TX (orange) connected to Pico UART0 RX pin 22
     * Probe GND (black) connected to Pico GND pin 23

### Without the Debug Probe

 ![`Pico with USB to Serial`](img/pico_usb.jpg "Pico with USB to Serial")

Setup the Pico as shown above with the following connections ([detailed pinout](https://datasheets.raspberrypi.com/pico/Pico-R3-A4-Pinout.pdf)):

 1. USB from PC to Pico Micro-USB connector
 2. USB to TTL serial cable from PC breaks out to three pins (male)
     * USB RX (white) connected to Pico UART0 TX pin 21
     * USB TX (green) connected to Pico UART0 RX pin 22
     * USB GND (black) connected to Pico GND pin 23

## Building the Binary

From this directory in your Adamant environment run:

```
$ redo
```

This will compile the Pico assembly and create `build/bin/Pico/main.elf` and `build/bin/Pico/main.uf2` which will be used in the next section.

## Uploading to the Pico

Now we can upload our freshly compiled binary to the Pico. There are two methods for doing this. The first, using the Raspberry Pi Debug Probe,
will allow for traditional debugging of the running code using GDB. If you do not have a Debug Probe, you can still upload and run the binary
using the second method.

### With the Debug Probe (Recommended)

With the Raspberry Pi Debug Probe we can upload new programs to the Pico, send and receive data on the UART, and perform debugging with GDB.
Before starting, install OpenOCD and GDB on your host machine using [these instructions](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html#installing-tools).

To program the Pico without debugging you can run `./program.sh` from your host machine, or manually run:

```
$ openocd -f interface/cmsis-dap.cfg -f target/rp2040.cfg -c "adapter speed 5000" -c "program build/bin/Pico/main.elf verify reset exit"
```

You may need `sudo`.

To perform debugging with GDB we will need two terminals open on the host machine. In the first, run `./start_openocd.sh` or manually run:

```
$ openocd -f interface/cmsis-dap.cfg -f target/rp2040.cfg -c "adapter speed 5000"
```

Next, start GDB in the second terminal by running `./debug.sh` or manually run:

```
$ gdb build/bin/Pico/main.elf
> target remote localhost:3333
> monitor reset init
> load
> continue
```

From here you can use GDB as you normally would to set break points, pause the program, etc.

You can verify that telemetry is being produced by the Pico by opening the USB serial device on your PC with a program like minicom or screen with a baud rate of 115200, ie.

```
$ screen /dev/ttyACM0 115200
```

### Without the Debug Probe

The Pico can act like a USB storage device, allowing you to program it by simply drag-and-dropping the `.uf2` file onto the device.

 1. With the Pico Micro-USB connector disconnected, push and hold the BOOTSEL button on the Pico.
 2. Connect the Micro-USB connector to your PC.
 3. Once the USB storage device RPI-RP2 automatically mounts on your computer, you can release the BOOTSEL button.
 4. Finally, copy or drag-and-drop `build/bin/Pico/main.uf2` onto the RPI-RP2 device. The program should begin running automatically.

 ![`Copy main.uf2 to RPI-RP2 device`](img/copy_uf2.png "Copy main.uf2 to RPI-RP2 device")

You can verify that telemetry is being produced by the Pico by opening the USB serial device on your PC with a program like minicom or screen with a baud rate of 115200, ie.

```
$ screen /dev/ttyACM0 115200
```

## Commanding and Telemetry with [COSMOS](https://github.com/OpenC3/cosmos)

 ![`Commanding and Telemetry with OpenC3 COSMOS`](img/cosmos.png "Commanding and Telemetry with OpenC3 COSMOS")

To best interact with the Pico assembly, we need to use a ground system interface, such as OpenC3 [COSMOS](https://github.com/OpenC3/cosmos). To install COSMOS, navigate to an appropriate directory on your host machine and clone the COSMOS example project repository:

```
$ git clone https://github.com/openc3/cosmos-project.git
```

The COSMOS Docker container must be configured to use the serial port connected to the Pico.

> **Note for Mac Hosts:** Exposing a serial device from a Mac host to a Docker container is [not yet supported](https://github.com/docker/for-mac/issues/900). This can be worked around by connecting to the serial port on the Mac and forwarding traffic through a TCP socket to COSMOS running on the Docker container. Mac-specific modifications to this tutorial will be noted by "**For Mac**" after applicable steps.

Edit `cosmos-project/compose.yaml` and add the following entry to the `openc3-operator:` section:

```
    devices:
      - /dev/ttyACM0:/dev/tty0
```

Where `/dev/ttyACM0` should correspond to the device file for the Pico's USB port on your host machine. Note that the device name may vary between systems. To find the device file for your USB port, use the following command:

```
$ ls /dev/tty*
```

> **For Mac**, do not add any `devices:`, instead modify `cosmos-project/compose.yaml` to expose TCP port that we will forward the serial traffic over by adding the following entry to the `openc3-operator:` section:
> ```
>     ports:
>       - "2003:2003/tcp"
> ```

Start COSMOS by running:

```
$ cd cosmos-project
$ ./openc3.sh start
```

After the containers start, open a web browser and navigate to `http://localhost:2900`. You will be prompted to configure a password, and then presented with the COSMOS interface. Some modules may still be loading, but after a minute the interface should be complete. Navigate to `ADMIN CONSOLE` and uninstall the "openc3-cosmos-demo" plugin by selecting the `Delete Plugin` icon.

OpenC3 COSMOS runs inside of its own Docker containers. The COSMOS example project provides the necessary tools and commands to create an interface plugin from our generated configuration files. While still in the `cosmos-project` directory, run:

```
$ ./openc3.sh cli generate plugin PICO_EXAMPLE
```

This creates a new directory called `openc3-cosmos-pico-example`. Next, run:

```
$ cd openc3-cosmos-pico-example
$ ../openc3.sh cli generate target PICO_EXAMPLE
```

This creates the plugin directory structure as well as template configuration files that our generated configuration will replace. These files are located at:

```
cosmos-project/openc3-cosmos-pico-example/plugin.txt
cosmos-project/openc3-cosmos-pico-example/targets/PICO_EXAMPLE/cmd_tlm/cmd.txt
cosmos-project/openc3-cosmos-pico-example/targets/PICO_EXAMPLE/cmd_tlm/tlm.txt
```

After installing and running COSMOS we need to build the Pico Example plugin configuration files. This will allow COSMOS to decode telemetry from Adamant running on the Pico and properly format outgoing commands.

These files are autocoded by Adamant. *From the Adamant virtual environment* run:

```
$ cd adamant_example/src/assembly/pico/main
$ redo cosmos_config
```

This generates the command and telemetry configurations in the `adamant_example/src/assembly/pico/build/cosmos/plugin/` directory. Note that the main plugin configuration file is located in `adamant_example/src/assembly/pico/main/cosmos/plugin/`. This file should be reviewed to ensure the interface and required protocols are correct for your configuration. All of these files will be installed into the COSMOS plugin in the following steps.

> **For Mac**, first overwrite the provided `plugin.txt` file with one that is designed for TCP communication.
> ```
> $ cd adamant_example/src/assembly/pico/main/cosmos/plugin
> $ cp plugin.txt.for_mac plugin.txt
> ```

Next, run the helper script to install the Adamant plugin configuration files to the COSMOS plugin directory. *The following should be run from the host machine*. If the COSMOS and Adamant example project directories are adjacent, the command to install the configuration would be:

```
$ cd adamant_example/src/assembly/pico/main
$ ./install_cosmos_plugin.sh ../../../../../cosmos-project/openc3-cosmos-pico-example/
```

The plugin can now be compiled. Next, run:

```
$ cd ../../../../../cosmos-project/openc3-cosmos-pico-example/
$ ../openc3.sh cli rake build VERSION=1.0.0
```

In the COSMOS Admin Console, select `Click to select plugin .gem file to install` and navigate to the compiled plugin gem file at `cosmos-project/openc3-cosmos-pico-example/openc3-cosmos-pico-example-1.0.0.gem` to install the compiled plugin. The plugin is templated to allow changing of parameters such as serial ports, but the default values are already set to correspond with this project.

The plugin will be installed. With the Pico connected and running, the COSMOS Log Messages panel should show that the serial interface has accepted a new connection from Adamant.

> **For Mac**, before COSMOS can connect to the Pico serial stream, we must first forward all the serial data over TCP using the `serial_tcp_bridge.py`. This program depends on pyserial, which we will install first. *From the Mac host run:*
> ```
> $ cd adamant_example/gnd/cosmos
> $ python3 -m venv venv
> $ source venv/bin/activate
> $ pip install pyserial
> ```
> Now run `serial_tcp_bridge.py` with the following arguments:
> ```
> $ python3 serial_tcp_bridge.py --tty /dev/tty.usbmodem22402 --baudrate 115200 --ip 127.0.0.1 --port 2003
> ```
> Make sure to provide the correct device path for your serial device to the `--tty` argument. You should see telemetry packets being received by the bridge program and also by COSMOS.

With COSMOS running, here are some interesting things you can try:

 1. View messages generated from the Pico assembly in the main panel.
 2. View telemetry from the Counter and Oscillator components by opening the `Telemetry Grapher` panel and selecting the "PICO_EXAMPLE" target, "HOUSEKEEPING_PACKET" packet, "OSCILLATOR_A.OSCILLATOR_VALUE.VALUE" as item, and selecting "Add Item".
 3. Send any command by selecting it in the `Command Sender` panel. Try sending a NOOP or changing the Oscillator frequencies by selecting "Oscillator_A-Set_Frequency", changing "Value", and selecting "Send".
 4. View the queue usage for each component by opening the `Packet Viewer` panel and selecting "HOUSEKEEPING_PACKET".

## Commanding and Telemetry with Hydra

 ![`Commanding and Telemetry with Hydra`](img/hydra.jpg "Commanding and Telemetry with Hydra")

*Note that Hydra is not yet publicly available, but will be made so in the future. The instructions below serve as an example of how you could interact with this assembly with any ground system.*

To best interact with the Pico, we need to use a ground system interface, such as Hydra. Before running
Hydra we need to build the Hydra configuration files. This will allow Hydra to decode telemetry from the Pico and properly format
outgoing commands.

From this directory in your Adamant environment run:

```
$ redo hydra_config
```

You can also translate the produced Hydra configuration files to work with another ground system.

Hydra will connect to the serial port on your host machine. You can tell Hydra to connect to the appropriate device by modifying the
[hardware configuration file](hydra/Config/hardware.xml). Change the `port` field in the following line:

```
<hwSerial name="serialPort" port="/dev/ttyACM0" baud="115200" parity="NONE" stopbits="1"/>
```

to the USB serial port from the Pico on your PC. To find the device file for your USB port, use the following command:

```
$ ls /dev/tty*
```

Next, open Hydra on your host machine and select your project directory as `src/assembly/pico/main/hydra`.
Hydra will start up and you should see events being received every two seconds from the Pico over the UART in the main panel.

With Hydra running, here are some interesting things you can try:

 1. View events generated from the Pico in the main panel.
 2. View telemetry from the Counter and Oscillator components by opening the `Display Page -> custom -> plots` panel.
 3. Send any command by double clicking a line in the `View -> All Commands` panel. Try sending a NOOP or changing the Oscillator frequencies.
 4. View the Pico temperature and system voltage by opening the `Display Page -> Ccsds-Product_Packetizer_Instance-Housekeeping_Packet` panel.
 5. View the CPU usage for each active component by opening the `Display Page -> pico_example -> pico_example_cpu_monitor` panel.

## What's Next

Now that you have a Raspberry Pi Pico running Adamant, it is time to make it your own. Try modifying or adding a component. Follow the tutorials
in the [user guide](https://github.com/lasp/adamant/blob/main/doc/user_guide/user_guide.pdf) to get going.

Other things to look at:

 * Check out the example [Linux assembly](../../linux/main/README.md)
 * [Learn more about Ada](https://learn.adacore.com/)
