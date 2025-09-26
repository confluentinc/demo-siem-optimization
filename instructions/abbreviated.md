
# Demonstration Script

## Introduction

Keep this guide open on a separate screen so you can refer to it throughout the demo. View the file on GitHub in order to benefit from code copy button functionality.
- https://github.com/confluentinc/demo-siem-optimization/instructions/abbreviated.md

1. You will be using docker-compose to start the demo up but if you have run this demo before in the same directory you will
need to restore files that were moved by the spooldir connector

```
git restore spooldir/ad_hosts/csv_input/ad_servers.csv
git restore spooldir/urlhaus/csv_input/2020-10-16-urlhaus_sample.csv
```

Once this is done you can run ```docker-compose up -d```


2. Display this architecture diagram for your audience if you didn't do so in a presentation

    ![architecture diagram](./images/lab-architecture.svg)

> The lab environment itself is a network of Docker containers. There is a Splunk event generator feeding data to the Universal Forwarder. There is also a container that uses PCAP files to simulate network traffic that is sniffed by Zeek. The Splunk events and syslog events are streamed into topics on the Confluent Server (which is a Kafka broker) via Kafka Connect source connectors. Socket connection, DNS, HTTP, and other network data sniffed by Zeek is produced directly to the broker using an open source Zeek-Kafka plugin. ksqlDB and Confluent Sigma are stream processors that filter, aggregate, and enrich data in motion. The optimized data is sent via Kafka Connect sink connectors to Splunk or Elastic for indexing and analysis.


## Explore Control Center

Open Confluent Control Center by launching a new tab for port `9021`. Browse the topics page.

> What you are seeing here are a number of topics that already exist in this newly spun up environment. Topics are how different streams of data are organized.  Most of these topics are receiving network metadata streaming in through the Zeek network sensor which is pretty a common tool in network monitoring and cyber defense. It reads packet traffic and produces metadata about that activity on the network.  For instance you can see topics for socket connections, dns queries, http requests, running applications, etc. Zeek is a good example of one of the many tools in this domain that have native support for producing directly into kafka. Other examples are things like syslog-ng, r-syslog, beats, blue coat proxy, etc.

Show the data in the dns topic

> Just a quick peek you can see the DNS metadat being streaming from Zeek.

> We also have some precreated topics that will be used by our real-time stream processors. One of those for instance is topic with domain name watch lists. But we'll look at that later.

## Demonstrate the Ease of Importing Data into Confluent

### Add the `SyslogSourceConnector`

1. Navigate to the connect cluster in Confluent Control Center.

> Confluent offers a buffet of off-the-shelf connectors, into the hundreds, to easily get data in or out of event streams. For this demonstration you will see that we already have two running and taking data in.  One is scraping a watch list from a location on the filesystem and another is recieving data from Splunk universal forwarders.  But to give you an idea whats its like we will spin a new one up. A standard data source in Cybersecurity is system logs (syslog), so lets start capturing that.

2. Select "add connector"
3. Select "SyslogSourceConnector"
4. Set `syslog.listener` to `UDP` and `syslog.port` to `5140`.

> All I have to do with this connector is to specify which syslog protocol to use and which port to receive events on.

5. Submit the connector.

6. Inspect the records in the `syslog` topic.

> Note that Confluent syslog connector parses and extracts the syslog into a structured format but also includes the raw syslog string as well.  This turns out to be important because many tools in the cyber defense ecosystem understand or want raw syslog and this way it doesn’t need to be reconstructed

7. Inspect the records in the `splunk-s2s-events` topic.

> We will take a quick peek at the data coming from the splunk universal forwarder. You can see that it's doing something similar to the syslog connector. It has some structure and the original Splunk data from the forwarder.

## Analyze Streaming SIEM Data in Real Time

> Ok lets go to ksqlDB in Control Center.  If you are not familiar with ksqlDB, its a stream processing engine that allows you to leverage simple SQL syntax to do some very powerful real-time processing.  As I mentioned earlier this could just as easily be flink... but its what I have containerized here.

1. Go to the ksqlDB app in Control Center. Make sure `auto.offset.reset=earliest` so queries pick up from the beginning of topics.

> So we have three sources of data at this point:
>1. Syslog data flowing from agents into Confluent via the SyslogSourceConnector
>2. Data from Splunk agents flowing into Confluent via the Splunks2sSourceConnector
>3. High volume network metadata taken from a Zeek sensor.

