/*  Kedar's 2025 code to implement UDP memcached client 
    with some mods by Steen
    Modified to use AF_PACKET (raw sockets) instead of AF_INET
    
First compile the program - g++ udp_memcached.cpp
on one terminal run memcached -u nobody -m 64 -U 11211 (assuming you have memcached installed)
on second terminal run sudo ./a.out eth0 192.168.1.100 127.0.0.1 11211 set foo bar  (needs sudo for raw sockets)
then on the same terminal run sudo ./a.out eth0 192.168.1.100 127.0.0.1 11211 get foo
optionally, on a third terminal you can run sudo tcpdump -i lo port 11211 -w memcached_udp.pcap to capture the traffic

Note: Using AF_PACKET requires root/sudo privileges
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <netinet/ether.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <linux/if_packet.h>
#include <net/ethernet.h>

struct memc_udp_header {
    uint16_t request_id;
    uint16_t seq_number;
    uint16_t total_pkts;
    uint16_t reserved;
};

#define MAX_BUF 2048

static void die(const char *msg) {
    perror(msg);
    exit(EXIT_FAILURE);
}

// Calculate IP checksum
uint16_t ip_checksum(void *vdata, size_t length) {
    uint8_t *data = (uint8_t *)vdata;
    uint32_t acc = 0xffff;
    
    for (size_t i = 0; i + 1 < length; i += 2) {
        uint16_t word;
        memcpy(&word, data + i, 2);
        acc += ntohs(word);
        if (acc > 0xffff) {
            acc -= 0xffff;
        }
    }
    
    if (length & 1) {
        uint16_t word = 0;
        memcpy(&word, data + length - 1, 1);
        acc += ntohs(word);
        if (acc > 0xffff) {
            acc -= 0xffff;
        }
    }
    
    return htons(~acc);
}

// Get interface index and MAC address
int get_interface_info(const char *ifname, int *ifindex, uint8_t *mac_addr) {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) return -1;
    
    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, ifname, IFNAMSIZ - 1);
    
    // Get interface index
    if (ioctl(sock, SIOCGIFINDEX, &ifr) < 0) {
        close(sock);
        return -1;
    }
    *ifindex = ifr.ifr_ifindex;
    
    // Get MAC address
    if (ioctl(sock, SIOCGIFHWADDR, &ifr) < 0) {
        close(sock);
        return -1;
    }
    memcpy(mac_addr, ifr.ifr_hwaddr.sa_data, 6);
    
    close(sock);
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc < 7) {
        fprintf(stderr,
            "Usage:\n"
            "  %s <interface> <src_ip> <dst_ip> <port> get <key>\n"
            "  %s <interface> <src_ip> <dst_ip> <port> set <key> <value>\n"
            "Example:\n"
            "  sudo %s eth0 192.168.1.100 127.0.0.1 11211 get foo\n",
            argv[0], argv[0], argv[0]);
        return EXIT_FAILURE;
    }

    const char *ifname = argv[1];
    const char *src_ip_str = argv[2];
    const char *dst_ip_str = argv[3];
    int port = atoi(argv[4]);
    const char *op = argv[5];
    const char *key = argv[6];
    const char *value = NULL;

    int is_set = 0;
    if (strcmp(op, "get") == 0) {
        is_set = 0;
        if (argc != 7) {
            fprintf(stderr, "get requires: %s <if> <src_ip> <dst_ip> <port> get <key>\n", argv[0]);
            return EXIT_FAILURE;
        }
    } else if (strcmp(op, "set") == 0) {
        is_set = 1;
        if (argc != 8) {
            fprintf(stderr, "set requires: %s <if> <src_ip> <dst_ip> <port> set <key> <value>\n", argv[0]);
            return EXIT_FAILURE;
        }
        value = argv[7];
    } else {
        fprintf(stderr, "Unknown op '%s', use 'get' or 'set'\n", op);
        return EXIT_FAILURE;
    }

    // Get interface info
    int ifindex;
    uint8_t src_mac[6];
    if (get_interface_info(ifname, &ifindex, src_mac) < 0) {
        fprintf(stderr, "Failed to get interface info for %s\n", ifname);
        return EXIT_FAILURE;
    }
    
    printf("Interface: %s (index %d)\n", ifname, ifindex);
    printf("Source MAC: %02x:%02x:%02x:%02x:%02x:%02x\n",
           src_mac[0], src_mac[1], src_mac[2], src_mac[3], src_mac[4], src_mac[5]);

    // Parse IP addresses
    struct in_addr src_ip, dst_ip;
    if (inet_pton(AF_INET, src_ip_str, &src_ip) <= 0) {
        fprintf(stderr, "Invalid source IP address: %s\n", src_ip_str);
        return EXIT_FAILURE;
    }
    if (inet_pton(AF_INET, dst_ip_str, &dst_ip) <= 0) {
        fprintf(stderr, "Invalid destination IP address: %s\n", dst_ip_str);
        return EXIT_FAILURE;
    }

    // Build memcached command
    char cmd_buf[MAX_BUF];
    int cmd_len = 0;

    if (is_set) {
        size_t vlen = strlen(value);
        cmd_len = snprintf(cmd_buf, sizeof(cmd_buf),
                           "set %s 0 0 %zu\r\n%s\r\n", key, vlen, value);
        printf("Set command length: %d\n", cmd_len);
    } else {
        cmd_len = snprintf(cmd_buf, sizeof(cmd_buf),
                           "get %s\r\n", key);
    }

    if (cmd_len <= 0 || cmd_len >= (int)sizeof(cmd_buf)) {
        fprintf(stderr, "Command too long or snprintf error\n");
        return EXIT_FAILURE;
    }

    // Build memcached UDP header
    struct memc_udp_header memc_hdr;
    memc_hdr.request_id = htons(0x1234);
    memc_hdr.seq_number = htons(0);
    memc_hdr.total_pkts = htons(1);
    memc_hdr.reserved   = htons(0);

    // Calculate total payload length
    int udp_payload_len = sizeof(memc_hdr) + cmd_len;
    
    // Build the complete packet
    uint8_t packet[MAX_BUF];
    int packet_len = 0;
    
    // Ethernet header
    struct ether_header *eth = (struct ether_header *)packet;
    uint8_t dst_mac[6] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff}; // Broadcast for simplicity
    memcpy(eth->ether_dhost, dst_mac, 6);
    memcpy(eth->ether_shost, src_mac, 6);
    eth->ether_type = htons(ETH_P_IP);
    packet_len += sizeof(struct ether_header);
    
    // IP header
    struct iphdr *iph = (struct iphdr *)(packet + packet_len);
    iph->ihl = 5;
    iph->version = 4;
    iph->tos = 0;
    iph->tot_len = htons(sizeof(struct iphdr) + sizeof(struct udphdr) + udp_payload_len);
    iph->id = htons(54321);
    iph->frag_off = 0;
    iph->ttl = 64;
    iph->protocol = IPPROTO_UDP;
    iph->check = 0;
    iph->saddr = src_ip.s_addr;
    iph->daddr = dst_ip.s_addr;
    iph->check = ip_checksum(iph, sizeof(struct iphdr));
    packet_len += sizeof(struct iphdr);
    
    // UDP header
    struct udphdr *udph = (struct udphdr *)(packet + packet_len);
    udph->source = htons(12345); // Random source port
    udph->dest = htons(port);
    udph->len = htons(sizeof(struct udphdr) + udp_payload_len);
    udph->check = 0; // Optional for UDP
    packet_len += sizeof(struct udphdr);
    
    // Memcached UDP header + command
    memcpy(packet + packet_len, &memc_hdr, sizeof(memc_hdr));
    packet_len += sizeof(memc_hdr);
    memcpy(packet + packet_len, cmd_buf, cmd_len);
    packet_len += cmd_len;
    
    printf("Total packet length: %d bytes\n", packet_len);

    // Create raw socket
    int sock = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if (sock < 0) {
        die("socket (need root/sudo)");
    }

    // Bind to interface
    struct sockaddr_ll socket_address;
    memset(&socket_address, 0, sizeof(socket_address));
    socket_address.sll_family = AF_PACKET;
    socket_address.sll_protocol = htons(ETH_P_IP);
    socket_address.sll_ifindex = ifindex;
    socket_address.sll_hatype = ARPHRD_ETHER;
    socket_address.sll_pkttype = PACKET_OTHERHOST;
    socket_address.sll_halen = 6;
    memcpy(socket_address.sll_addr, dst_mac, 6);

    printf("Sending packet...\n");
    ssize_t n = sendto(sock, packet, packet_len, 0,
                       (struct sockaddr *)&socket_address, sizeof(socket_address));
    if (n < 0) die("sendto");
    printf("Sent %zd bytes\n", n);

    // Receive response
    printf("Waiting for response...\n");
    uint8_t recv_buf[MAX_BUF];
    socklen_t addr_len = sizeof(socket_address);
    
    // Set timeout to avoid waiting forever
    struct timeval tv;
    tv.tv_sec = 5;
    tv.tv_usec = 0;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    
    n = recvfrom(sock, recv_buf, sizeof(recv_buf), 0,
                 (struct sockaddr *)&socket_address, &addr_len);
    
    if (n < 0) {
        perror("recvfrom (timeout or error)");
        close(sock);
        return EXIT_FAILURE;
    }
    
    printf("Received %zd bytes\n", n);
    
    // Parse response - skip Ethernet + IP + UDP headers
    int header_offset = sizeof(struct ether_header) + sizeof(struct iphdr) + sizeof(struct udphdr);
    
    if (n < header_offset + (int)sizeof(struct memc_udp_header)) {
        fprintf(stderr, "Received packet too small\n");
        close(sock);
        return EXIT_FAILURE;
    }
    
    // Extract memcached response
    struct memc_udp_header resp_hdr;
    memcpy(&resp_hdr, recv_buf + header_offset, sizeof(resp_hdr));
    
    int payload_len = n - header_offset - sizeof(struct memc_udp_header);
    char *payload = (char *)(recv_buf + header_offset + sizeof(struct memc_udp_header));
    
    if (is_set) {
        if (strncmp(payload, "STORED", 6) == 0) {
            printf("STORED\n");
        } else {
            printf("Response: %.*s\n", payload_len, payload);
        }
    } else {
        if (strncmp(payload, "VALUE", 5) != 0) {
            printf("NOT FOUND\n");
        } else {
            char key_buf[256];
            int flags = 0;
            int value_len = 0;
            
            sscanf(payload, "VALUE %255s %u %d\r\n", key_buf, &flags, &value_len);
            
            char *line_end = strstr(payload, "\r\n");
            char *data_start = line_end + 2;
            
            printf("Value: ");
            fwrite(data_start, 1, value_len, stdout);
            printf("\n");
        }
    }

    close(sock);
    return 0;
}