# Calculate Hourly Bandwidth Usage By Host with ksqlDB


A SIEM tool is a very expensive calculator. With stream processing, you can perform calculations upstream and send the results to the reporting layer to save costs.

1. Create a Stream from the Zeek Conn topic
    ```sql
    CREATE STREAM conn_stream (
        ts DOUBLE(16,6),
        uid STRING,
        "id.orig_h" VARCHAR,
        "id.orig_p" INTEGER,
        "id.resp_h" VARCHAR,
        "id.resp_p" INTEGER,
        proto STRING,
        service STRING,
        conn_state STRING,
        local_orig BOOLEAN,
        local_resp BOOLEAN,
        missed_bytes INTEGER,
        history STRING,
        orig_packets INTEGER,
        orig_ip_bytes INTEGER,
        resp_pkts INTEGER,
        resp_ip_bytes INTEGER)
    WITH (KAFKA_TOPIC='conn', VALUE_FORMAT='JSON');
    ```
2. Create a table to hold aggregate byte counts
    ```sql
    CREATE TABLE HOURLY_BYTE_COUNT_TABLE
    WITH (KAFKA_TOPIC='BYTE_TABLE', VALUE_FORMAT='JSON')
    AS SELECT
        "id.orig_h" AS SRC_IP,
        sum(orig_ip_bytes + resp_ip_bytes) AS TOTAL_BYTES
    FROM CONN_STREAM
    WINDOW TUMBLING(SIZE 1 HOUR)
    GROUP BY "id.orig_h";
    ```
3. Run a ```SELECT *``` query for a single host as a sanity check
    ```sql
    SELECT * FROM  HOURLY_BYTE_COUNT_TABLE WHERE SRC_IP='192.168.1.15';
    ```
    Here is some example output
    ```json
    {
    "SRC_IP": "192.168.1.15",
    "WINDOWSTART": 1631037600000,
    "WINDOWEND": 1631041200000,
    "TOTAL_BYTES": 6586453
    }
    ```
4. Run a more complex query for prettier output
    ```sql
    SELECT
        SRC_IP, TOTAL_BYTES, WINDOWSTART, WINDOWEND,
        UNIX_TIMESTAMP() AS NOW_EPOCH,
        FORMAT_TIMESTAMP(FROM_UNIXTIME(WINDOWSTART), 'yyyy-MM-dd HH:mm:ss') AS TIME_START,
        FORMAT_TIMESTAMP(FROM_UNIXTIME(WINDOWEND), 'yyyy-MM-dd HH:mm:ss') AS TIME_END,
        FORMAT_TIMESTAMP(FROM_UNIXTIME(UNIX_TIMESTAMP()), 'yyyy-MM-dd HH:mm:ss.SSS') AS NOW,
        TOTAL_BYTES/1000000.00 AS TOTAL_MB
    FROM  HOURLY_BYTE_COUNT_TABLE
    WHERE SRC_IP='192.168.1.15' ;
    ```
    Here is some example output
    ```json
    {
    "SRC_IP": "192.168.1.15",
    "TOTAL_BYTES": 4155771,
    "WINDOWSTART": 1631037600000,
    "WINDOWEND": 1631041200000,
    "NOW_EPOCH": 1631039786152,
    "TIME_START": "2021-09-07 18:00:00",
    "TIME_END": "2021-09-07 19:00:00",
    "NOW": "2021-09-07 18:36:26.158",
    "TOTAL_MB": 4.155771
    }
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