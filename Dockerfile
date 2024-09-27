FROM ubuntu:22.04 AS builder

ENV USER=lmxserver USER_ID=1000 USER_GID=1000

RUN groupadd --gid "${USER_GID}" "${USER}" && \
    useradd \
      --uid ${USER_ID} \
      --gid ${USER_GID} \
      --create-home \
      --shell /bin/bash \
      ${USER}

RUN apt-get update && apt-get -y install wget perl sudo

# Install LM-X server + Rizom Lab vendor plugin
WORKDIR /install

RUN wget https://www.rizom-lab.com/floating_tools/linux/liblmxvendor.so \
    && wget https://www.rizom-lab.com/floating_tools/linux/lmx-enduser-tools_linux_x64.tar \
    && tar -xvf lmx-enduser-tools_linux_x64.tar

RUN printf "\ny\nn\nn\n" | ./lmx-enduser-tools_linux_x64.sh -- -e accept -l /install/liblmxvendor.so -i /usr/lmxserver -u lmxserver

RUN rm /usr/lmxserver/*.jar \
    && rm /usr/lmxserver/lmxendutil

# Map logs to a separate folder
RUN mkdir /logs \
    && chown $USER_ID:$USER_GID /logs

# Map config files to a separate folder
RUN mkdir /config \
    && chown $USER_ID:$USER_GID /config \
    && mv /usr/lmxserver/lmx-serv.cfg /config \
    && ln -s /config/lmx-serv.cfg /usr/lmxserver/lmx-serv.cfg

# Prepare minimal-specific folders

RUN mkdir -p /minimal

# Setup an empty temp folder
RUN mkdir -p /minimal/var/tmp && chmod 755 /minimal/var && chmod 1777 /minimal/var/tmp

# Extract all license server dependencies
RUN ldd /usr/lmxserver/lmx-serv | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname /minimal%); cp -p % /minimal%;'

# Extract only necessary LM-X license server files from installation
RUN mkdir -p /minimal/usr/lmxserver \
    && chown lmxserver /minimal/usr/lmxserver \
    && cp -p /usr/lmxserver/lmx-serv /minimal/usr/lmxserver \
    && cp -p /usr/lmxserver/lmx-serv.cfg /minimal/usr/lmxserver

# Include lmxserver user & group
RUN mkdir -p /minimal/etc \
    && chmod ugo+r /minimal/etc \
    && cp -p /etc/passwd /minimal/etc/passwd \
    && cp -p /etc/group /minimal/etc/group

#########################################################################

FROM scratch AS minimal

ENV USER=lmxserver

USER ${USER}

# Add minimal-specific folders:
#   LM-X server
#   dependencies
#   etc/passwd, /etc/group
#   /var/tmp
COPY --from=builder /minimal /

# Map logs to a separate folder
COPY --from=builder --chown=lmxserver /logs /logs

# Map config files to a separate folder
COPY --from=builder --chown=lmxserver /config /config

# Include 'stdbuf' utility
COPY --from=builder --chown=lmxserver /usr/bin/stdbuf /usr/bin/stdbuf
COPY --from=builder --chown=lmxserver /usr/libexec/coreutils/libstdbuf.so /usr/libexec/coreutils/libstdbuf.so

# LM-X server communicates over port 6200, TCP+UDP
EXPOSE 6200/udp
EXPOSE 6200/tcp

ENTRYPOINT [ "stdbuf", "--output=L", "/usr/lmxserver/lmx-serv" ]
CMD [ "-logfile", "/logs/lmx-serv.log", "-licpath", "/config/license.lic" ]

###########################################################################

FROM ubuntu:20.04 AS regular

ENV USER=lmxserver USER_ID=1000 USER_GID=1000

RUN groupadd --gid "${USER_GID}" "${USER}" && \
    useradd \
      --uid ${USER_ID} \
      --gid ${USER_GID} \
      --create-home \
      --shell /bin/bash \
      ${USER}

# Add LM-X server application
COPY --from=builder /usr/lmxserver /usr/lmxserver

# Map logs to a separate folder
RUN mkdir /logs \
    && chown $USER_ID:$USER_GID /logs

# Map config file to a separate folder
RUN mkdir /config \
    && chown $USER_ID:$USER_GID /config \
    && mv /usr/lmxserver/lmx-serv.cfg /config \
    && ln -s /config/lmx-serv.cfg /usr/lmxserver/lmx-serv.cfg

# LM-X server communicates over port 6200, TCP+UDP
EXPOSE 6200/udp
EXPOSE 6200/tcp

USER ${USER}

ENTRYPOINT [ "stdbuf", "--output=L", "/usr/lmxserver/lmx-serv" ]
CMD [ "-logfile", "/logs/lmx-serv.log", "-licpath", "/config/license.lic" ]

