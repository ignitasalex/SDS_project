sudo ovs-vsctl set Bridge s1 protocols=OpenFlow13
sudo ovs-vsctl set Bridge s2 protocols=OpenFlow13


curl -X PUT http://localhost:8080/firewall/module/enable/0000000000000001

curl -X PUT http://localhost:8080/firewall/module/enable/0000000000000002


curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "203.0.113.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "203.0.113.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000002

curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000002

curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "192.168.1.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "192.168.1.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000002

curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "192.168.1.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000001
curl -X POST -d '{"nw_src": "192.168.1.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP"}' http://localhost:8080/firewall/rules/0000000000000001

# Drop default rules:
sudo ovs-ofctl --protocols=OpenFlow13 add-flow s1 "table=0, priority=0, actions=drop"
sudo ovs-ofctl --protocols=OpenFlow13 add-flow s2 "table=0, priority=0, actions=drop"
