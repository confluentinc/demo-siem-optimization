# Optimize SIEM With Confluent

The examples in this repository give you hands-on experience optimizing Security Information and Event Management (SIEM)
solutions using Confluent. Each tutorial illustrates how to use Confluent to improve the response to a common 
cybersecurity scenario.

## Starting up the environment

This demonstration currently only runs on AMD64 platform Linux and requires docker and docker-compose to be installed.
Because there are so many components running (Confluent Platform, zeek, Elastic, Confluent Sigma, and Splunk) you will 
want a fairly beefy box.  On AWS a m4.xlarge should do the trick.

To run the demonstration clone this repository locally. If you are running this off a remote server you will need to 
edit the docker-compose.yml to put the correct host name for the value `CONTROL_CENTER_KSQL_KSQLDB1_ADVERTISED_URL` 
in the `control-center` section. 

run docker-compose up -d

If you are using sudo with docker-compose then you will likely need to use the -E option to sudo so it inherits your 
environmental variables so the command will become ```sudo -E docker-compose up -d```

### Hands-On Lab Instructions

Run through entire end-to-end demo to get the big picture. Zoom in on the individual labs to go into more detail.

0. [End-to-End Demo](./instructions/00-executive-demo.md) (long)
1. [Introduction](./instructions/01-introduction.md)
2. [Analyze Syslog Data in Real Time with ksqlDB](./instructions/02-syslog.md)
3. [Calculate Hourly Bandwidth Usage By Host with ksqlDB](./instructions/03-bandwidth.md)
4. [Match Hostnames in a Watchlist Against Streaming DNS Data](./instructions/04-watchlist.md)
5. [Filter SSL Transactions and Enrich with Geospatial Data](./instructions/05-ssl.md)

## References

### Demo Video

- https://www.confluent.io/resources/video/how-to-optimize-your-siem-platforms-with-confluent/

### Executive Brief

- https://assets.confluent.io/m/1eb84018eaad8291/

### Cyber Defense Whitepaper

- https://assets.confluent.io/m/34ffc6b59ead86e5/

### Confluent Sigma

- https://github.com/confluentinc/confluent-sigma

