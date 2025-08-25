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
  IPV6
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

    void update_checksum () {
        total_len = len_after_ip_header + (4 * static_cast<uint16_t> (ihl));
        uint16_t calc_checksum[10];

        calc_checksum[0] = (4 << 12) | (ihl & 0xF) << 8 | (tos & 0xFF);
        calc_checksum[1] = total_len;
        calc_checksum[2] = id;
        calc_checksum[3] = flag_fragment;
        calc_checksum[4] = (ttl << 8) | proto;
        calc_checksum[5] = 0x0000;
        calc_checksum[6] = (src[0] << 8) | src[1];
        calc_checksum[7] = (src[2] << 8) | src[3];
        calc_checksum[8] = (dst[0] << 8) | dst[1];
        calc_checksum[9] = (dst[2] << 8) | dst[3];

        checksum = ipv4_checksum(calc_checksum);
    }

    void update_len (int len) {
        len_after_ip_header = len;
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
