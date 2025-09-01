#pragma once
#include <array>
#include <iostream>
#include <sstream>
#include <vector>
#include "util/checksum.h"

enum class Kind {
  DEFAULT,
  ETHER, 
  IPV4, 
  UDP,
  TCP,
  ICMP,
  IPV6,
  UALINK
};

struct Layer {
  virtual ~Layer() = default;
  virtual Kind kind() {
    return Kind::DEFAULT;
  }
  virtual int get_header_length() {
    return 0;
  }
  virtual int get_physical_length() {
    return 0;
  }
  virtual void update_len(int len) {}
  virtual void update_checksum() {}
};

struct ether: Layer {
    uint16_t ethertype{0x0800};
    std::array<uint8_t, 6> src{}, dst{};

    void set_src_ether (const std::string& src_mac) {
        std::istringstream data(src_mac);
        std::string line;
        int index = 0;
        while(std::getline(data,line,':')) {
            uint8_t temp = std::stoi(line, nullptr, 16);
            src[index] = static_cast<uint8_t>(temp);
            index++;
        }
    }

    void set_dst_ether (const std::string& dst_mac) {
        std::istringstream data(dst_mac);
        std::string line;
        int index = 0;
        while(std::getline(data,line,':')) {
            uint8_t temp = std::stoi(line, nullptr, 16);
            dst[index] = static_cast<uint8_t>(temp);
            index++;
        }
    }

    Kind kind() override {
        return Kind::ETHER;
    }

    int get_header_length() override {
        return 14;
    }

    int get_physical_length() override {
        return 14;
    }
};

struct ipv4: Layer {
    uint8_t ihl = 5;
    uint8_t tos = 0;
    uint16_t total_len = 0;
    uint16_t id = 0;
    uint16_t flag_fragment = 0;
    uint8_t  ttl = 64, proto = 17;
    uint16_t checksum = 0;
    std::array<uint8_t, 4> src{}, dst{};

    uint16_t len_after_ip_header = 0;

    Kind kind() override {
        return Kind::IPV4;
    }

    void set_dst_ipv4 (const std::string& dst_ip) {
        std::istringstream data(dst_ip);
        std::string line;
        int index = 0;
        while(std::getline(data,line,':')) {
            uint8_t temp = std::stoi(line, nullptr, 16);
            dst[index] = static_cast<uint8_t>(temp);
            index++;
        }
    }

    void set_src_ipv4 (const std::string& src_ip) {
        std::istringstream data(src_ip);
        std::string line;
        int index = 0;
        while(std::getline(data,line,':')) {
            uint8_t temp = std::stoi(line, nullptr, 16);
            src[index] = static_cast<uint8_t>(temp);
            index++;
        }
    }

    int get_header_length () override {
        return 20;
    }

    int get_physical_length() override {
        return 20;
    }
};

struct udp: Layer {
    uint16_t sport = 0;
    uint16_t dport = 0;
    uint16_t checksum = 0;
    uint16_t len = 8;
    std::vector<uint8_t> payload;

    void set_source_port(const std::string& s_port) {
        sport = static_cast<uint16_t>(std::stoi(s_port));
    }

    void set_dest_port(const std::string& d_port) {
        dport = static_cast<uint16_t>(std::stoi(d_port));
    }

    Kind kind() override {
        return Kind::UDP;
    }

    int get_header_length () override {
        return 8;
    }
    int get_physical_length() override {
        return static_cast<uint16_t>(8 + payload.size());
    }
};


struct tcp: Layer {
    uint16_t sport = 0;
    uint16_t dport = 0;
    uint32_t seq = 0;
    uint32_t ack = 0;
    uint8_t  data_offset = 5;
    uint8_t flags = 0;
    uint16_t window = 65535;
    uint16_t checksum = 0;
    uint16_t urgent_ptr = 0;
    std::vector<uint8_t> options;
    std::vector<uint8_t> payload;

    Kind kind() override {
        return Kind::TCP;
    }

    int get_header_length () override {
        return static_cast<uint16_t>(4 * data_offset);
    }

    int get_physical_length() override {
        return static_cast<uint16_t>(get_header_length() + payload.size());
    }
};

struct ualink: Layer {
    struct header {
        uint8_t  ver_type;
        uint8_t  op;
        uint8_t tag;
        uint8_t req_len;
        uint16_t req_attr;
        uint64_t base_addr;
        uint16_t pad = 0;
    };

    header ua_hdr; 
    uint64_t user_addr;
    uint8_t num_bytes; //payload

    Kind kind() override {
        return Kind::UALINK;
    }

    void calc_req_addr_attr() {
        ua_hdr.base_addr = user_addr & ~0x7ULL;
        uint16_t off  = (uint16_t)(user_addr - ua_hdr.base_addr);
        uint16_t span = off + num_bytes;
        uint16_t dw  = (span + 7) / 8;
        ua_hdr.req_len = (uint8_t)(dw - 1);
        uint32_t first_bytes = (num_bytes <= (8 - off)) ? num_bytes : (8 - off);
        uint8_t first_mask = (first_bytes == 8 && off == 0)
                    ? 0xFF
                    : (uint8_t)(((1u << first_bytes) - 1u) << off);
        uint8_t last_mask;
        if (dw == 1) {
            last_mask = 0;
        } else {
            uint32_t tail = (off + num_bytes) % 8;
            last_mask = (tail == 0) ? 0xFF : (uint8_t)((1u << tail) - 1u);
        }

        ua_hdr.req_attr = (first_mask) | (last_mask << 8);
    }

    void set_attributes(uint64_t u_add, uint8_t payload_size, uint8_t rw, uint8_t tag) {
        user_addr = u_add;
        num_bytes = payload_size;
        ua_hdr.op = rw;
        ua_hdr.ver_type = (1u<<4) | 0;
        ua_hdr.tag = tag;
    }
};
