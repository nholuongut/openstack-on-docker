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

FROM os-base-image
MAINTAINER Nho Luong <luongutnho@hotmail.com>

# install packages
RUN set -x \
    && apt-get -y update \
    && apt-get -y install \
        ironic-api \
        python-mysqldb \
    && apt-get -y clean \
    && rm -f /var/lib/ironic/ironic.db

# copy config file
COPY ironic.conf /etc/ironic/ironic.conf

# add bootstrap script and make it executable
COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh && chmod a+x /etc/bootstrap.sh

EXPOSE 6385

ENTRYPOINT ["/etc/bootstrap.sh"]
