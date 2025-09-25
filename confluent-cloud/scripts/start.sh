#!/bin/bash

source settings.env

### Create Topics
./scripts/create-topics.sh

### Start the local docker components
echo -n "Starting local Connect server."
docker compose up connect -d

### Wait for Connect to be ready
echo -n 'Waiting for Connect...' 
./scripts/wait-for-endpoint.sh http://localhost:8083
echo '...Connect is ready!'

### Start local Control Center
docker compose up control-center -d

### Start syslog components
echo "Starting the Syslog connector..."
./scripts/update-syslog-properties.sh
./scripts/submit-connector.sh ../confluent-cloud/connectors/syslog-source.json

#echo 'Starting the syslog-streamer...'
docker compose up syslog-streamer -d

### Start Sigma Processors
echo "Starting the Sigma zeek dns streams app..."
docker compose up sigma-zeek-dns-streams -d

#echo "Starting the Sigma splunk cisco asa streams app..."
docker compose up sigma-splunk-cisco-asa-streams -d

#echo "Starting Sigma UI..."
docker compose up sigma-streams-ui -d

### Start the Zeek Streamer
echo "Starting the zeek-streamer..."
./scripts/update-zeek-properties.sh
docker compose up zeek-streamer -d

### Start Splunk components
./scripts/start-splunk.sh

### Start Elastic components
./scripts/start-elastic.sh
