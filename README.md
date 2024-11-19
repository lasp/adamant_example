asdfadsfasd
# Adamant Example Project

[![Build the Linux Assembly](https://github.com/lasp/adamant_example/actions/workflows/build_linux.yml/badge.svg)](https://github.com/lasp/adamant_example/actions/workflows/build_linux.yml)
[![Build the Pico Assembly](https://github.com/lasp/adamant_example/actions/workflows/build_pico.yml/badge.svg)](https://github.com/lasp/adamant_example/actions/workflows/build_pico.yml)
[![Run All Unit Tests](https://github.com/lasp/adamant_example/actions/workflows/test_all.yml/badge.svg)](https://github.com/lasp/adamant_example/actions/workflows/test_all.yml)
[![Check Style](https://github.com/lasp/adamant_example/actions/workflows/style_all.yml/badge.svg)](https://github.com/lasp/adamant_example/actions/workflows/styl_all.yml)
[![Build All Documentation](https://github.com/lasp/adamant_example/actions/workflows/publish_all.yml/badge.svg)](https://github.com/lasp/adamant_example/actions/workflows/publish_all.yml)

This repository contains an example project which utilizes the [Adamant](https://github.com/lasp/adamant) software framework. Its purpose is to demonstrate how the framework can be used to create components, unit test components, and connect those components together into an executable assembly.

The project can be compiled for two different targets, a Linux desktop environment and the [Raspberry Pi Pico](https://www.raspberrypi.com/products/raspberry-pi-pico/).

![`Adamant on the Raspberry Pi Pico`](src/assembly/pico/main/img/pico.jpg "Adamant on the Raspberry Pi Pico")

## Getting Started

 1. First, we need to set up the development environment for the project by following [this guide](docker/README.md).
 2. Build, run, and explore the [Linux assembly](src/assembly/linux/main/README.md).
 3. Build, run, and explore the [Raspberry Pi Pico assembly](src/assembly/pico/main/README.md).
 4. Copy, modify, and adapt the example project for your own project.

## Need Help?

 * Have a question or suggestion? Please use the project's [discussions](https://github.com/lasp/adamant_example/discussions).
 * Find a bug? Please [submit an issue](https://github.com/lasp/adamant_example/issues).

## Contributing

Contributions are welcome! This repository follows the guidelines from the main Adamant repository. For details see [CONTRIBUTING.md](https://github.com/lasp/adamant/blob/main/CONTRIBUTING.md).

## Resources

Below are some helpful resources for learning up on [Adamant](https://github.com/lasp/adamant) and the various tools used in this framework.

 * The design documents for the example assemblies can be found here: [Linux](src/assembly/linux/doc/linux_example.pdf), [Raspberry Pi Pico](src/assembly/pico/doc/pico_example.pdf).
 * The [Architecture Description Document](https://github.com/lasp/adamant/blob/main/doc/architecture_description_document/architecture_description_document.pdf) provides an overview of Adamant's architecture and main concepts.
 * The [User Guide](https://github.com/lasp/adamant/blob/main/doc/user_guide/user_guide.pdf) is a comprehensive resource for developers looking to start using the Adamant framework.
 * New to Ada or SPARK? Learn more [here](https://learn.adacore.com/). But familiar with C++ or Java? Take a look at [this guide](https://learn.adacore.com/courses/Ada_For_The_CPP_Java_Developer/index.html).
 * Learn more about Adamant's [redo](https://github.com/dinkelk/redo)-based build system.

## Directory Structure

The following is a description of what you can expect to find in the subdirectories of this directory.

 * `config/` - Adamant configuration file for the project
 * `env/` - files used for configuring the development environment used by the project
 * `redo/` - [redo](https://github.com/dinkelk/redo) build files for the project
 * `src/` - the source code which makes up the project
 * `docker/` - files for configuring the development environment used for this project
