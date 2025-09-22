#include <iostream>
#include <memory>
#include <vector>
#include "../include/fpga_interface.h"

int main() {
    /*
    Here we create a batch of packets to be sent out 
    And wait for ack 
    This is for requesting to write some payload into memory 
    */

    int counter = 10;
    std::array<uint8_t,5> payload_write_req;
    payload_write_req[0] = 0xFF;
    payload_write_req[1] = 0xDD;
    payload_write_req[2] = 0xCC;
    payload_write_req[3] = 0xBB;
    payload_write_req[4] = 0xAA;
    RawEth sock_interface("enp36s0");
    uint8_t frame[14 + 16 + 230];

    for (int i = 0; i < counter; i++) {
        Packet p_write;
        ether test4;
        test4.set_src_ether("aa:aa:aa:aa:aa:aa");
        test4.set_dst_ether("aa:aa:ab:aa:aa:aa");
        ualink test5;
        // Write request of 5 byte payload at the 0x2000 address
        test5.set_attributes(0x2000, payload_write_req.size(), 2, 0x10); // Write request
        p_write = test4 / test5;
        int bytes_to_send = 0;
        p_write.prepare_send(payload_write_req.data(), frame, bytes_to_send);
        sock_interface.send_on_wire(frame, bytes_to_send);
    }

    Packet expected_ack;
    ether ether_ack;
    ualink ualink_ack;
    uint8_t buf_ack[256];
    expected_ack = ether_ack / ualink_ack;
    // put a timeout here to break out of the loop
    while (true) {
        if (sock_interface.recv_on_wire(buf_ack, 256) > 0) {
            expected_ack.prepare_packet_recv(buf_ack);
            // break condition here in case the ack is actually received 
        }
    }
}


/*
1. Add test functions to cross-check the actual bytes generated 
2. Right now can handle UDP or TCP or ICMP ONLY (with the ether and IPv4 layers) - Need to add a stack up layered sender ? just needs different handling at the packet level 
3. Add UA Link packet layers just like the current implemented ones 
*/