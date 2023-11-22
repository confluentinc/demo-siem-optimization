FROM zeek/zeek:6.1.0

RUN apt-get update && \
    apt-get install -y \
      bison \
      clang \
      cmake \
      flex \
      g++ \
      gcc \
      git \
      iproute2 \
      libssl-dev \
      librdkafka-dev \
      libpcap-dev \
      make \
      net-tools \
      python3 \
      softflowd \
      swig \
      tcpreplay \
      zlib1g-dev \
      && \
    rm -rf /var/lib/apt/lists/*

RUN zkg install --force seisollc/zeek-kafka --version v1.2.0 --user-var librdkafka_root=/usr && \
    rm -rf /usr/local/zeek/var/lib/zkg/scratch /usr/local/zeek/var/lib/zkg/testing && \
    zeek -N Seiso::Kafka
