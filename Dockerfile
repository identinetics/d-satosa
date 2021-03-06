FROM intra/centos7_py36_base

RUN yum -y update \
 && yum -y install net-tools sudo wget \
 && yum -y install gcc gcc-c++ \
 && yum -y install git python36u-devel \
 && yum -y install libffi-devel libxml2-devel libyaml-devel openssl-devel xmlsec1 xmlsec1-openssl \
 && yum -y install logrotate \
 && yum clean all

#RUN mkdir -p /src/satosa
COPY SATOSA /src/satosa
RUN python3 -m venv /opt/venv \
 && echo 'source /opt/venv/bin/activate' > /etc/profile.d/pyenv.sh \
 && source /etc/profile.d/pyenv.sh \
 && sync \
 && /opt/venv/bin/pip install /src/satosa/[redirecturl]
COPY SATOSA/docker/attributemaps /opt/satosa/attributemaps
COPY SATOSA/docker/start.sh /opt/bin/start.sh
# for debugging:
RUN /opt/venv/bin/pip install autologging

COPY install/bin /opt/bin
COPY install/etc /opt/etc
ENV GUNICORN_CONF=/opt/etc/gunicorn/config.py
COPY install/test /opt/test
ENV DATA_DIR=/opt/etc/satosa
ENV METADATA_DIR=$DATA_DIR/metadata
RUN chmod -R +x /opt/bin/* \
 && adduser --user-group satosa \
 && mkdir -p $DATA_DIR/attributemaps /var/log/satosa /var/run/satosa \
 && chown -R satosa:satosa $DATA_DIR /opt/test /var/log/satosa /var/run/satosa

# satosa-saml-metadata requires valid UTF setting:
ENV LANG=en_US.utf-8
ENV LC_ALL=en_US.utf-8

# silence pip version check for dcshell build number generation
RUN mkdir -p $HOME/.config/pip \
 && printf "[global]\ndisable-pip-version-check = True\n" > $HOME/.config/pip/pip.conf

VOLUME /opt/etc
VOLUME /var/log
CMD ["/opt/bin/start_satosa.sh"]
ARG PROXY_PORT=8080
EXPOSE $PROXY_PORT

# For development/debugging - map port in config and start sshd with /start_sshd.sh
# delete keys to generate them on first container start, not in image
#RUN yum -y install openssh-server \
# && yum clean all
#RUN echo changeit | passwd -f --stdin root \
# && echo 'GSSAPIAuthentication no' >> /etc/ssh/sshd_config \
# && echo 'useDNS no' >> /etc/ssh/sshd_config \
# && rm -f /etc/ssh/ssh_host_*_key
#VOLUME /etc/sshd
#EXPOSE 2022
