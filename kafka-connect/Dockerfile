FROM confluentinc/cp-server-connect-base:latest

# Install connectors
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:latest && \
    confluent-hub install --no-prompt splunk/kafka-connect-splunk:latest && \
    confluent-hub install --no-prompt confluentinc/kafka-connect-splunk-s2s:latest && \
    confluent-hub install --no-prompt jcustenborder/kafka-connect-spooldir:latest && \
    confluent-hub install --no-prompt confluentinc/kafka-connect-syslog:latest