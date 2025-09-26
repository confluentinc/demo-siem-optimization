# Filter SSL Transactions and Enrich with Geospatial Data

The `ssl` topic from Zeek has information about the TCP connection in SSL/TLS exchanges, and the `x509` topic from Zeek has data about the certificate itself. We will join these two data sources to create a derived data stream with IP addresses and ports but also Certificate Authority, certificate creation and expiration information. Enrich this data stream with Geo IP information as well as network ownership via ASN records.

1. Create a stream from the ```ssl``` topic
    ```sql
    CREATE STREAM ssl_stream (
        ts DOUBLE(16,6),
        uid STRING,
        "id.orig_h" VARCHAR,
        "id.orig_p" INTEGER,
        "id.resp_h" VARCHAR,
        "id.resp_p" INTEGER,
        version STRING,
        cipher VARCHAR,
        curve STRING,
        server_name VARCHAR,
        resumed BOOLEAN,
        next_protocol VARCHAR,
        established BOOLEAN,
        cert_chain_fuids ARRAY<STRING>,
        client_cert_chain_fuids ARRAY<STRING>,
        subject VARCHAR,
        issuer VARCHAR,
        validation_status STRING)
    WITH (KAFKA_TOPIC='ssl', VALUE_FORMAT='JSON');
    ```

2. Do the same for the ```x509``` topic
    ```sql
    CREATE STREAM x509_stream (
        ts DOUBLE(16,6),
        id STRING,
        "certificate.version" INTEGER,
        "certificate.serial" STRING,
        "certificate.subject" VARCHAR,
        "certificate.issuer" VARCHAR,
        "certificate.not_valid_before" BIGINT,
        "certificate.not_valid_after" BIGINT,
        "certificate.key_alg" STRING,
        "certificate.sig_alg" STRING,
        "certificate.key_type" STRING,
        "certificate.key_length" INTEGER,
        "certificate.exponent" INTEGER,
        "basic_constraints.ca" BOOLEAN,
        "basic_constraints.path_len" INTEGER)
    WITH (KAFKA_TOPIC='x509', VALUE_FORMAT='JSON');
    ```

3. The goal for this next query is to join

    ```sql
    SELECT
        s.TS AS SSL_TS,
        FORMAT_TIMESTAMP(FROM_UNIXTIME(CAST(s.TS AS BIGINT)*1000), 'yyyy-MM-dd HH:mm:ss') AS EVENT_TIME,
        s."id.orig_h" AS SRC_IP,
        s."id.orig_p" AS SRC_PORT,
        s."id.resp_h" AS DEST_IP,
        getgeoforip("id.resp_h") AS GEOIP,
        getasnforip("id.resp_h") AS ASNIP,
        s."id.resp_p" AS DEST_PORT,
        s.VERSION AS VERSION,
        s.CIPHER AS CIPHER,
        s.CURVE AS CURVE,
        s.SERVER_NAME AS SERVER_NAME,
        s.SUBJECT AS SUBJECT,
        s.ISSUER AS ISSUER,
        s.VALIDATION_STATUS AS VALIDATION_STATUS,
        x.TS AS X509_TS,
        x."certificate.version" AS CERTIFICATE_VERSION,
        x."certificate.not_valid_before" AS CERTIFICATE_NOT_VALID_BEFORE,
        x."certificate.not_valid_after" AS CERTIFICATE_NOT_VALID_AFTER,
        FORMAT_TIMESTAMP(FROM_UNIXTIME(x."certificate.not_valid_after"*1000), 'yyyy-MM-dd HH:mm:ss') AS CERT_EXPIRATION_DATE,
        FORMAT_TIMESTAMP(FROM_UNIXTIME(x."certificate.not_valid_before"*1000), 'yyyy-MM-dd HH:mm:ss') AS CERT_REGISTRATION_DATE,
        x."certificate.key_alg" AS CERTIFICATE_KEY_ALG,
        x."certificate.sig_alg" AS CERTIFICATE_SIG_ALG,
        x."certificate.key_type" AS CERTIFICATE_KEY_TYPE,
        x."certificate.key_length" AS CERTIFICATE_KEY_LENGTH
    FROM SSL_STREAM s INNER JOIN X509_STREAM x WITHIN 1 SECONDS
    on s.SUBJECT = x."certificate.subject"
    WHERE s.VALIDATION_STATUS!='ok' EMIT CHANGES;
    ```

    This query does a few interesting things:
    - Formats a new field called ```EVENT_TIME``` by transforming the SSL event's timestamp
    - Enriches the data with the ```GETGEOFORIP``` and ```GETASNFORIP``` User Defined Functions (UDFs)
    - Joins the ```SSL_STREAM``` with the ```X509_STREAM``` where the certificate subjects match.

    Notice the `WITHIN 1 SECONDS` clause. Since we are joining two unending streams, we need some way to limit the data we are using to do lookups. That's why joining two streams always includes a window. In this case, ksqlDB remembers 1 second worth of events from each stream for lookups. Whenever a new event arrives from either stream, ksqlDB does a lookup against the other stream in the last 1 second for any events with the same certificate subject. For each match found, a new enriched event is sent to the output stream. Pretty neat!

    Here is a sample event from this query -- cleaned, filtered, enriched, and ready for your downstream SIEM tool.

    ```json
    {
    "SSL_TS": 1630511449.743718,
    "EVENT_TIME": "2021-09-01 15:50:49",
    "SRC_IP": "192.168.1.143",
    "SRC_PORT": 49927,
    "DEST_IP": "104.154.89.105",
    "GEOIP": {
        "CITY": null,
        "COUNTRY": "United States",
        "SUBDIVISION": "Virginia",
        "LOCATION": {
        "LON": -77.2481,
        "LAT": 38.6583
        }
    },
    "ASNIP": {
        "ASN": 15169,
        "ORG": "GOOGLE"
    },
    "DEST_PORT": 443,
    "VERSION": "TLSv12",
    "CIPHER": "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
    "CURVE": "secp256r1",
    "SERVER_NAME": "self-signed.badssl.com",
    "SUBJECT": "CN=*.badssl.com,O=BadSSL,L=San Francisco,ST=California,C=US",
    "ISSUER": "CN=*.badssl.com,O=BadSSL,L=San Francisco,ST=California,C=US",
    "VALIDATION_STATUS": "self signed certificate",
    "X509_TS": 1630511449.781517,
    "CERTIFICATE_VERSION": 3,
    "CERTIFICATE_NOT_VALID_BEFORE": 1570664512,
    "CERTIFICATE_NOT_VALID_AFTER": 1633736512,
    "CERT_EXPIRATION_DATE": "2021-10-08 23:41:52",
    "CERT_REGISTRATION_DATE": "2019-10-09 23:41:52",
    "CERTIFICATE_KEY_ALG": "rsaEncryption",
    "CERTIFICATE_SIG_ALG": "sha256WithRSAEncryption",
    "CERTIFICATE_KEY_TYPE": "rsa",
    "CERTIFICATE_KEY_LENGTH": 2048
    }
    ```
