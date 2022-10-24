# DEPRECATED

Active development on this demo is now taking place at https://github.com/confluentinc/demo-siem-optimization. Cheers!

# Optimize SIEM With Confluent

The examples in this repository give you hands-on experience optimizing Security Information and Event Management (SIEM) solutions using Confluent. Each tutorial illustrates how to use Confluent to improve the response to a common cybersecurity scenario.

## Hands-On in Your Browser

This demo runs best using Gitpod. Gitpod uses your existing git service account (GitHub, Gitlab, or BitBucket) for authentication. See the [gitpod tips](./instructions/gitpod-tips.md) to get acquainted with gitpod.

**Launch a workspace** to get hands-on with the labs:
- https://gitpod.io/#https://github.com/confluentinc/demo-siem-optimization

If you want to launch a workspace that **automatically submits all connectors**, use this link instead:
- https://gitpod.io/#SUBMIT_CONNECTORS=true/https://github.com/confluentinc/demo-siem-optimization

If you want to run locally or in a different environment, see the [appendix](./instructions/appendix.md).

### Hands-On Lab Instructions

Run through entire end-to-end demo to get the big picture. Zoom in on the individual labs to go into more detail.

0. [End-to-End Demo](./instructions/00-executive-demo.md) (long)
1. [Introduction](./instructions/01-introduction.md)
2. [Analyze Syslog Data in Real Time with ksqlDB](./instructions/02-syslog.md)
3. [Calculate Hourly Bandwidth Usage By Host with ksqlDB](./instructions/03-bandwidth.md)
4. [Match Hostnames in a Watchlist Against Streaming DNS Data](./instructions/04-watchlist.md)
5. [Filter SSL Transactions and Enrich with Geospatial Data](./instructions/05-ssl.md)

## References

### Demo Video

- https://www.confluent.io/resources/video/how-to-optimize-your-siem-platforms-with-confluent/

### Executive Brief

- https://assets.confluent.io/m/1eb84018eaad8291/

### Cyber Defense Whitepaper

- https://assets.confluent.io/m/34ffc6b59ead86e5/

### Confluent Sigma


- https://github.com/confluentinc/cyber/tree/master/confluent-sigma

