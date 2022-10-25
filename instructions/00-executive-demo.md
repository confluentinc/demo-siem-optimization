# Executive Demonstration

You are a Confluent employee showcasing this demo for an executive audience (or just a curious person who wants to learn more about SIEM optimization). As preparation, run through this demonstration yourself until you feel confident you know how it works and can speak intelligently about it.

## Presentation

1. Request read access to the [demo presentation](https://docs.google.com/presentation/d/1fRue23OSV_zddkXWOv4YOARvK1SHAOkffcFzms0RBsk/edit?usp=sharing)
2. Deliver the slide presentation to set the context

# Demonstration Script

## Introduction

Keep this guide open on a separate screen so you can refer to it throughout the demo. It is suggested to can go to GitHub to benefit from code copy button functionality.
- https://github.com/confluentinc/demo-siem-optimization/instructions/00-executive-demo.md

1. In a screen you are displaying to your audience, launch the Gitpod workspace by clicking the link:
   - https://gitpod.io/#https://github.com/confluentinc/demo-siem-optimization

> Here I'm starting a containerized lab environment that will automatically do a lot on launch.

> I am going to demonstrate how Confluent can help you optimize your existing SIEM investment, while at the same time improving your cyber defense capabilities.

2. Display this architecture diagramfor your audience:

    ![architecture diagram](./images/lab-architecture.svg)

>  This demo will show four advantages of using Confluent: 
>1. Real-time threat detection directly in the streams of data.
>2. Decrease your Splunk costs by filtering and aggregating the data before it lands in Splunk.
>3. Gain insights from high volume data too expensive to index
>4. Avoid vendor lock-in so that you can take advantage of the strengths of different SIEM vendors.

> The lab environment itself is a network of Docker containers. There is a Splunk event generator feeding data to the Universal Forwarder. There is also a container that uses PCAP files to simulate network traffic that is sniffed by Zeek. The Splunk events and syslog events are streamed into topics on the Confluent Server (which is a Kafka broker) via Kafka Connect source connectors. Socket connection, DNS, HTTP, and other network data sniffed by Zeek is produced directly to the broker using an open source Zeek-Kafka plugin. ksqlDB and Confluent Sigma are stream processors that filter, aggregate, and enrich data in motion. The optimized data is sent via Kafka Connect sink connectors to Splunk or Elastic for indexing and analysis.

NOTE: For more detailed information about the ports being used, see the `.gitpod.yml` file. For more detailed information about how each component functions, see the `docker-compose.yml` file.

## Explore Control Center

Back in Gitpod, open Confluent Control Center by launching a new tab for port `9021` from Remote Explorer (see [Gitpod tips](./gitpod-tips.md)). Browse the topics page.

> What you are seeing here are a number of topics that already exist in this newly spun up environment. Topics are how different streams of data are organized.  Most of these topics are receiving PCAP data streaming in through a Zeek container. Zeek is a common tool in cyber defense -- it's an open source network sensor that reads packet traffic and produces metadata about that activity on the network.  For instance you can see topics for socket connections, dns queries, http requests, running applications, etc. Zeek is a good example of one of the many tools in this domain that have native support for producing directly into Confluent. Other examples are things like syslog-ng, r-syslog, beats, blue coat proxy, etc.

> We also have some precreated topics that will be used by our real-time stream processors. One of those for instance is topic with domain name watch lists. But we'll look at that later.

## Demonstrate the Ease of Importing Data into Confluent

### Add the `SyslogSourceConnector`

> Confluent offers a buffet of off-the-shelf connectors to easily get data in or our of event streams.  A standard data source in Cyber defense are system logs (syslog), so lets start capturing that.

1. Navigate to the connect cluster in Confluent Control Center.
2. Select "add connector"
3. Select "SyslogSourceConnector"

> If you aren’t familiar with Kafka Connect, it's the easiest way to move data into or out of Confluent. You simply specify a few settings for the external system, and the connect cluster automatically starts the data flowing. No code required.

4. Set `syslog.listener` to `UDP` and `syslog.port` to `5140`.

> All I have to do with this connector is to specify which syslog protocol to use and which port to receive events on.

5. Submit the connector.

> Control center actually generates the configuration and sends it to the Connect cluster's REST API. So you can just as easily automate this using your favorite tool, or use gitops to store the connectors you need.

### Add the `SplunkS2SSourceConnector`

>As mentioned earlier, we are a company that has Splunk agents to collecting and sending data straight to Splunk.  In order to take advantage of real-time stream processing, we want to send the data to Confluent instead.  So let's spin up another connector to receive this data.

1. Click "add connector" and select the `SplunkS2SSourceConnector`.
2. Submit the connector.

> For this one we don’t need to specify anything at all and will just stick with the defaults.

> So at this point let's actually go back and take a quick peek into the topics to see what the data looks like.

3. Inspect the records in the `syslog` topic.

> Note that Confluent syslog connector parses and extracts the syslog into a structured format but also includes the raw syslog string as well.  This turns out to be important because many tools in the cyber defense ecosystem understand or want raw syslog and this way it doesn’t need to be reconstructed

4. Inspect the records in the `splunk-s2s-events` topic.

> Take a quick peek at the data coming from the splunk universal forwarder. You can see that it's doing something similar to the syslog connector. It has some structure and the original Splunk data.

### View Network Metadata from Zeek

> There is another source of data captured for this demo -- a Zeek network sensor. This network metadata data was captured from an exfiltration exercise and stored in a PCAP file. That file is then streamed into Confluent through a Kafka producer to simulate an obscenely high volume captured in real time. In the real world, the Zeek sensor would send data to a Kafka producer, which would publish to topics in real time. Again, Zeek is producing data about socket connections, dns queries, http requests, running applications, etc. Let's look at the DNS data.

1. Inspect reords in the `dns` topic.

>  The volume of DNS data is shockingly high.  In the Pantheon of cyber data volumes, only pure packet capture and netflow data tends to be bigger. Organizations often don’t even send it to their SIEM because it's cost is prohibitive and places a huge burden on the SIEM relative to other data sources.  This data is generally just hard to deal with.  The immediate consequence is bad guys know this and it's a favorite for things like SSH tunneling and data exfiltration.

## Analyze Streaming SIEM Data in Real Time

> Lets go to ksqlDB in Control Center.  If you are not familiar with ksqlDB, its a stream processing engine that allows you to leverage simple SQL syntax to do some very powerful real-time processing.

1. Go to the ksqlDB app in Control Center. Make sure `auto.offset.reset=earliest` so queries pick up from the beginning of topics.

> So we have three sources of data at this point:
>1. Syslog data flowing from agents into Confluent via the SyslogSourceConnector
>2. Data from Splunk agents flowing into Confluent via the Splunks2sSourceConnector
>3. High volume network metadata taken from a Zeek sensor.

> High-volume, low-value data is costly to index in SIEM tools. SIEMs like Splunk are optimized for indexing and searching, so there are performance and budget costs for sending more data than necessary. Unfortunately that means this data is usually dropped altogether. But what if you could filter and aggregate the data in motion _before_ it gets to the SIEM indexing tool? You would save on costs while still deriving value from that high volume data.

> Organizations are looking to respond more rapidly to threat patterns and automate as much as possible (SOAR -- Security Orchestration Automated Response). Confluent's event-driven, data in motion paradigm is practically purpose built for this sort of demand.

### Filter and Enrich the DNS Stream

> Let's use Confluent to optimize your data and look for threats upstream of your SIEM. We're going to use Confluent's stream processing capability ksqlDB to filter, enrich, and aggregate these data streams in real-time. 

2. Create the `conn_stream` in the KSQL editor.

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
    ```

> The first thing we need to do is tell ksqlDB how to interpret the raw JSON data thats coming in from Zeek into our topics. I’m not going to walk through all the details of these queries, but you can see its assigning data types to the fields in the topics. This stream is socket connection data.

> Similarly, we structure the stream for DNS data captured by Zeek.

3. Create the `dns_stream` in the KSQL editor.

    ```sql
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
    ```

> At this point we can start processing, and analyzing.  So for instance if I wanted to get a real-time aggregation as the data flows through kafka I could run a query like this:

4. Submit the KSQL query and terminate when ready to move on.

    ```sql
    SELECT "query", COUNT("query") AS LOOKUPS
        FROM DNS_STREAM
        GROUP BY "query"
        EMIT CHANGES;
    ```

> This is giving me a count broken down by unique DNS queries. Note that as time goes on the repeat queries will have larger numbers and this will go on indefinitely until you terminate the query.  In actuality these sort of real-time aggregates need something called a window to be useful. for instance I might say I want a running count in 10 second windows and any time I see the same query more than X in 10 seconds that could be interesting. This is just an ad-hoc query. It will terminate when I'm tired of looking at it.

> Lets actually create an enriched and filtered stream of DNS data.  For every DNS query there is of course a network connection.  The zeek sensor has a separate stream for ALL connections which includes the DNS ones.  If I really wanted a more complete view of the DNS queries I probably need to join the streams, for instance maybe I want the transferred bytes associated with the query.  That's not in DNS but is in Connection.   So let's create a persistent query which will produce the enriched data. This query will live on and continue to process records in real-time.

5. Submit the persistent query.

    ```sql
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

> Note that in addition to joining to the connection stream for byte tallies, I’m also calling a custom function that uses maxmind to get the geo location for the IP AND filtering out anything that did not originate on the local network.

> We can now peek at the new enriched stream.

6. Submit query to inspect the new derived stream.

    ```sql
    SELECT * FROM RICH_DNS EMIT CHANGES;
    ```
>  Here is the enriched and filtered stream with byte tallies and geospatial data. And now any SIEM tool can take advantage of it. Pretty cool!

### Real-Time Watchlist Alerts


> Now that we have filtered and enriched this DNS data, let's apply some real-time alerting to it in Confluent. It's common for SOCs (Security Operations Centers) to maintain watchlists for IP addresses and domains.

> We already have such a watchlist populated in a Kafka topic, so we can now populate a lookup table in ksqlDB.

1. Set the ksqlDB editor's `auto.offset.reset` to `earliest` so the watchlist table will be populated from the beginning of the topic.

2. Create the `DOMAIN_WATCHLIST` lookup table.
    ```sql
    CREATE TABLE DOMAIN_WATCHLIST (
        domain VARCHAR PRIMARY KEY,
        id STRING,
        dateadded STRING,
        source VARCHAR)
    WITH (KAFKA_TOPIC='adhosts', VALUE_FORMAT='AVRO');
    ```
>  Now we can create a query that emits events for any DNS lookups against domain names in the watchlist.

3. Create the persistent query.

    ```sql
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

### Real-Time Authentication Alerts with DUO (Skip)

<---> This section is under construction. Skip for now. <--->

> We will take a look at one more example of creating an alert. We also have DUO data simulating multi-factor and that writing to the duo topic. Suppose we wanted to create an alert that would notify an analyst if there were repeated sign in failures, but not just any sign in failure as your MFA tool would most likely catch that. In this case, we will be looking for multiple failures that occur within a window of time, perhaps by a bot that is changing their IP address.

1. Create the stream of DUO events.

    ```sql
    CREATE STREAM duo_stream (
    Time_Auth VARCHAR,
    User VARCHAR,
    Integration VARCHAR,
    Factor VARCHAR,
    Result VARCHAR,
    Reason VARCHAR,
    TWO_FA_Device_Name VARCHAR,
    Access_Device_IP VARCHAR,
    Access_Device_Country VARCHAR,
    Access_Device_State VARCHAR,
    Access_Device_City VARCHAR,
    Email VARCHAR,
    Response_Time VARCHAR
    ) WITH (KAFKA_TOPIC='duo', VALUE_FORMAT='DELIMITED', VALUE_DELIMITER=',');
    ```

> Next, we count up the failures within 30 second windows.

2. Create the windowed count of failed login attempts.
    ```sql
    CREATE TABLE DUO_FAILURES
    WITH (PARTITIONS=1, VALUE_FORMAT='AVRO')
    AS SELECT 
        WINDOWSTART AS WS, 
        WINDOWEND AS WE, 
        COUNT(*) AS COUNT, 
        RESULT 
        FROM DUO_STREAM 
        WINDOW TUMBLING (SIZE 30 SECONDS)
        WHERE RESULT = 'FAILURE'
        GROUP BY RESULT
        EMIT CHANGES;
    ```

> And then, we create the alert stream that will trigger if there are more than 10 failures within that 30 second tumbling window.

3. Create the failures and suspicious failure rate streams.
    ```sql
    CREATE STREAM FAILURES_STREAM
    WITH (KAFKA_TOPIC='DUO_FAILURES', VALUE_FORMAT='AVRO');
    
    CREATE STREAM SUSPICIOUS_FAILURE_RATE
    WITH (PARTITIONS=1, VALUE_FORMAT='AVRO')
    AS SELECT *
        FROM FAILURES_STREAM
        WHERE (FAILURES_STREAM.COUNT > 10)
    EMIT CHANGES;
    ```

4. View the suspicious failure rate stream and stop the query when you're done.
    ```sql
    SELECT * FROM SUSPICIOUS_FAILURE_RATE EMIT CHANGES;
    ```

> Like before, your SOAR can listen to these events and take immediate action.

## Apply Sigma Rules in Real-Time with Confluent Sigma

1. Go to the [Confluent Sigma slide](https://docs.google.com/presentation/d/1fRue23OSV_zddkXWOv4YOARvK1SHAOkffcFzms0RBsk/edit#slide=id.g102ab69693c_0_4511) in the presentation.

> In working with my many cyber defense customers, one thing I realized is that very few of the SOC personnel are coders, and even SQL can be out of their comfort zone. They are focused on understanding their domain and their toolset. That's why we created Confluent Sigma, an open-source stream processing application with a UI for security professionals.

2. Open the Confluent Sigma UI on port `8080` in a new tab from Remote Explorer (see [Gitpod tips](./gitpod-tips.md)).

> We wrote Confluent Sigma using Kafka Streams, which is a poorly named but powerful stream processing library for Java.  ksqlDB actually runs on Kafka Streams "under the hood." As a Java library, Kafka Streams gives deeper programmatic control over your stream processing logic, which in this case we used to create a custom application. To understand what it does, we need to know what Sigma is in the SIEM world.

3. Show the https://github.com/SigmaHQ/sigma page.

> Sigma is a domain-specific language (DSL) to describe suspicious patterns in log events. It's open source, and security researchers maintain collections of Sigma patterns to share with others.

4. Go back to the Confluent Sigma UI tab.

> What you are seeing here is a simple web interface for the Confluent Sigma. I mentioned earlier that the data being sent into Confluent in this demonstration was taken during a data exfiltration exercise.  You may also remember that I said DNS was a favorite channel for exploitation by baddies.  So let's see if we can develop a sigma rule to exposes this.  Data exfiltration likely means that someone has a bot or trojan inside our network and they want to send data out to a collecting server. One innocuous way to do this is make legitimate DNS queries from the trojan but encode the data in the DNS query.

5. Go to the "Sigma Rules" tab and paste the rule. Click the "publish" button when ready. Show the rule in "Sigma Rules".
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

6. Go to the DNS tab.

> The sigma streams processor is currently configured to put any matching records into a new topic called `dns-detection`. As you can see there is nothing in there.  This means nothing is matching.  Actually I can go back to my sigma UI and click on the DNS Data tab and see that gray represents record flow in the topic and red represents detections.

> So if there is a bot sending data out they aren’t dumb enough to use big long suspicious queries.  We will make it preposterously low to demonstrate that its working at all.

7. Edit the rule to change 180 to 8, publish, and go back to the DNS tab.

> You can now see that pretty much every DNS record matches which is what we would expect.  Let's set it back to 180 and let's publish a different new rule.

8. Edit the rule to change 8 back to to 180, publish, and go back to the DNS tab.

> If the bot isn’t publishing long queries then it's clearly keeping them more modest so that it will fly under the radar.  In this case we are looking for queries over 50 characters which are not rare but only key in on them IF you see more than 10 of them in a 5 second window.

9. Publish a new rule and then return to the DNS tab.
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
        query|re: ^.{50}.*$
      condition: query_length | count() > 10
      timeframe: 5s
    ```

> Now you can see we have matches.

10. Go to Control Center and look at records in the `dns-detection` topic.

> If you look at the DNS detections topic, you can see there's encoded data being tacked on to a domain called mrhaha.net. That's the rascal! This stream of just the detections can be passed to you SIEM tool via Kafka Connect, your SOAR, or another stream processor to take action.

> Now I’m going to leverage Confluent Sigma's RegEx extraction processor. There are various ways to apply regular expressions in Kafka Connect and ksqlDB, but Confluent Sigma was purpose-built to put data into a form easily consumable by Splunk or other SIEM tools.

11. Click on RegEx in the Confluent Sigma UI and paste in `cisco:asa` as the source type.

> The source type here allows us to specify that we only want to run the extractions on a single type of record, which is more efficient than running regular expressions on every record. The regular expression field allows us to specify a pattern with capture groups that will get extracted into fields.

12. Paste in the regular expression:
    ```re
    ^(?<timestamp>\w{3}\s\d{2}\s\d{2}:\d{2}:\d{2})\s(?<hostname>[^\s]+)\s\%ASA-\d-(?<messageID>[^:]+):\s(?<action>[^\s]+)\s(?<protocol>[^\s]+)\ssrc\sinside:(?<src>[0-9\.]+)\/(?<srcport>[0-9]+)\sdst\soutside:(?<dest>[0-9\.]+)\/(?<destport>[0-9]+)
    ```
> Next, we specify the topic where we want matching records to be sent, which in this case is `firewalls`. Then we can attach optional tags to matching records.

13. Put `firewalls` for the topic and attach tags `location = edge` , `sourcetype = cisco:asa` , `index = main` and submit the rule.

> The really amazing thing about using Sigma as the domain specific language is that new rules are published all the time. With Confluent Sigma, you can insert new rules into a special `sigma-rules` topic and the application will automatically pick them up and apply them to your data in real-time. This allows you to be much more proactive about staying on top of the latest threats.

## Optimize What Ends Up in Splunk

> So at this point we haven’t really done any substantial optimization on the data. We showed data enrichment and real-time threat detection, but now let's focus on how to optimize the data upstream of our SIEM tools. And I’m going to start off with some more filtering.

1. Go to the ksqlDB editor and create the Splunk stream and the filtered cisco_asa stream.
```sql
CREATE STREAM SPLUNK (
    `event` VARCHAR,
    `time` BIGINT,
    `host` VARCHAR,
    `source` VARCHAR,
    `sourcetype` VARCHAR,
    `index` VARCHAR
) WITH (
KAFKA_TOPIC='splunk-s2s-events', VALUE_FORMAT='JSON');
 
CREATE STREAM CISCO_ASA
AS SELECT
    `event`,
    `source`,
    `sourcetype`,
    `index`
FROM SPLUNK
WHERE `sourcetype` = 'cisco:asa'
EMIT CHANGES;
```

> With ksqlDB, we will give it a definition of the data types coming from the Splunk Universal Forwarder and then we will filter out all events that are not sourcetype cisco:asa.  In the real world, you would need to be more sophisticated about what you filter, but for this generated data it is effectively just filtering out some internal splunk messages.

> So suppose I know that we have a noisy but benign data producer.  I can go ahead and filter them out as well with this query.

2. Create query to filter out noisy producer.
    ```sql
    CREATE STREAM CISCO_ASA_FILTER_106023
    WITH (KAFKA_TOPIC='CISCO_ASA_FILTER_106023', PARTITIONS=1, REPLICAS=1, VALUE_FORMAT='AVRO')
    AS SELECT
        SPLUNK.`event` `event`,
        SPLUNK.`source` `source`,
        SPLUNK.`sourcetype` `sourcetype`,
        SPLUNK.`index` `index`
    FROM SPLUNK SPLUNK
    WHERE ((SPLUNK.`sourcetype` = 'cisco:asa') AND (NOT (SPLUNK.`event` LIKE '%ASA-4-106023%')))
    EMIT CHANGES;
    ```
> Note that while I’m filtering out in the derived stream, the original stream has all the raw data in it.  If I was required for compliance to hold on to this I could do so in a very cost effective way in Confluent using tiered storage.  In this case data over a certain age will go into S3 compatible storage, but the refined and much smaller data set can be sent to your SIEM.  With Confluent you can always rewind the original data stream (as long as you've defined a retention period) and reprocess it later if you realize that you want to adjust your rules. 

> Filtering is helpful, but you have to be certain and there is only so much you can filter.  So I want to demonstrate how to use windowed aggregations to massively compress recurring events.  In this case I’m going to use 60 second intervals.

3. Create the firewalls stream and create the windowed aggregation.
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
    ./scripts/submit-connector.sh kafka-connect/connectors/splunk-sink.json
    ```

6. Then execute
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

> So remember that voluminous DNS data we talked about in the beginning?  Well we are already analyzing this in real time with Sigma but suppose we wanted to index it all and do retrospective analysis. Maybe we don’t want to send it to Splunk because of its size. Maybe we want to leverage another tool, lets say Elastic, for this.  I can just as easily send a topic to Elastic as I can to Splunk.  So lets create a new sink connector for the enriched DNS we made.  Again, I’ll just execute a script for this.

1. In the terminal, submit the connector and then go to Connect -> connectors in Control Center.
    ```bash
    ./scripts/submit-connector.sh kafka-connect/connectors/elastic-sink.json
    ```

> You can now see we have a connector sending data to Elastic. Lets head over to Elastic to verify that its getting in.

2. Open Kibana, Elastic's web UI, on port `5601` from Remote Explorer (see [Gitpod tips](./gitpod-tips.md))

. From Kibana's hamburger menu on the top left, select "Discover" and create a data view with `rich*` to match the `rich_dns` index.

> As you can, see the data is here.  I’ll leave the Elastic analysis up to your imagination.

> I have sent data to Splunk and Elastic but I could have just as easily sent the data to a S3, a data lake, or whatever you want to use. This is an essential aspect of using Confluent to create an observability data fabric. it enables a vast ecosystem of tools rather than forcing you to use a single vendor. 

## Summary

>  In summary, this demo showed four advantages of using Confluent: 
>1. Detect threats directly in the streams of data in real-time with ksqlDB and Confluent Sigma.
>2. Decrease your Splunk costs by filtering and aggregating the data before it lands in Splunk.
>3. Gain insights from high volume data too expensive to index.
>4. Avoid vendor lock-in so that you can take advantage of the strengths of different SIEM vendors.
