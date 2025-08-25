#include <cstdint>
#include <vector>

uint16_t ipv4_checksum(uint16_t* header);

uint16_t udp_checksum_helper(uint16_t* pseudo_header, uint16_t* udp_header, const std::vector<uint8_t>& payload);