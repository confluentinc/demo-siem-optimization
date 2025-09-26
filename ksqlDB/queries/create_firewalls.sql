CREATE STREAM FIREWALLS (
    `src` VARCHAR,
    `messageID` BIGINT,
    `index` VARCHAR,
    `dest` VARCHAR,
    `hostname` VARCHAR,
    `protocol` VARCHAR,
    `action` VARCHAR,
    `srcport` BIGINT,
    `sourcetype` VARCHAR,
    `destport` BIGINT,
    `location` VARCHAR,
    `timestamp` VARCHAR
) WITH (
KAFKA_TOPIC='firewalls', value_format='JSON'
);
