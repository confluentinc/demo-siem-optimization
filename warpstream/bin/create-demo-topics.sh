#!/bin/bash
kafka-topics --create --topic matched_dns --bootstrap-server broker:29092
kafka-topics --create --topic rich_dns --bootstrap-server broker:29092
kafka-topics --create --topic CISCO_ASA --bootstrap-server broker:29092
kafka-topics --create --topic CISCO_ASA_FILTER_106023 --bootstrap-server broker:29092
kafka-topics --create --topic AGGREGATOR --bootstrap-server broker:29092
