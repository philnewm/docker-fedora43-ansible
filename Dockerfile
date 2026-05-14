FROM quay.io/fedora/fedora:43-x86_64
LABEL maintainer="philnewm"
ENV container="docker"
ENV pip_packages="ansible"

RUN echo "max_parallel_downloads=20" >> /etc/dnf/dnf.conf

RUN dnf -y update && dnf clean all

# Enable systemd.
RUN dnf5 -y install systemd && dnf5 clean all && \
    (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;

# Ensure systemd-logind is not masked
RUN rm -f /etc/systemd/system/systemd-logind.service;

RUN dnf makecache \
    && dnf -y install \
        uv \
        sudo \
        procps-ng \
        which \
        python3-rpm \
        python3-libdnf5 \
        python3-dnf \
        glibc-langpack-en \
    && dnf5 clean all

RUN echo 'LANG=en_US.UTF-8' > /etc/locale.conf

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN uv pip install $pip_packages --system

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers

# Fix shadow file permissions
# Note https://github.com/rocky-linux/sig-cloud-instance-images/issues/56
RUN chmod 0640 /etc/shadow

# Setup ansible user
RUN set -eux; \
    group=$(if command -v yum >/dev/null 2>&1; then echo wheel; else echo sudo; fi); \
    useradd -m -s /bin/bash ansible; \
    usermod -aG "$group" ansible; \
    echo "ansible ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible; \
    chmod 0644 /etc/sudoers.d/ansible

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]
CMD ["/usr/sbin/init"]
