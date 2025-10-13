#include <iostream>
#include <memory>
#include <vector>
#include "packet.h"
#include "io.h"
#include <chrono>

class FPGAInterface {
public:
    FPGAInterface(const std::string& dev, const std::string& s_mac, const std::string& d_mac) : 
    sock_interface(dev), src_mac(s_mac), dst_mac(d_mac) {}
    RawEth sock_interface;
    std::string src_mac;
    std::string dst_mac;
    int ack_timeout_ms = 200;
    int read_timeout_ms = 200;

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

        if (op == 2) {
            return wait_ack(ack_timeout_ms);
        } else if (op == 1) {
            std::vector<std::array<uint8_t,226>> response_vec;
            return wait_read(read_timeout_ms, payload_vec.size(), response_vec);
        }

        return false;
    }

    bool wait_ack (int timeout_ms) {
        auto start = std::chrono::steady_clock::now();
        std::vector<uint8_t> buf(256);
        while (true) {
            bool receive_ok = sock_interface.recv_on_wire(buf.data(), 256);
            if (receive_ok) {
                return true;
            }
            int elapsed = (int)std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::steady_clock::now() - start).count();
            if (elapsed >= timeout_ms) { 
                return false;
            }
        }
        return true;
    }

    bool wait_read (int timeout_ms, int num_expected_read_frames, std::vector<std::array<uint8_t,226>>& response_vec) {
        auto start = std::chrono::steady_clock::now();
        std::array<uint8_t,256> buf;
        int num_actual_read_frames;
        while (true) {
            bool receive_ok = sock_interface.recv_on_wire(buf.data(), 256);
            if (receive_ok) {
                num_actual_read_frames++;
                std::array<uint8_t,226> arr;
                std::copy(buf.begin(), buf.begin() + arr.size(), arr.begin());
                response_vec.push_back(arr);
                if (num_actual_read_frames == num_expected_read_frames) return true;
            }
            int elapsed = (int)std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::steady_clock::now() - start).count();
            if (elapsed >= timeout_ms) { 
                return false;
            }
        }
        return false;
    }

    void send_ack (uint64_t mem_addr, uint8_t tag) {
        std::array<uint8_t,226> payload_ack = {0xFF};
        Packet p_send;
        ether e_header;
        ualink ua_header;
        // we are limited to 226 bytes on the payload 
        // 14 + 16 bytes for the ether + ualink headers 
        uint8_t frame [14 + 16 + 226];
        e_header.set_src_ether(src_mac);
        e_header.set_dst_ether(dst_mac);
        // assuming that operation type here is 3 for ACK
        // TODO discuss and change if needed 
        ua_header.set_attributes(mem_addr, payload_ack.size(), 3, tag);
        p_send = e_header / ua_header;
        int bytes_to_send;
        p_send.prepare_send(payload_ack.data(), frame, bytes_to_send);
        sock_interface.send_on_wire(frame, bytes_to_send);
    }
};