4. Create a persistent query to save these these groomed events to a Kafka topic.
    ```sql
    CREATE STREAM BAD_SSL
    WITH (KAFKA_TOPIC='BAD_SSL', VALUE_FORMAT='JSON')
    AS SELECT
        s.TS AS SSL_TS,
        FORMAT_TIMESTAMP(FROM_UNIXTIME(CAST(s.TS AS BIGINT)*1000), 'yyyy-MM-dd HH:mm:ss') AS EVENT_TIME,
        s."id.orig_h" AS SRC_IP,
        s."id.orig_p" AS SRC_PORT,
        s."id.resp_h" AS DEST_IP,
        getgeoforip("id.resp_h") AS GEOIP,
        getasnforip("id.resp_h") AS ASNIP,
        s."id.resp_p" AS DEST_PORT,
        s.VERSION AS VERSION,
        s.CIPHER AS CIPHER,
        s.CURVE AS CURVE,
        s.SERVER_NAME AS SERVER_NAME,
        s.SUBJECT AS SUBJECT,
        s.ISSUER AS ISSUER,
        s.VALIDATION_STATUS AS VALIDATION_STATUS,
        x.TS AS X509_TS,
        x."certificate.version" AS CERTIFICATE_VERSION,
        x."certificate.not_valid_before" AS CERTIFICATE_NOT_VALID_BEFORE,
        x."certificate.not_valid_after" AS CERTIFICATE_NOT_VALID_AFTER,
        FORMAT_TIMESTAMP(FROM_UNIXTIME(x."certificate.not_valid_after"*1000), 'yyyy-MM-dd HH:mm:ss') AS CERT_EXPIRATION_DATE,
        FORMAT_TIMESTAMP(FROM_UNIXTIME(x."certificate.not_valid_before"*1000), 'yyyy-MM-dd HH:mm:ss') AS CERT_REGISTRATION_DATE,
        x."certificate.key_alg" AS CERTIFICATE_KEY_ALG,
        x."certificate.sig_alg" AS CERTIFICATE_SIG_ALG,
        x."certificate.key_type" AS CERTIFICATE_KEY_TYPE,
        x."certificate.key_length" AS CERTIFICATE_KEY_LENGTH
    FROM SSL_STREAM s INNER JOIN X509_STREAM x WITHIN 1 SECONDS
    on s.SUBJECT = x."certificate.subject"
    WHERE s.VALIDATION_STATUS!='ok'
    PARTITION BY s."id.orig_h"
    EMIT CHANGES;
    ```
    This new `BAD_SSL` topic can then be consumed by any number of different downstream connectors simultaneously.

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