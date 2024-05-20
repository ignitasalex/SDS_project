# SDS_project

To run the topology with python2:

```bash
sudo python2 macTopology.py
```

## Snort

### Install

```bash
sudo apt install snort
```
### Configuration
On /etc/snort/rules create the file 'projectRules.rules' with the following content (also available on the repository):

```text
alert icmp any any -> 10.0.0.100 any (msg:"ICMP Flood to server1 Detected"; sid:1000004; classtype:icmp-event; detection_filter:track by_dst, count 50, seconds 10;)
alert icmp any any -> 10.0.0.200 any (msg:"ICMP Flood to server2 Detected"; sid:1000005; classtype:icmp-event; detection_filter:track by_dst, count 50, seconds 10;)

alert tcp any any -> 10.0.0.100 80 (flags:S; msg:"SYN Flood to server1 Detected"; sid:1000006; classtype:attempted-dos; detection_filter:track by_dst, count 30, seconds 10;)
alert tcp any any -> 10.0.0.200 80 (flags:S; msg:"SYN Flood to server2 Detected"; sid:1000007; classtype:attempted-dos; detection_filter:track by_dst, count 30, seconds 10;)

alert tcp any any -> 10.0.0.100 80 (msg:"TCP Connection Flood to server1 Detected"; sid:1000008; classtype:attempted-dos; detection_filter:track by_dst, count 100, seconds 10;)
alert tcp any any -> 10.0.0.200 80 (msg:"TCP Connection Flood to server2 Detected"; sid:1000009; classtype:attempted-dos; detection_filter:track by_dst, count 100, seconds 10;)
```

On the file /etc/snort/snort.conf comment all the rules that you don't need and add the following line:

```
include $RULE_PATH/projectRules.rules
```

Restart snort to apply changes:

```bash
sudo systemctl restart snort
sudo systemctl restart snort.service
```

### Usage

Create an interface for s2 where snort will be listening:

```
sudo ip link add name s2-snort type dummy
sudo ip link set s2-snort up 
```

Run mininet topology instance:

``
sudo python2 macTopology.py
```

Set interface s2-snort to switch s2:
```
sudo ovs-vsctl add-port s2 s2-snort
```

Run ryu-manager with switch snort:

```bash
sudo ryu-manager simple_switch_snort.py
```

In order to check it if the interface has been correctly updated you can use:
```
sudo ovs-ofctl show s2
```

Also in order to see the flows of the switch s2 you can execute:
```
sudo ovs-ofctl dump-flows s2
```

Mirror all traffic to interface s2-snort:
```bash
sudo ovs-vsctl -- set Bridge s2 mirrors=@m -- --id=@s2-snort get Port s2-snort -- --id=@m create Mirror name=m0 select-all=true output-port=@s2-snort
```

Start snort:

```bash
sudo snort -i s2-snort -A unsock -l /tmp -c /etc/snort/snort.conf
```

Execute the DoS attack in the terminal of host1 (xterm host1) to server1 (10.0.0.100) or server2 (10.0.0.200):

```bash
hping3 -V -1 -d 1400 --faster 10.0.0.100
```
