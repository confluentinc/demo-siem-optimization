CREATE TABLE AGGREGATOR WITH (KAFKA_TOPIC='AGGREGATOR', KEY_FORMAT='JSON', PARTITIONS=1, REPLICAS=1) AS SELECT
    `hostname`,
    `messageID`,
    `action`,
    `src`,
    `dest`,
    `destport`,
    `sourcetype`,
    as_value(`hostname`) as hostname,
    as_value(`messageID`) as messageID,
    as_value(`action`) as action,
    as_value(`src`) as src,
    as_value(`dest`) as dest,
    as_value(`destport`) as dest_port,
    as_value(`sourcetype`) as sourcetype,
    TIMESTAMPTOSTRING(WINDOWSTART, 'yyyy-MM-dd HH:mm:ss', 'UTC') TIMESTAMP,
    60 DURATION,
    COUNT(*) COUNTS
FROM FIREWALLS FIREWALLS
WINDOW TUMBLING ( SIZE 60 SECONDS )
GROUP BY `sourcetype`, `action`, `hostname`, `messageID`, `src`, `dest`, `destport`
EMIT CHANGES;
