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

    // Build a ETHER + UALINK packet 
    Packet p_write;
    ether test4;
    test4.set_src_ether("aa:aa:aa:aa:aa:aa");
    test4.set_dst_ether("aa:aa:ab:aa:aa:aa");

    std::array<uint8_t,2> payload;
    payload[0] = 0xFF;
    payload[1] = 0xDD;

    ualink test5;
    test5.set_attributes(0x2000, payload.size(), 2, 0x10); // Write request
    p_write = test4 / test5;
    p_write.send(payload.data());

    Packet p_read;
    std::array<uint8_t,2> payload_recv;
    payload_recv[0] = 0xFF; // dummy filled
    payload_recv[1] = 0xFF; // dummy filled
    ualink test6;
    test6.set_attributes(0x2000, payload_recv.size(), 1, 0x10); // Read request
    p_read = test4 / test6;
    p_read.send(payload_recv.data());
}


/*
1. Add test functions to cross-check the actual bytes generated 
2. Right now can handle UDP or TCP or ICMP ONLY (with the ether and IPv4 layers) - Need to add a stack up layered sender ? just needs different handling at the packet level 
3. Add UA Link packet layers just like the current implemented ones 
*/