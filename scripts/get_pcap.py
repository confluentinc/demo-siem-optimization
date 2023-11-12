import os
import requests

# This script pulls a 1GB pcap file from an open S3 bucket
# TODO: pull the bucket/object values from a config file

print("Renaming existing zeek_streamer.pcap file")
if os.path.exists('./pcaps/zeek_streamer.pcap'):
    os.rename('./pcaps/zeek_streamer.pcap', './pcaps/zeek_streamer.pcap.bak')

url = 'https://demo-siem-optimization.s3.us-east-2.amazonaws.com/pcaps/zeek_streamer.pcap'
headers = {'Host': 'demo-siem-optimization.s3.us-east-2.amazonaws.com'}
print("Downloading pcap file...")
r = requests.get(url, headers=headers)
pcap_binary = r.content

print("Writing file to disk...")
with open("./pcaps/zeek_streamer.pcap", "wb") as pcap:
    pcap.write(pcap_binary)

print("Done")