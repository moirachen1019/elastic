#! /usr/bin/env bash

# check root privileges
if [[ $(id -u) -ne 0 ]]; then
  echo "Please run the script with sudo or as root."
  exit 1
fi

ip_address=$(ip route get 8.8.8.8 | awk '{print $7}')
hosts="[\"$ip_address\"]" # Default hosts with the current IP address
# parse command-line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --cluster_name)
      cluster_name="$2"
      shift
      shift
      ;;
    --node_name)
      node_name="$2"
      shift
      shift
      ;;
    --hosts)
      shift
      hosts="[\"$ip_address\""
      shift
      while [[ $# -gt 0 ]]; do
        hosts="$hosts, \"$1\""
        shift
      done
      hosts="$hosts]"
      ;;
    *)
      echo "Invalid option: $1"
      exit 1
      ;;
  esac
done

# Check if all required arguments are provided
if [ -z "$cluster_name" ] || [ -z "$node_name" ]; then
  echo "Usage: $0 --cluster_name <cluster_name> --node_name <node_name> --hosts [host ip]..."
  exit 1
fi

# configure elasticsearch
echo "Starting to configure elasticsearch..."
config_path="/etc/elasticsearch/elasticsearch.yml"
cors_config='
http.cors.allow-origin: "*"
http.cors.enabled: true
http.cors.allow-credentials: true
http.cors.allow-methods: OPTIONS, POST
http.cors.allow-headers: X-Requested-With, X-Auth-Token, Content-Type, Content-Length, Authorization, Access-Control-Allow-Headers, Accept
'
# check if the elasticsearch.yml file exists
if [ -f $config_path ]; then
    # cluster.name
    sed -i 's/#cluster.name:/cluster.name:/' $config_path
    sed -i "s/cluster.name: .*/cluster.name: $cluster_name/" $config_path
    # node.name
    sed -i 's/#node.name:/node.name:/' $config_path
    sed -i "s/node.name: .*/node.name: $node_name/" $config_path
    # node.master
    sed -i 's/#node.master:/node.master:/' $config_path
    sed -i "s/node.master: .*/node.master: true/" $config_path
    # network.host
    sed -i 's/#network.host:/network.host:/' $config_path
    sed -i "s/network.host: .*/network.host: $ip_address/" $config_path
    # http.port
    sed -i 's/#http.port:/http.port:/' $config_path
    sed -i "s/http.port: .*/http.port: 9200/" $config_path 
    # discovery.zen.ping.unicast.hosts
    # echo $hosts
    sed -i 's/#discovery.zen.ping.unicast.hosts:/discovery.zen.ping.unicast.hosts:/' $config_path
    sed -i "s/discovery.zen.ping.unicast.hosts: .*/discovery.zen.ping.unicast.hosts: $hosts/" $config_path
    echo "$cors_config" >> $config_path
    echo "Config file updated"
else
    echo "elasticsearch.yml file not found"
fi
