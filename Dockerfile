FROM ubuntu

ENV USER=lmxserver USER_ID=1000 USER_GID=1000

RUN groupadd --gid "${USER_GID}" "${USER}" && \
    useradd \
      --uid ${USER_ID} \
      --gid ${USER_GID} \
      --create-home \
      --shell /bin/bash \
      ${USER}

RUN apt-get update && apt-get -y install wget perl sudo

RUN mkdir install \
    && cd install \
    && wget https://www.rizom-lab.com/floating_tools/linux/liblmxvendor.so \
    && wget https://www.rizom-lab.com/floating_tools/linux/lmx-enduser-tools_linux_x64.tar \
    && tar -xvf lmx-enduser-tools_linux_x64.tar \
    && printf "\ny\nn\nn\n" | ./lmx-enduser-tools_linux_x64.sh -- -e accept -l /install/liblmxvendor.so -i /usr/lmxserver -u lmxserver \
    && mkdir /logs \
    && chown $USER_ID:$USER_GID /logs \
    && mkdir /config \
    && chown $USER_ID:$USER_GID /config \
    && mv /usr/lmxserver/lmx-serv.cfg /config \
    && ln -s /config/lmx-serv.cfg /usr/lmxserver/lmx-serv.cfg

EXPOSE 6200/udp
EXPOSE 6200/tcp

USER ${USER}

ENTRYPOINT [ "/usr/lmxserver/lmx-serv", "-logfile", "/logs/lmx-serv.log", "-licpath", "/config/license.lic" ]
