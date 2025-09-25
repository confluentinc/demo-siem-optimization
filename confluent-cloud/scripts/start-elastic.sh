#!/bin/bash

source settings.env

### Wait for Connect to be ready
echo -n 'Waiting for Connect...' 
./scripts/wait-for-endpoint.sh http://localhost:8083
echo '...Connect is ready!'

### Start Elastic components
echo "Starting Elastic Search..."
docker compose up elasticsearch -d

echo "Starting Kibana..."
docker compose up kibana -d

echo -n 'Waiting for Elastic...' 
./scripts/wait-for-endpoint.sh http://localhost:9200
echo '...Elastic is ready!'

echo "Starting the Elastic sink connector..."
./scripts/submit-connector.sh ../confluent-cloud/connectors/elastic-sink.json
