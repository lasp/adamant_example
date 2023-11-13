# Adamant Environment Setup

Below is the procedure for creating the Adamant build environment for the Example Project. Adamant requires quite a few dependencies. To make this easy to manage, a [pre-built Docker image](https://hub.docker.com/r/dinkelk/adamant/tags) is provided to get you started with minimal fuss.

Note, the following has been tested successfully on MacOS, Ubuntu Linux, and Windows with [Git for Windows](https://git-scm.com/download/win) and [WSL](https://learn.microsoft.com/en-us/windows/wsl/install). If you cannot get things working on your machine, please submit an issue or a fix via pull request.

## Creating the Environment

This procedure is used to create a new Docker container that hosts the Adamant build environment. This is only meant to be run once. If you have already created the container, proceed to the next section to start the container.

 1. Start by downloading [Docker Desktop](https://www.docker.com/products/docker-desktop/).
 2. Next, create a new project directory and clone both the [Adamant](https://github.com/lasp/adamant) and [Example](https://github.com/lasp/adamant) repositories.

   ```
   $ mkdir project
   $ cd project
   $ git clone https://github.com/lasp/example.git
   $ git clone https://github.com/lasp/adamant.git
   ```

 3. Next, tell Docker to create a new container from the [pre-built image](https://hub.docker.com/r/dinkelk/adamant/tags). This make take a few minutes and ~6 GB of disk space. By default the container created is named `adamant_example_container`. To change this, or the image that the container uses, modify `docker_config.sh` before running the commands below.

   ```
   $ cd example/docker
   $ ./create_container.sh
   ```

 4. Finally, you can log into the container by running.

   ```
   $ ./login_container.sh
   ```

The `example/` and `adamant/` directories in `project/` will be shared with the new Docker container at `~/example/` and `~/adamant/`.

**Note**: The entire `project/` directory on the host is shared with the Docker container via a bind mount at `/share/`. Compiling
is slow when done on files in a mounted folder, so internal to the Docker container, [unison](https://github.com/bcpierce00/unison) is 
used to bi-directional sync `/share/adamant/` and `/share/example/` to `~/adamant/` and `~/example/` respectively. This significantly increases the performance
of the build system. Be aware that there can be some latency or other issues with the internal sync when changing git branches, cleaning, or making
other changes that modify many files quickly. If you get stuck, try restarting the container via `./stop_container.sh` and `./start_container.sh`.

## Starting and Stopping the Container 

Once you have created a container using the section above you can stop it by running.

  ```
  $ ./stop_container.sh
  ```

To start the container up again, run:

  ```
  $ ./start_container.sh
  ```

## Running the Example Project

To build and run the example project (for Linux) we need to first log in to the container.

  ```
  $ ./login_container.sh
  ```

From within the container run:

  ```
  user@1234$ cd ~/example/src/assembly/linux/main
  user@1234$ redo run
  ```

## Building the Docker Image from Scratch

The procedures above use the [pre-built Docker](https://hub.docker.com/r/dinkelk/adamant/tags) image. You can recreate this image locally using the provided `Dockerfile`. If you have
not already, clone both the [Adamant](https://github.com/lasp/adamant) and [Example](https://github.com/lasp/adamant) repositories into a project directory.

   ```
   $ mkdir project
   $ cd project
   $ git clone https://github.com/lasp/example.git
   $ git clone https://github.com/lasp/adamant.git
   ```

Next, you can create the Docker image by running:

  ```
  $ cd example/docker
  $ ./build_image.sh
  ```

This may take 30 minutes to 1 hour to complete. By default, the image created is named `dinkelk/adamant:example-latest`. To change this, modify `docker_config.sh` before running `./build_image.sh`.
