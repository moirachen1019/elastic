#! /usr/bin/env bash
# check root privileges
if [[ $(id -u) -ne 0 ]]; then
  echo "Please run the script with sudo or as root."
  exit 1
fi

ip_address=$(ifconfig ens34 | grep 'inet ' | awk '{print $2}')

# parse command-line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --c)
      cluster_name="$2"
      shift
      shift
      ;;
    --n)
      node_name="$2"
      shift
      shift
      ;;
    --min)
      min_master="$2"
      shift
      shift
      ;;
    --master_eligible)
      master_eligible="$2"
      shift
      shift
      ;;
    --client_node)
      client_node="$2"
      shift
      shift
      ;;
    --heap)
      heap="$2"
      shift
      shift
      ;;
    --h)
      hosts="["
      shift
      while [[ $# -gt 0 ]]; do
        hosts="$hosts\"$1\""
        shift
        if [[ $# -gt 0 ]]; then
          hosts="$hosts,"
        fi
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
  echo "Usage: $0 --c <cluster_name> --n <node_name> --min <min_master_node_number> --master_eligible <1/0: is master eligible> --client_node <1/0: is client node> --heap <heap_memory_size> "
  exit 1
fi

echo "Cluster Name: $cluster_name"
echo "Node Name: $node_name"
echo "IP: $ip_address"
echo "Hosts: $hosts"

# configure elasticsearch.yml
echo "Starting to configure elasticsearch.yml..."
config_path="/etc/elasticsearch/elasticsearch.yml"
data_path="/mnt/hdd/elasticsearch"
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
    # path.data
    sed -i "s|^path.data:.*|path.data: $data_path|" $config_path
    # node.master
    if [ "$master_eligible" -eq 0 ]; then
      echo "node.master: false" >> "$config_path"
    fi
    # client node
    if [ "$client_node" -eq 1 ]; then
      echo "node.data: false" >> "$config_path"
    fi    # network.host
    sed -i 's/#network.host:/network.host:/' $config_path
    sed -i "s/network.host: .*/network.host: $ip_address/" $config_path
    # http.port
    sed -i 's/#http.port:/http.port:/' $config_path
    sed -i "s/http.port: .*/http.port: 9200/" $config_path 
    # discovery.zen.ping.unicast.hosts
    sed -i 's/#discovery.zen.ping.unicast.hosts:/discovery.zen.ping.unicast.hosts:/' $config_path
    sed -i "s/discovery.zen.ping.unicast.hosts: .*/discovery.zen.ping.unicast.hosts: $hosts/" $config_path
    echo "$cors_config" >> $config_path
    # discovery.zen.minimum_master_nodes
    sed -i 's/#discovery.zen.minimum_master_nodes:/discovery.zen.minimum_master_nodes:/' $config_path
    sed -i "s/discovery.zen.minimum_master_nodes: .*/discovery.zen.minimum_master_nodes: $min_master/" $config_path
    echo "elasticsearch.yml file updated"
else
    echo "elasticsearch.yml file not found"
fi

# configure jvm.options
echo "Starting to configure jvm.options..."
config_path="/etc/elasticsearch/jvm.options"

if [ -f $config_path ]; then
    # -Xms
    sed -i 's/-Xms[0-9]\+g/-Xms'$heap'g/' $config_path
    # -Xmx
    sed -i 's/-Xmx[0-9]\+g/-Xmx'$heap'g/' $config_path
    echo "jvm.options file updated"
else
    echo "jvm.options file not found"
fi

# restart elasticsearch
systemctl restart elasticsearch.service
