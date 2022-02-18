#!/bin/bash

# Submits a Kafka Connect connector.
# Takes a json file as input.
# ex: ./submit-connector.sh /path/to/my-connector.json

echo "submitting connectors\n\n"

HEADER="Content-Type: application/json"

curl -X POST -H "${HEADER}" --data "@$1" http://localhost:8083/connectors