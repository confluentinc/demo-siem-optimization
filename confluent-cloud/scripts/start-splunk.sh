#!/bin/bash

source settings.env

### Wait for Connect to be ready
echo -n 'Waiting for Connect...' 
./scripts/wait-for-endpoint.sh http://localhost:8083
echo '...Connect is ready!'

### Start Splunk components
echo "Starting the Splunk source connector..."
./scripts/submit-connector.sh ../kafka-connect/connectors/splunk-s2s-source.json

echo "Starting the Splunk universal forwarder..."
docker compose up splunk_uf1 -d

echo "Starting the Splunk event generator..."
docker compose up splunk_eventgen -d

echo "Starting the Splunk UI..."
docker compose up splunk -d

### need to wait for the splunk endpoint
echo -n 'Waiting for Splunk...' 
./scripts/wait-for-endpoint.sh http://localhost:8000
echo '...Splunk is ready!'

echo "Starting the Splunk sink connector..."
./scripts/submit-connector.sh ../kafka-connect/connectors/splunk-sink.json
./scripts/submit-connector.sh ../kafka-connect/connectors/splunk-sink-preaggregated.json
