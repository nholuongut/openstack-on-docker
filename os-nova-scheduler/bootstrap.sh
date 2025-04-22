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

set -xeuo pipefail


# Environment variables default values setup
NOVA_DB_HOST="${NOVA_DB_HOST:-localhost}"
NOVA_DB_USER="${NOVA_DB_USER:-nova}"
#NOVA_DB_PASS
NOVA_RABBITMQ_HOST="${NOVA_RABBITMQ_HOST:-localhost}"
NOVA_RABBITMQ_USER="${NOVA_RABBITMQ_USER:-nova}"
#NOVA_RABBITMQ_PASS
NOVA_IDENTITY_URI="${NOVA_IDENTITY_URI:-http://127.0.0.1:35357}"
NOVA_SERVICE_TENANT_NAME=${NOVA_SERVICE_TENANT_NAME:-service}
NOVA_SERVICE_USER=${NOVA_SERVICE_USER:-nova}
#NOVA_SERVICE_PASS
NOVA_MEMCACHED_SERVERS="${NOVA_MEMCACHED_SERVERS:-}"
NOVA_USE_IRONIC="${NOVA_USE_IRONIC:-false}"
NOVA_NOTIFICATIONS="${NOVA_NOTIFICATIONS:-false}"
NOVA_NOTIFY_ON_STATE_CHANGE="${NOVA_NOTIFY_ON_STATE_CHANGE:-vm_state}"

NOVA_MY_IP="$(ip addr show eth0 | awk -F' +|/' '/global/ {print $3}')"
DATABASE_CONNECTION=\
"mysql://${NOVA_DB_USER}:${NOVA_DB_PASS}@${NOVA_DB_HOST}/nova"
CONFIG_FILE="/etc/nova/nova.conf"

if [ "$NOVA_USE_IRONIC" == "true" ] || [ "$NOVA_USE_IRONIC" == "True" ]; then
    SCHEDULER_HOST_MANAGER=\
"nova.scheduler.ironic_host_manager.IronicHostManager"
    SCHEDULER_USE_BAREMETAL_FILTERS=True
    SCHEDULER_TRACKS_INSTANCE_CHANGES=False
    RAM_ALLOCATION_RATIO="1.0"
    SCHEDULER_USE_BAREMETAL_FILTERS=True
else
    SCHEDULER_HOST_MANAGER="nova.scheduler.host_manager.HostManager"
    SCHEDULER_USE_BAREMETAL_FILTERS=False
    SCHEDULER_TRACKS_INSTANCE_CHANGES=True
    RAM_ALLOCATION_RATIO="1.5"
    SCHEDULER_USE_BAREMETAL_FILTERS=False
fi

if [ "$NOVA_NOTIFICATIONS" == "true" ] \
    || [ "$NOVA_NOTIFICATIONS" == "True" ]; then
     NOTIFICATION_DRIVER="messagingv2"
else
    # Turn off notifications
    NOTIFICATION_DRIVER="noop"
    NOVA_NOTIFY_ON_STATE_CHANGE="None"
fi

# Configure the service with environment variables defined
sed -i -e "s#%DATABASE_CONNECTION%#${DATABASE_CONNECTION}#" \
    -e "s#%NOVA_MY_IP%#${NOVA_MY_IP}#" \
    -e "s#%NOVA_RABBITMQ_HOST%#${NOVA_RABBITMQ_HOST}#" \
    -e "s#%NOVA_RABBITMQ_USER%#${NOVA_RABBITMQ_USER}#" \
    -e "s#%NOVA_RABBITMQ_PASS%#${NOVA_RABBITMQ_PASS}#" \
    -e "s#%NOVA_IDENTITY_URI%#${NOVA_IDENTITY_URI}#" \
    -e "s#%NOVA_SERVICE_TENANT_NAME%#${NOVA_SERVICE_TENANT_NAME}#" \
    -e "s#%NOVA_SERVICE_USER%#${NOVA_SERVICE_USER}#" \
    -e "s#%NOVA_SERVICE_PASS%#${NOVA_SERVICE_PASS}#" \
    -e "s#%NOVA_MEMCACHED_SERVERS%#${NOVA_MEMCACHED_SERVERS}#" \
    -e "s#%SCHEDULER_HOST_MANAGER%#${SCHEDULER_HOST_MANAGER}#" \
    -e "s#%SCHEDULER_USE_BAREMETAL_FILTERS%#${SCHEDULER_USE_BAREMETAL_FILTERS}#" \
    -e "s#%SCHEDULER_TRACKS_INSTANCE_CHANGES%#${SCHEDULER_TRACKS_INSTANCE_CHANGES}#" \
    -e "s#%RAM_ALLOCATION_RATIO%#${RAM_ALLOCATION_RATIO}#" \
    -e "s#%NOVA_NOTIFY_ON_STATE_CHANGE%#${NOVA_NOTIFY_ON_STATE_CHANGE}#" \
    -e "s#%NOTIFICATION_DRIVER%#${NOTIFICATION_DRIVER}#" "$CONFIG_FILE"

# Start the service
nova-scheduler
