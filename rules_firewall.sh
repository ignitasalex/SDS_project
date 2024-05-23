# Activate the firewall
sudo ovs-vsctl set Bridge s1 protocols=OpenFlow13
sudo ovs-vsctl set Bridge s2 protocols=OpenFlow13
sudo ovs-vsctl set Bridge s3 protocols=OpenFlow13

curl -X PUT http://localhost:8080/firewall/module/enable/0000000000000001
curl -X PUT http://localhost:8080/firewall/module/enable/0000000000000002
curl -X PUT http://localhost:8080/firewall/module/enable/0000000000000003

curl http://localhost:8080/firewall/module/status

# ICMP traffic rules for s2
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "203.0.113.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "203.0.113.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "192.168.1.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "192.168.1.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000002

# ICMP and TCP traffic rules for s3
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "203.0.113.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "203.0.113.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "TCP"}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "192.168.1.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "192.168.1.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000003

# ICMP traffic rules for s1
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "192.168.1.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000001
curl -X POST -d '{"nw_src": "192.168.1.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000001

# Allow ICMP traffic with low priority
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "203.0.113.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "203.0.113.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "192.168.1.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "192.168.1.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "203.0.113.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "203.0.113.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "192.168.1.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "192.168.1.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "192.168.1.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000001
curl -X POST -d '{"nw_src": "192.168.1.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000001
