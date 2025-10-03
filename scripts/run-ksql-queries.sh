#!/bin/bash

# Parameter: A .sql file containing a ksqlDB query.

# example:
# ./run-ksql-query path/to/myquery.sql

# This script takes a ksqlDB query file and executes it within
# a ksqldb-cli container run with docker-compose,
# assuming the query file has been mounted in the /queries directory of the container.

docker-compose exec ksqldb-cli bash -c "ksql http://ksqldb-server:8088 <<EOF
RUN SCRIPT '/queries/create_zeek_conn_stream.sql';
exit ;
EOF
ksql http://ksqldb-server:8088 <<EOF
RUN SCRIPT '/queries/create_zeek_dns_stream.sql';
exit ;
EOF
ksql http://ksqldb-server:8088 <<EOF
RUN SCRIPT '/queries/create_zeek_rich_dns_stream.sql';
exit ;
EOF
ksql http://ksqldb-server:8088 <<EOF
RUN SCRIPT '/queries/create_domain_watchlist.sql';
exit ;
EOF
ksql http://ksqldb-server:8088 <<EOF
RUN SCRIPT '/queries/create_zeek_matched_domains_dns.sql';
exit ;
EOF
ksql http://ksqldb-server:8088 <<EOF
RUN SCRIPT '/queries/create_splunk.sql';
exit ;
EOF
ksql http://ksqldb-server:8088 <<EOF
RUN SCRIPT '/queries/create_cisco_asa.sql';
exit ;
EOF
ksql http://ksqldb-server:8088 <<EOF
RUN SCRIPT '/queries/create_cisco_asa_filtered.sql';
exit ;
EOF
ksql http://ksqldb-server:8088 <<EOF
RUN SCRIPT '/queries/create_firewalls.sql';
exit ;
EOF
ksql http://ksqldb-server:8088 <<EOF
RUN SCRIPT '/queries/create_aggregator.sql';
exit ;
EOF
"
