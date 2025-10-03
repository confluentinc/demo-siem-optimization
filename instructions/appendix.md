# Appendix

## Run This Demo Yourself (no Gitpod)

### Choosing your Docker host environment

- This demo (currently) runs 16 different Docker containers, so this might be too much for your laptop.
- Testing has been done on a c4.4xlarge EC2 instance, with good performance (probably over-provisioned).
- It's recommended to run ```docker system  prune -a``` before running ```docker-compose```

### Configuring the demo environment

1. Run ```python3 scripts/get_pcap.py``` script to download a 1GB/1hr playback pcap.


1. Configure Control Center's ksqlDB advertised listener
    - You need to advertise the correct hostname for the ksqlDB server to ensure that the ksqlDB editor in Confluent Control Center can communicate with the ksqlDB server.
    - In the `docker-compose.yml` file, change the value of  `CONTROL_CENTER_KSQL_KSQLDB1_ADVERTISED_URL` to `http://localhost:8088` if running locally, or to whatever the public DNS hostname is for your VM instance.  Alternatively, run `export CONTROL_CENTER_KSQL_KSQLDB1_ADVERTISED_URL="http://your-server.com:8088"` before starting the demo.

### Starting the demo

To run the demo without automatically submitting connectors, run
```bash
docker-compose up -d
```

If you would like to run it with connectors submitted automatically, run
```bash
docker-compose \
  -f docker-compose.yml \
  -f kafka-connect/submit-connectors.yml \
    up -d
```

If you would additionally like to pre-run all ksqlDB queries and just demo results, run
```bash
scripts/run-ksql-queries.sh
```

If you are using sudo with docker-compose then you will likely need to use the -E option to sudo so it inherits your environmental variables so the last command will become ```sudo -E docker-compose up -d```
