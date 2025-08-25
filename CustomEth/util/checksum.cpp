#include "../include/util/checksum.h"

uint16_t ipv4_checksum(uint16_t* header) {
    uint32_t sum = 0;
    uint16_t* temp = header;

    for (int i = 0; i < 10; i++) {
        sum += *temp++;
    }

    sum = (sum & 0xFFFF) + (sum >> 16);

    return static_cast<uint16_t>(~sum);
}

uint16_t udp_checksum_helper(uint16_t* pseudo_header, uint16_t* udp_header, const std::vector<uint8_t>& payload) {
    uint32_t sum_pseudo_header = 0;
    uint16_t* temp_p_header = pseudo_header;
    for (int i = 0; i < 6; i++) {
        sum_pseudo_header += *temp_p_header++;
    }
    uint32_t sum_udp_header = 0;
    uint16_t* temp_u_header = udp_header;
    for (int i = 0; i < 4; i++) {
        sum_udp_header += *temp_u_header++;
    }
    uint32_t sum_payload = 0;
    int i = payload.size()-1;
    while (i >= 1) {
        sum_payload += (payload[i-1] << 8) | payload[i];
        i = i - 2;
    }

    if (i > 0) {
        sum_payload += payload[i] << 8;
    }

    uint32_t sum = sum_pseudo_header + sum_udp_header + sum_payload;

    while (sum >> 16) {
        sum = (sum & 0xFFFF) + (sum >> 16);
    }
    return uint16_t(~sum);
}