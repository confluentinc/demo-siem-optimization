# Analyze Syslog Data in Real Time with ksqlDB

## Capture Real SSH Attack Attempts (optional)

The lab environment provides authentic syslog data provided by PCAP file. However, if your Docker host is publicly facing and allows SSH connections from anywhere, it's fun to see who's trying to hack your host.

The Syslog connector is listening on port 5140/UDP.
- If your host is running rsyslog, add the following to /etc/rsyslog.conf:

  ```
  * @localhost:5140
  ```

- Then restart rsyslog with:

  ```bash
  sudo /etc/init.d/rsyslog restart
  ```
## Find Attackers

0. Open Confluent Control Center by launching a new tab for port `9021` (see [Gitpod tips](./gitpod-tips.md) if running in Gitpod).

1. If it's not running already, create the syslog connector:
   - Navigate to the connect cluster in Confluent Control Center.
   - Select "add connector"
   - Select "SyslogSourceConnector"
   - Set `syslog.listener` to `UDP` and `syslog.port` to `5140`.
   - Submit the connector.

1.  Go to the ksqlDB editor in Create a stream from the syslog data with the following ksqlDB query:

    ```sql
    CREATE STREAM SYSLOG_STREAM WITH (KAFKA_TOPIC='syslog', VALUE_FORMAT='AVRO');
    ```

2. Look at the invalid ssh attempts, including geospatial data obtained from custom ksqlDB User-Defined Functions (UDFs).

    NOTE: If you are capturing real SSH traffic, add `AND  HOST NOT LIKE 'clonehost%'` to the `WHERE` clause of the next KSQL statement to omit hosts that were used to generate syslog data.
    ```sql
    SELECT
        TIMESTAMP,
        TAG,
        MESSAGE,
        HOST,
        REMOTEADDRESS AS DEST_IP,
        FORMAT_TIMESTAMP(FROM_UNIXTIME(TIMESTAMP), 'yyyy-MM-dd HH:mm:ss') AS EVENT_TIME, 
        REGEXP_EXTRACT('Invalid user (.*) from', MESSAGE, 1) AS USER,
        REGEXP_EXTRACT('Invalid user .* from (.*) port', MESSAGE, 1) AS SRC_IP,
        GETGEOFORIP(REGEXP_EXTRACT('Invalid user .* from (.*) port', MESSAGE, 1)) AS GEOIP,
        GETASNFORIP(REGEXP_EXTRACT('Invalid user .* from (.*) port', MESSAGE, 1)) AS ASNIP
    FROM  SYSLOG_STREAM
    WHERE TAG='sshd' AND MESSAGE LIKE 'Invalid user%'
    EMIT CHANGES;
    ```
    Here is an example output:

    ```json
    {
    "TIMESTAMP": 1630446079000,
    "TAG": "sshd",
    "MESSAGE": "Invalid user testuser from 18.222.188.131 port 45332",
    "HOST": "ip-172-31-38-121",
    "DEST_IP": "192.168.16.1",
    "EVENT_TIME": "2021-08-31 21:41:19",
    "USER": "testuser",
    "SRC_IP": "18.222.188.131",
    "GEOIP": {
        "CITY": "Columbus",
        "COUNTRY": "United States",
        "SUBDIVISION": "Ohio",
        "LOCATION": {
        "LON": -83.0235,
        "LAT": 39.9653
        }
    },
    "ASNIP": {
        "ASN": 16509,
        "ORG": "AMAZON-02"
    }
    }
    ```

3. Turn this into a persistent query that downstream applications can tap into at any time.
    ```sql
    CREATE STREAM ATTACKERS
    WITH (PARTITIONS=1, VALUE_FORMAT='JSON')
    AS SELECT
        TIMESTAMP,
        TAG,
        MESSAGE,
        HOST,
        REMOTEADDRESS AS DEST_IP,
        FORMAT_TIMESTAMP(FROM_UNIXTIME(TIMESTAMP), 'yyyy-MM-dd HH:mm:ss') AS EVENT_TIME, 
        REGEXP_EXTRACT('Invalid user (.*) from', MESSAGE, 1) AS USER,
        REGEXP_EXTRACT('Invalid user .* from (.*) port', MESSAGE, 1) AS SRC_IP,
        GETGEOFORIP(REGEXP_EXTRACT('Invalid user .* from (.*) port', MESSAGE, 1)) AS GEOIP,
        GETASNFORIP(REGEXP_EXTRACT('Invalid user .* from (.*) port', MESSAGE, 1)) AS ASNIP
    FROM  SYSLOG_STREAM
    WHERE TAG='sshd' AND MESSAGE LIKE 'Invalid user%'
    PARTITION BY HOST
    EMIT CHANGES;
    ```

## Reflection

- What are a couple of things you learned by working hands-on with this Confluent lab?
- What are some questions you still have? 
  - Consider discussing in Slack or posting to the forum
    - https://www.confluent.io/community/ask-the-community/

## Resources

- Go to https://developer.confluent.io/learn-kafka/ksqldb/intro/ to learn more about ksqlDB
- See the ksqlDB docs (they are really good): https://docs.ksqldb.io
- Here are some handy common KSQL snippets: https://ksqldb.io/examples.html
- Here are excellent hands-on stream processing tutorials: https://developer.confluent.io/tutorials