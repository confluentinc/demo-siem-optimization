CREATE STREAM SPLUNK (
  event VARCHAR,
  time BIGINT,
  host VARCHAR,
  source VARCHAR,
  sourcetype VARCHAR,
  index VARCHAR
) WITH (
  KAFKA_TOPIC='splunk-s2s-events', VALUE_FORMAT='JSON');
