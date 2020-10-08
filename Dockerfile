FROM ubuntu:20.04 AS builder

ENV USER=lmxserver USER_ID=1000 USER_GID=1000

RUN groupadd --gid "${USER_GID}" "${USER}" && \
    useradd \
      --uid ${USER_ID} \
      --gid ${USER_GID} \
      --create-home \
      --shell /bin/bash \
      ${USER}

RUN apt-get update && apt-get -y install wget perl sudo

WORKDIR /install

RUN wget https://www.rizom-lab.com/floating_tools/linux/liblmxvendor.so \
    && wget https://www.rizom-lab.com/floating_tools/linux/lmx-enduser-tools_linux_x64.tar \
    && tar -xvf lmx-enduser-tools_linux_x64.tar

RUN printf "\ny\nn\nn\n" | ./lmx-enduser-tools_linux_x64.sh -- -e accept -l /install/liblmxvendor.so -i /usr/lmxserver -u lmxserver

#####################################################################################

FROM ubuntu:20.04

ENV USER=lmxserver USER_ID=1000 USER_GID=1000

RUN groupadd --gid "${USER_GID}" "${USER}" && \
    useradd \
      --uid ${USER_ID} \
      --gid ${USER_GID} \
      --create-home \
      --shell /bin/bash \
      ${USER}

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

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

CMD [ "/usr/lmxserver/lmx-serv", "-logfile", "/logs/lmx-serv.log", "-licpath", "/config/license.lic" ]
