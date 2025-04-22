#! /usr/bin/env bash
#
# Copyright (c) 2025 Nho Luong <luongutnho@hotmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -uexo pipefail

DOWNLOAD_DIR="$HOME/downloads"

CIDR="10.29.29.0/24"
GATEWAY="10.29.29.1"
START_IP="10.29.29.20"
END_IP="10.29.29.200"
DNS="10.29.29.1"

IMAGES=(
    "http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img"
    "https://cloud-images.ubuntu.com/vivid/current/vivid-server-cloudimg-amd64-disk1.img"
    "https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img"
    "https://download.fedoraproject.org/pub/fedora/linux/releases/22/Cloud/x86_64/Images/Fedora-Cloud-Base-22-20250521.x86_64.qcow2"
)

# -------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

FLAVOR_NAME="ParallelsVM"
NODE_CPUS=1
NODE_RAM=2048
NODE_DISK=8
NODE_ARCH=x86_64


download_if_not_exists() {
    local url="$1"
    local filename="$(basename $1)"

    if [ ! -d "$DOWNLOAD_DIR" ]; then
        mkdir "$DOWNLOAD_DIR"
    fi

    if [ ! -f "$DOWNLOAD_DIR/$filename" ]; then
        curl -L -s -o "$DOWNLOAD_DIR/$filename" "$url"
    fi
}


# -- [ Neutron
neutron net-create \
    --shared \
    --router:external \
    --provider:network_type flat \
    --provider:physical_network external \
    external

neutron subnet-create \
    --name external \
    --gateway "$GATEWAY"\
    --allocation-pool "start=$START_IP,end=$END_IP" \
    --enable-dhcp \
    --dns-nameserver "$DNS" \
    external \
    "$CIDR"

# -- [ Glance
download_if_not_exists \
    http://tarballs.openstack.org/ironic-python-agent/coreos/files/coreos_production_pxe.vmlinuz
download_if_not_exists \
    http://tarballs.openstack.org/ironic-python-agent/coreos/files/coreos_production_pxe_image-oem.cpio.gz

openstack image create \
    --public \
    --container-format aki \
    --disk-format aki \
    --file "$DOWNLOAD_DIR/coreos_production_pxe.vmlinuz" \
    "IPA deploy kernel - x86_64"

kernel_id="$(glance image-list | awk '/IPA deploy kernel - x86_64/ {print $2}')"

openstack image create \
    --public \
    --container-format ari \
    --disk-format ari \
    --file "$DOWNLOAD_DIR/coreos_production_pxe_image-oem.cpio.gz" \
    "IPA deploy initrd - x86_64"

initrd_id="$(glance image-list | awk '/IPA deploy initrd - x86_64/ {print $2}')"

for image in "${IMAGES[@]}"; do
    download_if_not_exists "$image"

    image_basename="$(basename $image)"
    image_name="${image_basename%.*}"

    openstack image create \
        --public \
        --container-format bare \
        --disk-format qcow2 \
        --file "$DOWNLOAD_DIR/$image_basename" \
        "$image_name"
done

# -- [ Nova flavor
openstack flavor create --ram "$NODE_RAM" --disk "$NODE_DISK" --vcpus "$NODE_CPUS" $FLAVOR_NAME
nova flavor-key $FLAVOR_NAME set cpu_arch="$NODE_ARCH"
nova flavor-key $FLAVOR_NAME set capabilities:boot_option="local"

# -- [ Fix quotas for baremetal
nova quota-class-update --instances 1000 default
nova quota-class-update --cores 48000 default
nova quota-class-update --ram 128000000 default

# -- [ Nova Key Pair
nova keypair-add --pub-key ~/.ssh/id_rsa.pub keyp1

# -- [ Ironic
ironic node-create \
    --driver agent_ssh \
    --name "ironic-bm1" \
    --driver-info deploy_kernel="$kernel_id" \
    --driver-info deploy_ramdisk="$initrd_id" \
    --driver-info ssh_username="davide" \
    --driver-info ssh_key_contents="$(cat ~/.ssh/id_rsa)" \
    --driver-info ssh_virt_type="parallels" \
    --driver-info ssh_address="10.211.55.2" \
    --properties capabilities="boot_option:local" \
    --properties memory_mb="$NODE_RAM" \
    --properties cpu_arch="$NODE_ARCH" \
    --properties local_gb="$NODE_DISK" \
    --properties cpus="$NODE_CPUS"

ironic node-update "ironic-bm1" add \
    instance_info/capabilities='{"boot_option": "local"}'

node_uuid="$(ironic node-list | awk '/ironic-bm1/ {print $2}')"

ironic port-create \
    --node "$node_uuid" \
    --address 00:1C:42:89:64:34
