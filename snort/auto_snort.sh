sudo ovs-vsctl add-port s2 s2-snort
sudo ovs-vsctl -- set Bridge s2 mirrors=@m -- --id=@s2-snort get Port s2-snort -- --id=@m create Mirror name=m0 select-all=true output-port=@s2-snort
sudo snort -i s2-snort -A unsock -l /tmp -c /etc/snort/snort.conf