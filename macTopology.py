#!/usr/bin/env python

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import Node, OVSKernelSwitch, RemoteController, OVSSwitch, OVSController
from mininet.log import setLogLevel, info
from mininet.cli import CLI


class LinuxRouter( Node ):
    "A Node with IP forwarding enabled."

    # pylint: disable=arguments-differ
    def config( self, **params ):
        super( LinuxRouter, self).config( **params )
        # Enable forwarding on the router
        self.cmd( 'sysctl net.ipv4.ip_forward=1' )

    def terminate( self ):
        self.cmd( 'sysctl net.ipv4.ip_forward=0' )
        super( LinuxRouter, self ).terminate()


class NetworkTopo( Topo ):
    "A LinuxRouter connecting three IP subnets"

    # pylint: disable=arguments-differ
    def build( self, **_opts ):

        defaultIP = '192.168.1.1/24'  # IP address for r0-eth1
        router = self.addNode( 'r0', cls=LinuxRouter, ip=defaultIP, mac='00:00:00:00:00:01')

        s1, s2, s3 = [ self.addSwitch( s ) for s in ( 's1', 's2','s3') ]

        self.addLink( s1, router, intfName2='r0-eth1',
                      params2={ 'ip' : defaultIP } )  # for clarity
        self.addLink( s2, router, intfName2='r0-eth2',
                      params2={ 'ip' : '10.0.0.1/24' } )
        self.addLink( s3, router, intfName2='r0-eth3',
                      params2={ 'ip': '203.0.113.1/24' } )

        dbserver = self.addHost( 'dbserver', ip='192.168.1.100/24',
                           defaultRoute='via 192.168.1.1',
                           mac='00:00:00:00:01:01' )
        server1 = self.addHost( 'server1', ip='10.0.0.100/24',
                           defaultRoute='via 10.0.0.1',
                            mac='00:00:00:00:02:01' )
        server2 = self.addHost( 'server2', ip='10.0.0.200/24',
                           defaultRoute='via 10.0.0.1',
                            mac='00:00:00:00:02:02' )
        
        h2 = self.addHost( 'h2', ip='10.0.0.205/24',
                           defaultRoute='via 10.0.0.1',
                            mac='00:00:00:00:02:03' )
        
        host1 = self.addHost( 'host1', ip='203.0.113.100/24',
                          defaultRoute='via 203.0.113.1',
                            mac='00:00:00:00:03:01' )


        host5 = self.addHost( 'host5', ip='203.0.113.105/24',
                          defaultRoute='via 203.0.113.1',
                            mac='00:00:00:00:03:05' )

        for h, s in [ (dbserver, s1), (server1, s2), (server2, s2),(h2,s2), (host1,s3), (host5,s3)]:
            self.addLink( h, s )

        # self.addLink(host1, router, intfName2='r0-eth3', params2={'ip': '203.0.113.1/24'})

def run():
    topo = NetworkTopo()
    net = Mininet( topo=topo,
    		       controller=RemoteController('c0', protocols="OpenFLow13"),
                   waitConnected=True,
                   switch=OVSKernelSwitch,
                   )
    net.start()

    net['host1'].cmd('sysctl -w net.ipv6.conf.all.disable_ipv6=1')
    net['server1'].cmd('sysctl -w net.ipv6.conf.all.disable_ipv6=1')
    net['server2'].cmd('sysctl -w net.ipv6.conf.all.disable_ipv6=1')
    net['dbserver'].cmd('sysctl -w net.ipv6.conf.all.disable_ipv6=1')
    net['r0'].cmd('sysctl -w net.ipv6.conf.all.disable_ipv6=1')

    info( '*** Routing Table on Router:\n' )
    info( net[ 'r0' ].cmd( 'route' ) )

    net[ 'server1' ].cmd( 'python3 -m http.server 80 &' )
    net[ 'server2' ].cmd( 'python3 -m http.server 80 &' )
    # info[net[ 'host1' ].cmd( 'wget 10.0.0.202 &')]

    CLI( net )
    net.stop()


if __name__ == '__main__':
    setLogLevel( 'info' )
    run()
