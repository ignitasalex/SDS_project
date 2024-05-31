from operator import attrgetter

from ryu.app import simple_switch_13
from ryu.controller import ofp_event
from ryu.controller.handler import MAIN_DISPATCHER, DEAD_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.lib import hub

import socket
import datetime

UDP_IP = "127.0.0.1"
UDP_PORT = 8094


class SimpleMonitor13(simple_switch_13.SimpleSwitch13):

    def __init__(self, *args, **kwargs):
        super(SimpleMonitor13, self).__init__(*args, **kwargs)
        self.datapaths = {}
        self.monitor_thread = hub.spawn(self._monitor)

    @set_ev_cls(ofp_event.EventOFPStateChange,
                [MAIN_DISPATCHER, DEAD_DISPATCHER])
    def _state_change_handler(self, ev):
        datapath = ev.datapath
        if ev.state == MAIN_DISPATCHER:
            if datapath.id not in self.datapaths:
                self.logger.debug('register datapath: %016x', datapath.id)
                self.datapaths[datapath.id] = datapath
        elif ev.state == DEAD_DISPATCHER:
            if datapath.id in self.datapaths:
                self.logger.debug('unregister datapath: %016x', datapath.id)
                del self.datapaths[datapath.id]

    def _monitor(self):
        while True:
            for dp in self.datapaths.values():
                self._request_stats(dp)
            hub.sleep(10)

    def _request_stats(self, datapath):
        self.logger.debug('send stats request: %016x', datapath.id)
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        req = parser.OFPFlowStatsRequest(datapath)
        datapath.send_msg(req)

        req = parser.OFPPortStatsRequest(datapath, 0, ofproto.OFPP_ANY)
        datapath.send_msg(req)

    @set_ev_cls(ofp_event.EventOFPFlowStatsReply, MAIN_DISPATCHER)
    def _flow_stats_reply_handler(self, ev):

        FLOW_MSG = "flows,datapath=%x eth-dst=\"%s\",packets=%d,bytes=%d,ipv4-src=\"%s\",ipv4-dst=\"%s\" %d"
        body = ev.msg.body

        self.logger.info('stats received: %016x', ev.msg.datapath.id)

        if ev.msg.datapath.id == 3:

            for flow in body:
                ipv4_dst = flow.match.get('ipv4_dst', 'NA')
                ipv4_src = flow.match.get('ipv4_src', 'NA')

                # self.logger.info('[+] DEBUG: IP FLOW ENTRY - Source: %s, Destination: %s', ipv4_src, ipv4_dst)

                # Create a detailed string for the flow
                flow_details = (
                    f"Datapath ID: {ev.msg.datapath.id}, "
                    f"In-Port: {flow.match.get('in_port', 'NA')}, "
                    f"Eth-Dst: {flow.match.get('eth_dst', 'NA')}, "
                    # f"Out-Port: {flow.instructions[0].actions[0].port if flow.instructions else 'NA'}, "
                    f"Packets: {flow.packet_count}, "
                    f"Bytes: {flow.byte_count}, "
                    f"IPv4-Src: {ipv4_src}, "
                    f"IPv4-Dst: {ipv4_dst}"
                    f"Priority flow: {flow.priority}"
                )

                if flow.priority == 20:

                    timestamp = int(datetime.datetime.now().timestamp() * 1000000000)
                    msg = FLOW_MSG % (ev.msg.datapath.id,
                                    flow.match.get('eth_dst', 'NA'),
                                    flow.packet_count, flow.byte_count,
                                    ipv4_src, ipv4_dst,
                                    timestamp)
                    self.logger.info(msg)
                    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                    sock.sendto(msg.encode(), (UDP_IP, UDP_PORT))
            

    @set_ev_cls(ofp_event.EventOFPPortStatsReply, MAIN_DISPATCHER)
    def _port_stats_reply_handler(self, ev):
        PORT_MSG = "ports,datapath=%x,port=%x rx-pkts=%d,rx-bytes=%d,rx-error=%d,tx-pkts=%d,tx-bytes=%d,tx-error=%d %d"
        body = ev.msg.body
        self.logger.info('stats received: %016x', ev.msg.datapath.id)

        for stat in sorted(body, key=attrgetter('port_no')):
            timestamp = int(datetime.datetime.now().timestamp() * 1000000000)
            msg = PORT_MSG % (ev.msg.datapath.id, stat.port_no,
                             stat.rx_packets, stat.rx_bytes, stat.rx_errors,
                             stat.tx_packets, stat.tx_bytes, stat.tx_errors,
                             timestamp)
            self.logger.info(msg)
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.sendto(msg.encode(), (UDP_IP, UDP_PORT))
                             
                             
                             
                             
                             