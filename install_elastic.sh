#! /usr/bin/env bash

# check root privileges
if [[ $(id -u) -ne 0 ]]; then
  echo "Please run the script with sudo or as root."
  exit 1
fi

# install elasticsearch 6.8.23
apt update
apt install -y apt-transport-https openjdk-8-jre-headless
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/elastic-archive-keyring.gpg
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-6.x.list
apt update && sudo apt install -y elasticsearch
/bin/systemctl daemon-reload
/bin/systemctl enable elasticsearch.service
systemctl start elasticsearch.service
systemctl status elasticsearch.service
echo "Waiting for ElasticSearch to boot up..."
sleep 20
curl -X GET "localhost:9200/_cat/health?v"