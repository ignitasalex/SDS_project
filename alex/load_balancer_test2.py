from ryu.app import simple_switch_13
from ryu.controller import ofp_event
from ryu.controller.handler import CONFIG_DISPATCHER, MAIN_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.ofproto import ofproto_v1_3
from ryu.lib.packet import packet
from ryu.lib.packet import ether_types
from ryu.lib.packet import ipv4
from ryu.lib.mac import haddr_to_int
from ryu.lib.packet.ether_types import ETH_TYPE_IP
from ryu.lib.packet import arp
from ryu.lib.packet import ethernet

class LoadBalancer(simple_switch_13.SimpleSwitch13):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    VIRTUAL_IP = '10.0.0.202'  # The virtual server IP

    SERVER1_IP = '10.0.0.100'
    SERVER1_MAC = '00:00:00:00:02:01'
    SERVER1_PORT = 2
    SERVER2_IP = '10.0.0.200'
    SERVER2_MAC = '00:00:00:00:02:02'
    SERVER2_PORT = 3

    def __init__(self, *args, **kwargs):
        super(LoadBalancer, self).__init__(*args, **kwargs)
        self.mac_to_port = {}

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def _packet_in_handler(self, ev):
        if ev.msg.msg_len < ev.msg.total_len:
            self.logger.debug("packet truncated: only %s of %s bytes",
                              ev.msg.msg_len, ev.msg.total_len)
        msg = ev.msg
        datapath = msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        in_port = msg.match['in_port']

        pkt = packet.Packet(msg.data)
        eth = pkt.get_protocols(ethernet.ethernet)[0]

        if eth.ethertype == ether_types.ETH_TYPE_LLDP:
            return

        dst_mac = eth.dst
        src_mac = eth.src

        dpid = datapath.id
        self.mac_to_port.setdefault(dpid, {})

        self.logger.info("packet in %s %s %s %s", dpid, src_mac, dst_mac, in_port)

        # Extract IP layer information
        ip_pkt = pkt.get_protocol(ipv4.ipv4)
        if ip_pkt:
            src_ip = ip_pkt.src
            dst_ip = ip_pkt.dst
            self.logger.info("\nsrc_mac: %s, dst_mac: %s, src_ip: %s, dst_ip: %s\n",
                             src_mac, dst_mac, src_ip, dst_ip)

        self.mac_to_port[dpid][src_mac] = in_port

        if dst_mac in self.mac_to_port[dpid]:
            out_port = self.mac_to_port[dpid][dst_mac]
        else:
            out_port = ofproto.OFPP_FLOOD

        actions = [parser.OFPActionOutput(out_port)]

        if out_port != ofproto.OFPP_FLOOD:
            match = parser.OFPMatch(in_port=in_port, eth_dst=dst_mac, eth_src=src_mac)
            if msg.buffer_id != ofproto.OFP_NO_BUFFER:
                self.add_flow(datapath, 1, match, actions, msg.buffer_id)
                return
            else:
                self.add_flow(datapath, 1, match, actions)

        # Handle ARP Packet
        if eth.ethertype == ether_types.ETH_TYPE_ARP:
            arp_header = pkt.get_protocol(arp.arp)
            if arp_header.dst_ip == self.VIRTUAL_IP and arp_header.opcode == arp.ARP_REQUEST:
                # Build an ARP reply packet using source IP and source MAC
                reply_packet = self.arp_reply(arp_header.src_ip, arp_header.src_mac)
                actions = [parser.OFPActionOutput(in_port)]
                packet_out = parser.OFPPacketOut(datapath=datapath,
                                                 in_port=ofproto.OFPP_ANY,
                                                 data=reply_packet.data,
                                                 actions=actions,
                                                 buffer_id=ofproto.OFP_NO_BUFFER)
                datapath.send_msg(packet_out)
                self.logger.info("Sent the ARP reply packet")
                return

        # Handle TCP Packet
        if eth.ethertype == ETH_TYPE_IP:
            ip_header = pkt.get_protocol(ipv4.ipv4)
            if ip_header.dst == self.VIRTUAL_IP:
                self.handle_tcp_packet(datapath, in_port, ip_header, parser, dst_mac, src_mac)
                self.logger.info("TCP packet handled")
                return

        # Send if other packet
        data = None
        if msg.buffer_id == ofproto.OFP_NO_BUFFER:
            data = msg.data

        out = parser.OFPPacketOut(datapath=datapath,
                                  buffer_id=msg.buffer_id,
                                  in_port=in_port,
                                  actions=actions,
                                  data=data)
        datapath.send_msg(out)

    # Source IP and MAC passed here now become the destination for the reply packet
    def arp_reply(self, dst_ip, dst_mac):
        arp_target_ip = dst_ip  # the sender ip
        arp_target_mac = dst_mac  # the sender mac
        # Making the load balancer IP as source IP
        src_ip = self.VIRTUAL_IP

        if haddr_to_int(arp_target_mac) % 2 == 1:
            src_mac = self.SERVER1_MAC
        else:
            src_mac = self.SERVER2_MAC
        self.logger.info("\n************************************************************\nLoad balancer working Selected server MAC: " + src_mac)

        pkt = packet.Packet()
        pkt.add_protocol(ethernet.ethernet(dst=dst_mac, src=src_mac, ethertype=ether_types.ETH_TYPE_ARP))
        pkt.add_protocol(arp.arp(opcode=arp.ARP_REPLY, src_mac=src_mac, src_ip=src_ip, dst_mac=arp_target_mac, dst_ip=arp_target_ip))
        pkt.serialize()
        return pkt

    def handle_tcp_packet(self, datapath, in_port, ip_header, parser, dst_mac, src_mac):
        self.logger.info("Handling TCP packet: %s -> %s", ip_header.src, ip_header.dst)
        
        # Determine the server to redirect to (round robin or any other load balancing method can be implemented here)
        selected_server_ip, selected_server_mac, selected_server_port = self.SERVER1_IP, self.SERVER1_MAC, self.SERVER1_PORT
        
        if haddr_to_int(src_mac) % 2 == 0:
            selected_server_ip, selected_server_mac, selected_server_port = self.SERVER2_IP, self.SERVER2_MAC, self.SERVER2_PORT
        
        # Route to server
        match = parser.OFPMatch(in_port=in_port, eth_type=ETH_TYPE_IP, ip_proto=ip_header.proto,
                                ipv4_dst=self.VIRTUAL_IP)

        actions = [parser.OFPActionSetField(ipv4_dst=selected_server_ip),
                   parser.OFPActionSetField(eth_dst=selected_server_mac),
                   parser.OFPActionOutput(selected_server_port)]

        self.add_flow(datapath, 20, match, actions)
        self.logger.info("<==== Added TCP Flow- Route to Server: %s from Client: %s on Switch Port: %s ====>",
                         selected_server_ip, ip_header.src, selected_server_port)

        # Reverse route from server
        match = parser.OFPMatch(in_port=selected_server_port, eth_type=ETH_TYPE_IP,
                                ip_proto=ip_header.proto,
                                ipv4_src=selected_server_ip,
                                eth_dst=src_mac)
        actions = [parser.OFPActionSetField(ipv4_src=self.VIRTUAL_IP),
                   parser.OFPActionOutput(in_port)]

        self.add_flow(datapath, 20, match, actions)
        self.logger.info("<==== Added TCP Flow- Reverse route from Server: %s to Client: %s on Switch Port: %s ====>",
                         selected_server_ip, ip_header.src, in_port)

    def add_flow(self, datapath, priority, match, actions, buffer_id=None):
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        inst = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS, actions)]

        if buffer_id:
            mod = parser.OFPFlowMod(datapath=datapath, priority=priority, buffer_id=buffer_id,
                                    match=match, instructions=inst)
        else:
            mod = parser.OFPFlowMod(datapath=datapath, priority=priority,
                                    match=match, instructions=inst)
        datapath.send_msg(mod)
        self.logger.info("Flow added: %s", mod)
