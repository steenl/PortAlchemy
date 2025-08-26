#include <iostream>
#include <memory>
#include <vector>
#include "../include/packet.h"

int main() {
    ether test1;
    test1.set_src_ether("aa:aa:aa:aa:aa:aa");
    test1.set_dst_ether("aa:aa:ab:aa:aa:aa");

    ipv4 test2;
    test2.set_src_ipv4("127.0.0.1");
    test2.set_dst_ipv4("127.1.1.1");

    udp test3;
    test3.set_source_port("127");
    test3.set_dest_port("128");
    test3.payload.push_back(0xF);

    Packet p;
    p = test1 / test2 / test3;
    p.update();
}


/*
1. Add test functions to cross-check the actual bytes generated 
2. Right now can handle UDP or TCP or ICMP ONLY (with the ether and IPv4 layers) - Need to add a stack up layered sender ? just needs different handling at the packet level 
3. Add UA Link packet layers just like the current implemented ones 
*/