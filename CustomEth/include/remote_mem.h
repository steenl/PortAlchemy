#include "fpga_interface.h"
class RemoteMem {
public:
    RemoteMem (const std::string& dev, const std::string& s_mac, const std::string& d_mac): remote_interface(dev, s_mac, d_mac) {};
    uint64_t alloc (size_t size) {
        return 1;
    }
    void write (std::vector<std::array<uint8_t,226>>& payload_vec) {
        remote_interface.send_batch_wait_ack(payload_vec, base_addr, 1, tag);
    }
    void read (std::vector<std::array<uint8_t,226>>& payload_vec) {
        remote_interface.send_batch_wait_ack(payload_vec, base_addr, 2, tag);
    }
    void free ();
    FPGAInterface remote_interface;
    uint64_t base_addr;
    uint8_t tag;
};