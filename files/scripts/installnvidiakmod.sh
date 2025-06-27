#!/usr/bin/env bash

set -oue pipefail

KERNEL_VERSION="$(rpm -q "kernel" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
RELEASE="$(rpm -E '%fedora.%_arch')"
KERNEL_MODULE_TYPE="kernel"
if [[ "$IMAGE_NAME" == *"open"* ]]; then
    KERNEL_MODULE_TYPE+="-open"
fi

curl -Lo /etc/yum.repos.d/negativo17-fedora-nvidia.repo https://negativo17.org/repos/fedora-nvidia.repo
sed -i '0,/enabled=1/{s/enabled=1/enabled=1\npriority=90/}' /etc/yum.repos.d/negativo17-fedora-nvidia.repo

dnf install -y "kernel-devel-matched-$(rpm -q 'kernel' --queryformat '%{VERSION}')"
dnf install -y "akmod-nvidia*.fc${RELEASE}"

sed -i "s/^MODULE_VARIANT=.*/MODULE_VARIANT=$KERNEL_MODULE_TYPE/" /etc/nvidia/kernel.conf
akmods --force --kernels "${KERNEL_VERSION}" --kmod "nvidia"

# Depends on word splitting
# shellcheck disable=SC2086
modinfo /usr/lib/modules/${KERNEL_VERSION}/extra/nvidia/nvidia{,-drm,-modeset,-peermem,-uvm}.ko.xz > /dev/null || \
    (cat "/var/cache/akmods/nvidia/*.failed.log" && exit 1)

# View license information
# Depends on word splitting
# shellcheck disable=SC2086
modinfo -l /usr/lib/modules/${KERNEL_VERSION}/extra/nvidia/nvidia{,-drm,-modeset,-peermem,-uvm}.ko.xz

#./signmodules.sh "nvidia"

rm -f /etc/yum.repos.d/negativo17-fedora-nvidia.repo

systemctl disable akmods-keygen@akmods-keygen.service
systemctl mask akmods-keygen@akmods-keygen.service
systemctl disable akmods-keygen.target
systemctl mask akmods-keygen.target