> High-volume, low-value data is costly to index in SIEM tools. SIEMs like Splunk are optimized for indexing and searching, so there are performance and budget costs for sending more data than necessary. Unfortunately that means that its not unusual for data to be dropped altogether. But what if you could filter and aggregate the data in motion _before_ it gets to the SIEM indexing tool? You would save on costs while still deriving value from that high volume data.

> Organizations are looking to respond more rapidly to threat patterns and automate as much as possible. Confluent's event-driven, data in motion paradigm is practically purpose built for this sort of demand.

### Filter and Enrich the DNS Stream

1. > So the first stream processing I will do is to created an enriched DNS stream for downstream consumers.  I'm going to enrich it by joining it with the TCP connection stream because the DNS data itself lacks network connection metadata that someone might want when looking at these DNS requestions.  That metadata exsits in the connection stream

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
        duration DOUBLE(18,17),
        orig_bytes INTEGER,
        resp_bytes INTEGER,
        conn_state STRING,
        local_orig BOOLEAN,
        local_resp BOOLEAN,
        missed_bytes INTEGER,
        history STRING,
        orig_pkts INTEGER,
        orig_ip_bytes INTEGER,
        resp_pkts INTEGER,
        resp_ip_bytes INTEGER)
    WITH (KAFKA_TOPIC='conn', VALUE_FORMAT='JSON');

    CREATE STREAM dns_stream (
        ts DOUBLE(16,6),
        uid STRING,
        "id.orig_h" VARCHAR,
        "id.orig_p" INTEGER,
        "id.resp_h" VARCHAR,
        "id.resp_p" INTEGER,
        proto STRING,
        trans_id INTEGER,
        "query" VARCHAR,
        qclass INTEGER,
        qclass_name VARCHAR,
        qtype INTEGER,
        qtype_name STRING,
        rcode INTEGER,
        rcode_name STRING,
        AA BOOLEAN,
        TC BOOLEAN,
        RD BOOLEAN,
        RA BOOLEAN,
        Z INTEGER,
        rejected BOOLEAN)
    WITH (KAFKA_TOPIC='dns', VALUE_FORMAT='JSON');

    CREATE STREAM RICH_DNS
      WITH (PARTITIONS=1, VALUE_FORMAT='AVRO')
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
    ```



2. Submit query to inspect the new derived stream.

    ```sql
    SELECT * FROM RICH_DNS EMIT CHANGES;
    ```
>  Here is the enriched and filtered stream with byte tallies and geospatial data. And now any SIEM tool can take advantage of it and the NOC team can grab it as well.

### Real-Time Watchlist Alerts

> Now that we have enriched this DNS data, let's apply some real-time alerting to it in Confluent. It's common for SOCs (Security Operations Centers) to maintain watchlists for IP addresses and domains.

> We already have such a watchlist populated in a Kafka topic, so we can now populate a lookup table in ksqlDB.

1. Set the ksqlDB editor's `auto.offset.reset` to `earliest` so the watchlist table will be populated from the beginning of the topic.

2. Create the `DOMAIN_WATCHLIST` table and create the joined stream with the matches

    ```sql
    CREATE TABLE DOMAIN_WATCHLIST (
        domain VARCHAR PRIMARY KEY,
        id STRING,
        dateadded STRING,
        source VARCHAR)
    WITH (KAFKA_TOPIC='adhosts', VALUE_FORMAT='AVRO');

    CREATE STREAM MATCHED_DOMAINS_DNS
    WITH (KAFKA_TOPIC='matched_dns', PARTITIONS=1, REPLICAS=1, VALUE_FORMAT='AVRO')
    AS SELECT *
        FROM RICH_DNS INNER JOIN DOMAIN_WATCHLIST
        ON RICH_DNS."query" = DOMAIN_WATCHLIST.DOMAIN
    EMIT CHANGES;
    ```

> Now every time a DNS request goes to a domain in the watchlist, an event will be emitted to the `matched_dns` topic, where any other service can listen and take action. Not only that, but the watchlist table will update in real time as new records arrive in the `adhosts` topic.

> Let's see if we are getting any watchlist matches.

4. Select from the stream.

    ```sql
    SELECT * FROM MATCHED_DOMAINS_DNS
    EMIT CHANGES
    LIMIT 2;
    ```

> These results could be sent to the SOAR of your choice for immediate action.

## Apply Sigma Rules in Real-Time with Confluent Sigma


1. Go back to the Confluent Sigma UI tab.

> What you are seeing here is a simple web interface for the Confluent Sigma. I mentioned earlier that the data being sent into Confluent in this demonstration was taken during a data exfiltration exercise.  It turns out that DNS is a common channel for exploitation by baddies.  So let's see if we can develop a sigma rule to exposes this.  Data exfiltration likely means that someone has a bot or trojan inside our network and they want to send data out to a collecting server. One innocuous way to do this is make legitimate DNS queries from the trojan but encode the data in the DNS query.

2. Go to the "Sigma Rules" tab and click the "+" sign to add a new rule. Paste the rule below and click the "Publish Changes" button when ready. Show the rule in "Sigma Rules".
    ```yml
    title: Possible DNS exfiltration
    status: test
    description: 'This rule identifies possible data exfiltration through DNS'
    author: Will LaForest
    logsource:
      product: zeek
      service: dns
    detection:
      query_length:
        query|re: ^.{180}.*$
      condition: query_length
    ```

> What you are seeing here is a rule that is looking for any dns queries that are longer than 180 characters as that would be somewhat suspicious.  When I hit the publish button that is going to be sent into a Kafka topic and picked up by the sigma stream processor which will start looking for that pattern in the DNS topic.

3. Go to the Detection tab and click on the DNS menu.

> The sigma streams processor is currently configured to put any matching records into a new topic called `dns-detection`. As you can see there is nothing in there.  This means nothing is matching.  Actually I can go back to my sigma UI and click on the DNS Data tab and see that gray represents record flow in the topic and red represents detections.

> So if there is a bot sending data out they aren’t dumb enough to use big long suspicious queries.  We will make it preposterously low to demonstrate that its working at all.

4. Edit the rule to change 180 to 8, publish, and go back to the DNS tab.

> You can now see that pretty much every DNS record matches which is what we would expect.  Let's set it back to 180 and let's publish a different new rule.

5. Edit the rule to change 8 back to to 180, publish, and go back to the DNS tab.

> If the bot isn’t publishing long queries then it's clearly keeping them more modest so that it will fly under the radar.  In this case we are looking for queries over 50 characters which are not rare but only key in on them IF you see more than 10 of them in a 5 second window.

6. Publish a new rule and then return to the DNS tab.
    ```yml
    title: Possible DNS exfiltration over Time
    status: test
    description: 'This rule identifies possible data exfiltration through DNS'
    author: Will LaForest
    logsource:
      product: zeek
      service: dns
    detection:
      query_length:
        query|re: ^.{30}.*$
      condition: query_length | count() > 5
      timeframe: 5s
    ```

> Now you can see we have matches.

7. Go to Control Center and look at records in the `dns-detection` topic.

> If you look at the DNS detections topic, you can see there's encoded data being tacked on to a domain called mrhaha.net. That's the rascal! This stream of just the detections can be passed to you SIEM tool via Kafka Connect, your SOAR, or another stream processor to take action.

> Now I’m going to leverage Confluent Sigma's RegEx extraction processor. There are various ways to apply regular expressions in Kafka Connect and ksqlDB, but Confluent Sigma was purpose-built to put data into a form easily consumable by Splunk or other SIEM tools. The Sigma rule syntax already supports regex and we have included this in support of Confluent Sigma so we can just create a new regex rule.

8. Publish a new rule with the regex condition.
    ```yml
    title: Cisco Firewalls Extraction
    description: This rule is the regex rule test
    author: Mike Peacock
    logsource:
        product: splunk
        service: cisco:asa
    detection:
        filter_field:
            sourcetype: cisco:asa
        event_match:
            event|re: '^(?<timestamp>\w{3}\s\d{2}\s\d{2}:\d{2}:\d{2})\s(?<hostname>[^\s]+)\s\%ASA-\d-(?<messageID>[^:]+):\s(?<action>[^\s]+)\s(?<protocol>[^\s]+)\ssrc\sinside:(?<src>[0-9\.]+)\/(?<srcport>[0-9]+)\sdst\soutside:(?<dest>[0-9\.]+)\/(?<destport>[0-9]+)'
        condition: filter_field AND event_match
    kafka:
        outputTopic: firewalls
        customFields:
            location: edge
            sourcetype: cisco:asa
            index: main

    ```

> The source type here allows us to specify that we only want to run the extractions on a single type of record, which is more efficient than running regular expressions on every record. The regular expression field allows us to specify a pattern with capture groups that will get extracted into fields.

> We can also specify the topic where we want matching records to be sent, which in this case is `firewalls`. Then we can attach optional tags to matching records.

> We can also attach custom tags that we want to include in the topic such as `location = edge` , `sourcetype = cisco:asa` , `index = main`.

> The really amazing thing about using Sigma as the domain specific language is that new rules are published all the time. With Confluent Sigma, you can insert new rules into a special `sigma-rules` topic and the application will automatically pick them up and apply them to your data in real-time. This allows you to be much more proactive about staying on top of the latest threats.

## Optimize What Ends Up in Splunk

> So at this point we haven’t really done any substantial optimization on the data. We showed data enrichment and real-time threat detection, and those sigma patterns COULD have been used to filter the data to be sent to splunk but lets show an example of how you could compress the data going into Splunk by using temporal binning.

1. Create the firewalls stream and create the windowed aggregation.
    ```sql
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
    ```
> Essentially what we're saying is if a message is completely the same but just a new occurrence at a different time I don’t want to emit a new event but instead tally it into a count. The first seven fields are the fields we're using to determine a unique message and you can see the count aggregation.

> Rather than continuously sending each individual message into Splunk -- and **paying** for it, including license and indexing cost -- I want to send each unique event 1 time per 60 seconds, with a count to properly represent weight each record .

4. Look at the `AGGREGATOR` topic in Control Center.

> Let's take a look at the output.  Note the counts on each of the records now.

> Ok lets get some of this data over to Splunk.  I could go ahead and spin up two sink connectors via the web interface but to expedite it I’m just going to hit a script that will do this for me via Connect's REST API.

5. In the terminal, execute
    ```bash
    ./scripts/submit-connector.sh kafka-connect/connectors/splunk-sink-preaggregated.json
    ```

7. Go to the Connect cluster in Control Center.

> Note that you now have a sink connector going to Splunk.  Lets head over to splunk now and look at the data.

8. Open the Splunk UI by launching a new tab for port `8000` from Remote Explorer (see [Gitpod tips](./gitpod-tips.md)). Log in with the username **admin** and password **dingdong** Navigate to app -> search -> search. Run `index=*` and search.

> You can see that we have two source types. One is for the filtered ASA data and the other one is for the aggregated stream.  I can run a query in Splunk that will give me a report and enable me to compare my savings.

8. Run the query:
    ```
    index=* sourcetype=httpevent
    | bin span=5m _time
    | stats sum(COUNTS) as raw_events count(_raw) as filtered_events by _time, SOURCETYPE, HOSTNAME, MESSAGEID, , ACTION, SRC, DEST, DEST_PORT, DURATION
    | eval savings=round(((raw_events-filtered_events)/raw_events) * 100,2) . "%"
    | sort -savings
    ```
> Effectively what you are seeing is a side by comparison for the number of straight cisco events in the filtered data vs. the number in my deduplicated data broken down by event type.  You can see there is anywhere between a 98% to 99% savings in the number records.

## Avoid Lock-In -- Analyze with Elastic

> So remember that enriched DNS data we showed at the beginning of the demo? Well we are already analyzing this in real time with Sigma looking for anomolies.. and the results could be consumed by a SOAR... but imagine the network teams wants to use that enriched DNS data... which is a pretty reasonably thing to expect.  Well let say they are using... elastic... they can just spin up a connector to tap into that stream... so I am going to do that now. Again, I’ll just execute a script for this.

1. In the terminal, submit the connector and then go to Connect -> connectors in Control Center.
    ```bash
    ./scripts/submit-connector.sh kafka-connect/connectors/elastic-sink.json
    ```

> You can now see we have a connector sending data to Elastic. Lets head over to Elastic to verify that its getting in.

2. Open Kibana, Elastic's web UI, on port `5601` from Remote Explorer (see [Gitpod tips](./gitpod-tips.md))

. From Kibana's hamburger menu on the top left, select "Discover" and create a data view with `rich*` to match the `rich_dns` index.

> As you can, see the data is here.  I’ll leave the Elastic analysis up to your imagination.
> At I could just as easily send any of this data to any tool I wanted.. I might want to take all my security data products and send it to S3 for compliance retention...
> So at this point I'd like to conclude and open up the floor for quesitons!
