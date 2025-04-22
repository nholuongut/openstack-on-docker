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

openstack network delete external
openstack keypair list -f value | awk '{print $1}' \
    | xargs -L1 openstack keypair delete
openstack flavor list -f value | awk '/ParallelsVM/ {print $1}' \
    | xargs -L1 openstack flavor delete
openstack image list -f value | awk '{print $1}' \
    | xargs -L1 openstack image delete
ironic node-list | awk '/\| [0-9a-f]/ { print $2}' \
    | xargs -L1 ironic node-delete
openstack security group list -f value | awk '{print $1}' \
    | xargs -L1 openstack security group delete
