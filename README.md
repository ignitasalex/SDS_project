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
alert icmp any any -> any any (msg:"Pinging...";sid:1100001;)
alert icmp any any -> $HOME_NET any (msg:"ICMP flood"; sid:1100002; classtype:icmp-event;detection_filter:track by_dst, count 500, seconds 3;)
alert tcp any any -> $HOME_NET 80 (flags: S; msg:"Possible DoS Attack Type : SYN flood";flow:stateless; sid:1100003; detection_filter:track by_dst, count 20, seconds 10;)
```

On the file /etc/snort/snort.conf comment all the rules that you don't need and add the following line:
```
include $RULE_PATH/projectRules.rules
```
Create an interface for s2 where snort will be listening:

```
sudo ip link add name s2-snort type dummy
sudo ip link set s2-snort up 
sudo ovs-vsctl add-port s2 s2-snort
```

In order to check it if the interface has been correctly updated you can use:
```
sudo ovs-ofctl show s2
```

Also in order to see the flows of the switch s2 you can execute:
```
sudo ovs-vsctl dump-flows s2
```

### Usage

Run on different terminals the following commands:

```bash
sudo python2 macTopology.py
sudo ryu-manager ./ryu/ryu/app/simple_switch_snort.py 
sudo snort -i s2-snort -A unsock -l /tmp -c /etc/snort/snort.conf
```
In order to simulate a DoS attack you can execute from the host1 execute:

```bash
sudo hping3 -S --flood -p 80 10.0.0.100
```


