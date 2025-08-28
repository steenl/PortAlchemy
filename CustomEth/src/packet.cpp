#include "../include/packet.h"

void Packet::update() {
    for (auto &layer : layers) {
        layer->update_checksum();
    }

    for (int i = 0; i < layers.size(); i++) {
        if (layers[i]->kind() != Kind::IPV4) {
            continue;
        }

        uint32_t len = 0;
        for (int j = i + 1; j < layers.size(); j++) {
            len += layers[j]->get_physical_length();
        }

        auto* ipv4_layer = static_cast<ipv4*>(layers[i].get());
        uint16_t total_len = len + (4 * static_cast<uint16_t> (ipv4_layer->ihl));
        uint16_t calc_checksum[10];

        calc_checksum[0] = (4 << 12) | (ipv4_layer->ihl & 0xF) << 8 | (ipv4_layer->tos & 0xFF);
        calc_checksum[1] = total_len;
        calc_checksum[2] = ipv4_layer->id;
        calc_checksum[3] = ipv4_layer->flag_fragment;
        calc_checksum[4] = (ipv4_layer->ttl << 8) | ipv4_layer->proto;
        calc_checksum[5] = 0x0000;
        calc_checksum[6] = (ipv4_layer->src[0] << 8) | ipv4_layer->src[1];
        calc_checksum[7] = (ipv4_layer->src[2] << 8) | ipv4_layer->src[3];
        calc_checksum[8] = (ipv4_layer->dst[0] << 8) | ipv4_layer->dst[1];
        calc_checksum[9] = (ipv4_layer->dst[2] << 8) | ipv4_layer->dst[3];

        ipv4_layer->checksum = ipv4_checksum(calc_checksum);
    }

    for (int i = 0; i < layers.size(); i++) {
        if (layers[i]->kind() != Kind::IPV4) {
            continue;
        }

        if (layers[i+1]->kind() == Kind::UDP) {
            uint16_t pseudo_header[6];
            uint16_t udp_header[4];
            auto* udp_layer = static_cast<udp*>(layers[i+1].get());
            auto* ipv4_layer = static_cast<ipv4*>(layers[i].get());
            pseudo_header[0] = (ipv4_layer->src[0] << 8) | ipv4_layer->src[1];
            pseudo_header[1] = (ipv4_layer->src[2] << 8) | ipv4_layer->src[3];
            pseudo_header[2] = (ipv4_layer->dst[0] << 8) | ipv4_layer->dst[1];
            pseudo_header[3] = (ipv4_layer->dst[2] << 8) | ipv4_layer->dst[3];
            pseudo_header[4] = (0x00 << 8) | (uint16_t) 17;
            pseudo_header[5] = static_cast<uint16_t>(8 + udp_layer->payload.size());

            udp_header[0] = udp_layer->sport;
            udp_header[1] = udp_layer->dport;
            udp_header[2] = static_cast<uint16_t>(8 + udp_layer->payload.size());
            udp_header[3] = 0x0000;

            udp_layer->checksum = udp_checksum_helper(pseudo_header, udp_header, udp_layer->payload);
        }
        if (layers[i+1]->kind() == Kind::TCP) {
            auto* tcp_layer = static_cast<tcp*>(layers[i+1].get());
            // Similarly do a TCP checksum calculation and update
        }
        if (layers[i+1]->kind() == Kind::ICMP) {
        
        }
    }
}