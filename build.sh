#!/bin/env bash
set -eu

# This MUST be an absolute path because dnf does not work with relative paths
# as installation root.
INSTROOT="${PWD}/installroot"

# Initialize used variables
IMAGENAME=""
UPDATE="false"

help() {
	cat << EOF
Usage: $(basename "$0") --image <NAME> [--update]

Options:
  -i, --image <NAME>             Name for the container image to build

  -u, --update                   Just update  the image in a container workflow
                                 instead of doung a full rebuild

Builds the base image and stores it in the container storage with the given NAME.
EOF
}

# Parse command line options
if ! ARGS=$(getopt -o i:hu --long image:,help,update -n "build-podman" -- "$@"); then
	echo "Error: Failed to parse options. Please check your command." >&2
	help
fi

eval set -- "${ARGS}"

while true; do
	case "$1" in
		-i | --image)
			IMAGENAME=$2
			shift 2
			;;
		-u | --update)
			UPDATE="true"
			shift
			;;
		-h | --help)
			help
			;;
		--) # End of options
			shift
			break
			;;
		*)
			echo "Internal error in option parsing!" >&2
			exit 1
			;;
	esac
done

if [[ -z ${IMAGENAME}   ]]; then
	echo "Error: Missing image name!"
	help
	exit 1
fi

# Check if we are running in fedowa.
# shellcheck source=/dev/null
. /etc/os-release

if [[ ${ID} != "fedora"   ]]; then
	echo "This script has to be run on Fedora."
	exit 1
fi

version=$(date -u +%Y%m%d.%H%M)
if [[ ${UPDATE} == "true"   ]]; then
	# Updatung the packagesw from inside the image does not need sudo permissions
	# or a rootful container, so we do this as regulöar user.
	podman build \
		--platform linux/riscv64 \
		--from "${IMAGENAME}" \
		--squash-all \
		--build-arg version="${version}" \
		--security-opt=label=type:unconfined_t \
		-f Containerfile.update \
		-t "${IMAGENAME}" .
else
	if [[ -d ${INSTROOT} ]]; then
		sudo rm -rf "${INSTROOT}"
	fi
	sudo mkdir -p "${INSTROOT}"

	sudo dnf --installroot="${INSTROOT}" \
		--setopt="install_weak_deps=False" \
		--assumeyes \
		--forcearch=riscv64 \
		--repofrompath=riscv64,https://riscv-koji.fedoraproject.org/repos-dist/f42/latest/riscv64/ \
		--repofrompath=riscv-staging,https://riscv-koji.fedoraproject.org/repos-dist/f42-staging/latest/riscv64/ \
		install dnf coreutils-full

	sudo dnf --installroot="${INSTROOT}" clean all --assumeyes
	sudo rm -rf "${INSTROOT}"/var/log/*
	sudo rm -rf "${INSTROOT}"/var/cache/*
	sudo rm -rf "${INSTROOT}"/var/tmo/*
	sudo rm -rf "${INSTROOT}"/run/*
	sudo rm -rf "${INSTROOT}"/usr/share/doc/*
	sudo rm -rf "${INSTROOT}"/usr/share/man/*
	sudo rm -rf "${INSTROOT}"/usr/share/info/*

	# Build the container
	sudo podman build \
		--build-arg version="${version}" \
		--platform linux/riscv64 \
		--squash-all \
		--security-opt=label=type:unconfined_t \
		-t "${IMAGENAME}" .
fi
