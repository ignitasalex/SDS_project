# Activar el firewall
sudo ovs-vsctl set Bridge s1 protocols=OpenFlow13
sudo ovs-vsctl set Bridge s2 protocols=OpenFlow13
sudo ovs-vsctl set Bridge s3 protocols=OpenFlow13

curl -X PUT http://localhost:8080/firewall/module/enable/0000000000000001
curl -X PUT http://localhost:8080/firewall/module/enable/0000000000000002
curl -X PUT http://localhost:8080/firewall/module/enable/0000000000000003



sudo ovs-ofctl --protocols=OpenFlow13 add-flow s1 "table=0, priority=0, actions=drop"
sudo ovs-ofctl --protocols=OpenFlow13 add-flow s2 "table=0, priority=0, actions=drop"
#sudo ovs-ofctl --protocols=OpenFlow13 add-flow s3 "table=0, priority=0, actions=drop"



# Permitir tráfico hacia y desde la IP virtual del balanceador de carga

curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "10.0.0.202/32", "nw_proto": "TCP", "tp_dst": 80, "priority": 30}' http://localhost:8080/firewall/rules/0000000000000001
curl -X POST -d '{"nw_src": "10.0.0.202/32", "nw_dst": "10.0.0.0/24", "nw_proto": "TCP", "tp_src": 80, "priority": 30}' http://localhost:8080/firewall/rules/0000000000000001
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "10.0.0.202/32", "nw_proto": "TCP", "tp_dst": 80, "priority": 30}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "10.0.0.202/32", "nw_dst": "10.0.0.0/24", "nw_proto": "TCP", "tp_src": 80, "priority": 30}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "10.0.0.202/32", "nw_proto": "TCP", "tp_dst": 80, "priority": 30}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "10.0.0.202/32", "nw_dst": "10.0.0.0/24", "nw_proto": "TCP", "tp_src": 80, "priority": 30}' http://localhost:8080/firewall/rules/0000000000000003

# Permitir tráfico hacia los servidores backend con prioridad alta
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "10.0.0.100/32", "nw_proto": "TCP", "tp_dst": 80, "priority": 20}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "10.0.0.100/32", "nw_dst": "10.0.0.0/24", "nw_proto": "TCP", "tp_src": 80, "priority": 20}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "10.0.0.200/32", "nw_proto": "TCP", "tp_dst": 80, "priority": 20}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "10.0.0.200/32", "nw_dst": "10.0.0.0/24", "nw_proto": "TCP", "tp_src": 80, "priority": 20}' http://localhost:8080/firewall/rules/0000000000000002

# Permitir tráfico ICMP con prioridad baja
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "203.0.113.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "203.0.113.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "192.168.1.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "192.168.1.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000002

curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "203.0.113.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "203.0.113.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "TCP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "192.168.1.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "192.168.1.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003

curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "192.168.1.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000001
curl -X POST -d '{"nw_src": "192.168.1.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "ICMP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000001

# Reglas HTTP 80 con prioridad más baja para tráfico externo
curl -X POST -d '{"nw_src": "203.0.113.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "TCP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "203.0.113.0/24", "nw_proto": "TCP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000002
curl -X POST -d '{"nw_src": "203.0.113.0/24", "nw_dst": "10.0.0.0/24", "nw_proto": "TCP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003
curl -X POST -d '{"nw_src": "10.0.0.0/24", "nw_dst": "203.0.113.0/24", "nw_proto": "TCP", "priority": 10}' http://localhost:8080/firewall/rules/0000000000000003

# Reglas específicas de OpenFlow

sudo ovs-ofctl --protocols=OpenFlow13 add-flow s3 "cookie=0x0, table=0, priority=20, tcp, in_port=s3-eth2, nw_dst=10.0.0.202, actions=set_field:10.0.0.100->ip_dst,output:s3-eth1"
sudo ovs-ofctl --protocols=OpenFlow13 add-flow s3 "cookie=0x0, table=0, priority=20, tcp, in_port=s3-eth3, nw_dst=10.0.0.202, actions=set_field:10.0.0.100->ip_dst,output:s3-eth1"
sudo ovs-ofctl --protocols=OpenFlow13 add-flow s3 "cookie=0x0, table=0, priority=20, tcp, in_port=s3-eth1, dl_dst=00:00:00:00:03:01, nw_src=10.0.0.100, actions=set_field:10.0.0.202->ip_src,output:s3-eth2"
sudo ovs-ofctl --protocols=OpenFlow13 add-flow s3 "cookie=0x0, table=0, priority=20, tcp, in_port=s3-eth1, dl_dst=00:00:00:00:03:05, nw_src=10.0.0.100, actions=set_field:10.0.0.202->ip_src,output:s3-eth3"


sudo ovs-ofctl --protocols=OpenFlow13 add-flow s2 "cookie=0x0, table=0, priority=20, tcp, in_port=s2-eth1, nw_dst=10.0.0.202, actions=set_field:10.0.0.100->ip_dst,output:s2-eth2"
sudo ovs-ofctl --protocols=OpenFlow13 add-flow s2 "cookie=0x0, table=0, priority=20, tcp, in_port=s2-eth2, dl_dst=00:00:00:00:03:05, nw_src=10.0.0.100, actions=set_field:10.0.0.202->ip_src,output:s2-eth3"

sudo ovs-ofctl --protocols=OpenFlow13 add-flow s2 "cookie=0x0, table=0, priority=1, in_port=s2-eth2, dl_src=00:00:00:00:02:01, dl_dst=72:f2:f4:4a:46:9a, actions=output:s2-eth1"
sudo ovs-ofctl --protocols=OpenFlow13 add-flow s2 "cookie=0x0, table=0, priority=1, in_port=s2-eth1, dl_src=72:f2:f4:4a:46:9a, dl_dst=00:00:00:00:02:01, actions=output:s2-eth2"

