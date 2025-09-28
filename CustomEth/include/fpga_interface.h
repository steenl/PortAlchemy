#include <iostream>
#include <memory>
#include <vector>
#include "packet.h"
#include "io.h"

class FPGAInterface {
public:
    FPGAInterface(const std::string& dev, const std::string& s_mac, const std::string& d_mac) : 
    sock_interface(dev), src_mac(s_mac), dst_mac(d_mac) {}
    RawEth sock_interface;
    std::string src_mac;
    std::string dst_mac;

    bool send_batch_wait_ack (std::vector<std::array<uint8_t,226>>& payload_vec, uint64_t mem_addr, uint8_t op, uint8_t tag) {
        for (int i = 0; i < payload_vec.size(); i++) {
            Packet p_send;
            ether e_header;
            ualink ua_header;
            // we are limited to 226 bytes on the payload 
            // 14 + 16 bytes for the ether + ualink headers 
            uint8_t frame [14 + 16 + 226];
            e_header.set_src_ether(src_mac);
            e_header.set_dst_ether(dst_mac);
            ua_header.set_attributes(mem_addr, payload_vec[i].size(), op, tag);
            p_send = e_header / ua_header;
            int bytes_to_send;
            p_send.prepare_send(payload_vec[i].data(), frame, bytes_to_send);
            sock_interface.send_on_wire(frame, bytes_to_send);
        }

        if (wait_ack()) return true;
        return false;
    }

    bool wait_ack () {
        return true;
    }
};