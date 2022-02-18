#!/bin/bash

# Parameter: A .sql file containing a ksqlDB query.

# example:
# ./run-ksql-query path/to/myquery.sql

# This script takes a ksqlDB query file and executes it within 
# a ksqldb-cli container run with docker-compose,
# assuming the query file has been mounted in the /queries directory of the container.

QUERY=$(basename $1)
docker-compose exec ksqldb-cli bash -c " cat <<EOF
RUN SCRIPT '/queries/$QUERY';
exit ;
EOF
"