FROM zeek/zeek:6.1.0

RUN apt-get update && \
    apt-get install -y cmake libssl-dev librdkafka-dev libpcap-dev g++ tcpreplay && \
    rm -rf /var/lib/apt/lists/*

RUN zkg install --force seisollc/zeek-kafka --version v1.2.0 --user-var librdkafka_root=/usr && \
    zeek -N Seiso::Kafka
