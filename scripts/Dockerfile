FROM ubuntu:18.04

# ARG CACHEBUST=1

ARG ssh_prv_key
ARG ssh_pub_key

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y git sudo locales locales-all curl wget wamerican-insane

RUN git clone https://github.com/andromeda/pash.git

RUN sudo bash /pash/scripts/install.sh -p

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

ENV PASH_TOP=/pash
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/"


# Authorize SSH Host
RUN mkdir -p /root/.ssh && \
chmod 0700 /root/.ssh

# Add the keys and set permissions
RUN echo "$ssh_prv_key" > /root/.ssh/id_rsa_b313_11 && \
    echo "$ssh_pub_key" > /root/.ssh/id_rsa_b313_11.pub && \
    chmod 600 /root/.ssh/id_rsa_b313_11 && \
    chmod 600 /root/.ssh/id_rsa_b313_11.pub

CMD ["/bin/bash"]
