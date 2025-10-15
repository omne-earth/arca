ARG OPENHANDS_RELEASE=latest
FROM localhost/arca-app:${OPENHANDS_RELEASE}
ARG ARCA_TYPE=atlas
ARG AGENT_SERVER_VERSION=ab36fd6-python
ARG FIREFOX_VERSION=v25.09.1
ARG RUNTIME_VERSION=0.59-nikolaik
USER root

# install development tools
RUN apt-get update -y
RUN apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gpg \
    libdigest-sha3-perl \
    locales \
    skopeo \
    sudo \
    vim                                        

# install systemd requisites
RUN apt install -y \
    dbus \
    iproute2 \
    iptables \
    kmod \
    udev

# install systemd
RUN apt install -y \
    libsystemd0 \
    systemd \
    systemd-sysv

# mask systemd kernel daemons
RUN systemctl mask \
    e2scrub_all.timer \
    e2scrub_reap.service \
    sys-kernel-config.mount \
    sys-kernel-debug.mount \
    sys-kernel-tracing.mount \
    systemd-modules-load.service \
    systemd-udevd-control.socket \
    systemd-udevd-kernel.socket \
    systemd-udevd.service

# mask kernel message from journald
RUN echo "ReadKMsg=no" >> /etc/systemd/journald.conf 

# install docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh \
    && (echo 'a4366aa05f9692b1bff10569ca8f7a46adb0aea2dff8294c8b92a576  get-docker.sh' | sha3sum --check) \
    && sh get-docker.sh \
    && usermod -a -G docker arca

# install caddy
RUN curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor --no-tty -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list \
    && chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && chmod o+r /etc/apt/sources.list.d/caddy-stable.list \
    && apt update \
    && apt -y install caddy

# conditinally copy docker images
RUN mkdir -p /containers && if [ "$ARCA_TYPE" = "atlas" ]; then \
        skopeo copy "docker://docker.io/jlesage/firefox:$FIREFOX_VERSION" "docker-archive:/containers/firefox.tar:jlesage/firefox:$FIREFOX_VERSION" ;\
        skopeo copy "docker://ghcr.io/all-hands-ai/agent-server:$AGENT_SERVER_VERSION" "docker-archive:/containers/agent-server.tar:ghcr.io/all-hands-ai/agent-server:$AGENT_SERVER_VERSION" ;\
        skopeo copy "docker://docker.all-hands.dev/all-hands-ai/runtime:$RUNTIME_VERSION" "docker-archive:/containers/runtime.tar:docker.all-hands.dev/all-hands-ai/runtime:$RUNTIME_VERSION" ;\
    fi

# cleanup
RUN apt clean -y
RUN rm -rf \
    /tmp/* \
    /usr/share/doc/* \
    /usr/share/man/* \
    /usr/share/local/* \
    /var/cache/debconf/* \
    /var/lib/apt/lists/* \
    /var/log/* \
    /var/tmp/*

# setup atlas
COPY ./.bin/atlas /usr/bin/atlas
RUN chmod 755 /usr/bin/atlas

# copy systemd units
COPY ./.systemd/atlas.service /etc/systemd/system/
COPY ./.systemd/arca.service /etc/systemd/system/
COPY ./.systemd/portal.service /etc/systemd/system/
COPY ./.systemd/gateway.service /etc/systemd/system/

RUN chmod 644 /etc/systemd/system/atlas.service
RUN chmod 644 /etc/systemd/system/arca.service
RUN chmod 644 /etc/systemd/system/portal.service
RUN chmod 644 /etc/systemd/system/gateway.service

# enable services, initialized by /sbin/init entrypoint
RUN systemctl disable caddy.service
RUN systemctl enable atlas.service
RUN systemctl enable arca.service
RUN systemctl enable portal.service
RUN systemctl enable gateway.service

# setup arca user
RUN echo "arca:arca"|chpasswd
RUN mkdir -p /home/arca/.openhands/
COPY ./.openhands/settings.json.template /home/arca/.openhands/settings.json
COPY ./.openhands/secrets.json.template /home/arca/.openhands/secrets.json
RUN mkdir -p /home/arca/.firefox/
COPY ./.firefox/config/profile/prefs.js /home/arca/.firefox/config/profile/prefs.js
RUN chown -R arca:arca /home/arca/
RUN chmod -R 770 /home/arca/

# use stop signal instead of sigterm
STOPSIGNAL SIGRTMIN+3

# setup network
EXPOSE 8443

# setup entrypoint to systemd
USER root
WORKDIR /app
ENTRYPOINT [ "/sbin/init", "--log-level=err" ]

# cmd is ignored for system containers
CMD [""]
