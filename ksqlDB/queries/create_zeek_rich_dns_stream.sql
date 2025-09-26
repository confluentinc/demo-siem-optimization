CREATE STREAM RICH_DNS
WITH (PARTITIONS=1, KAFKA_TOPIC='rich_dns', VALUE_FORMAT='AVRO')
AS SELECT d."query",
        d."id.orig_h" AS SRC_IP,
        d."id.resp_h" AS DEST_IP,
        GETGEOFORIP(D.`id.resp_h`) DEST_GEO,
        d."id.orig_p" AS SRC_PORT,
        d."id.resp_h" AS DEST_PORT,
        d.QTYPE_NAME,
        d.TS,
        d.UID,
        c.UID,
        c.ORIG_IP_BYTES AS REQUEST_BYTES,
        c.RESP_IP_BYTES AS REPLY_BYTES,
        c.LOCAL_ORIG
    FROM DNS_STREAM d INNER JOIN CONN_STREAM c
        WITHIN 1 MINUTES
        ON d.UID = c.UID
    WHERE LOCAL_ORIG = true
    PARTITION BY "query"
EMIT CHANGES;
