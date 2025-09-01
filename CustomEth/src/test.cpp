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

    std::array<uint8_t,5> payload_write_req;
    payload_write_req[0] = 0xFF;
    payload_write_req[1] = 0xDD;
    payload_write_req[2] = 0xCC;
    payload_write_req[3] = 0xBB;
    payload_write_req[4] = 0xAA;

    ualink test5;
    // Write request of 5 byte payload at the 0x2000 address
    test5.set_attributes(0x2000, payload_write_req.size(), 2, 0x10); // Write request
    p_write = test4 / test5;

    Packet p_read;
    std::array<uint8_t,2> payload_read_req;
    payload_read_req[0] = 0xFF; // dummy filled
    payload_read_req[1] = 0xFF; // dummy filled
    ualink test6;

    // Read request at the 0x2000 address 
    test6.set_attributes(0x2000, payload_read_req.size(), 1, 0x10); // Read request
    p_read = test4 / test6;

    RawEth sock_interface("enp36s0");
    p_read.send(payload_read_req.data(), sock_interface);
    p_write.send(payload_write_req.data(), sock_interface);
}


/*
1. Add test functions to cross-check the actual bytes generated 
2. Right now can handle UDP or TCP or ICMP ONLY (with the ether and IPv4 layers) - Need to add a stack up layered sender ? just needs different handling at the packet level 
3. Add UA Link packet layers just like the current implemented ones 
*/