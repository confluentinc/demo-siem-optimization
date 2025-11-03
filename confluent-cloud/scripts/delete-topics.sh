#!/bin/bash

source ./scripts/rest-util.sh

for TOPIC in `./scripts/list-topics.sh`; do
    echo "Deleting topic: ${TOPIC}"
    
    curl --request DELETE \
        --url https://${CCLOUD_URL}/kafka/v3/clusters/${CLUSTER_ID}/topics/${TOPIC} \
        --header 'Content-Type: application/json' \
        --header 'Authorization: Basic '${BASE64_AUTH_INFO}''
done


