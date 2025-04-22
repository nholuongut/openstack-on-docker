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

BASE_CONTAINERS :=	os-mysql \
					os-httpboot \
					os-tftpboot \
					os-rabbitmq \
					os-memcached \
					os-keystone \
					os-glance-registry \
					os-glance-api \
					os-neutron-server \
					os-nova-conductor \
					os-nova-api \
					os-nova-scheduler \
					os-nova-compute \
					os-neutron-dhcp-agent \
					os-neutron-l3-agent \
					os-ironic-conductor \
					os-ironic-api \
					os-swift-proxy \
					os-swift-account \
					os-swift-object \
					os-swift-container
CLEAN_JOBS := $(addprefix clean-,${BASE_CONTAINERS})
BUILD_JOBS := $(addprefix build-,${BASE_CONTAINERS})
TEST_JOBS  := $(addprefix test-,${BASE_CONTAINERS})
BUILD_VERSION ?= latest

# build-os-base-image must be done before anything else
all:
	@$(MAKE) build-os-base-image
	@$(MAKE) ${BUILD_JOBS}

clean: ${CLEAN_JOBS} clean-os-base-image

test: ${TEST_JOBS} test-os-base-image

build-os-base-image: ; @$(MAKE) -s -C os-base-image build

clean-os-base-image: ; @$(MAKE) -s -C os-base-image clean

test-os-base-image: ; @$(MAKE) -s -C os-base-image test

${CLEAN_JOBS}: clean-%: ; @$(MAKE) -s -C $* clean

${BUILD_JOBS}: build-%: ; @$(MAKE) -s -C $* build

${TEST_JOBS}: test-%: ; @$(MAKE) -s -C $* test

.PHONY: all ${CLEAN_JOBS} ${BUILD_JOBS} ${TEST_JOBS}
