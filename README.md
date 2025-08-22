# Custom Fedora riscv64 container base image

## Description

At this time fedora project does not provide a base image for the RISC-V
architecture.

Since I want to play around with podman, RISC-V and Fedora a little bit in a
container environment and test my own software on RISC-V, I made a very
minimalistic base image as a "zero point" for my test images.

This Image only contains DNF5, its dependencies and coreutils. Any other
software from the DNF repositories have to be installed when you build derived
containers.

The build script uses sudo which is neccessary to install into a custom
installation root.

## Where to get the image

If you want to use the base image as a start for yourself pull it using:

```bash
podman pull docker.io/dirk1980/fedora-riscv64:latest
```

Replace podman with docker if you are using docker for your container environment.

In derived container images just use:

```Dockerfile
FROM docker.io/dirk1980/fedora-riscv64:latest
```

## Building the image

If you want to build the image by yourself:

* You may want to change Containerfile to customize the labels of the built
image.

* The build script must be run on Fedora and at least with sudo when doing a
full build. Dnf is used to install the packages into the INSTALLROOT on the host
system, which needs root privilleges, before copying the files into the
container image. So you need sudo permissions on the host running this.

You can do a complete build from scratch (must be done using sudo):

```bash
sudo ./build.sh --image registry/namespace/repo:tag
```

Or just update the packages in your image (does not need sudo privilleges):

```bash
./build.sh --image registry/namespace/repo:tag --update
```

The images are not pushed to a registry by the script, so you have to take care
of that by yourself.
