/* Raw Ethernet packet sender by AI and Steen*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <linux/if_packet.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/udp.h>
#include <net/if.h>

#define IFACE      "enp3s0f1"
#define DST_MAC    {0xaa,0xbb,0xcc,0xdd,0xee,0xff}
#define SRC_MAC    {0x02,0x00,0x00,0x00,0x00,0x01}
#define SRC_IP     "192.168.2.1"
#define DST_IP     "192.168.2.2"
#define SRC_PORT   1234
#define DST_PORT   5678

uint16_t checksum(void *data, int len)
{
    uint32_t sum = 0;
    uint16_t *ptr = data;

    while (len > 1) {
        sum += *ptr++;
        len -= 2;
    }
    if (len)
        sum += *(uint8_t *)ptr;

    while (sum >> 16)
        sum = (sum & 0xFFFF) + (sum >> 16);

    return ~sum;
}

int main(void)
{
    int sockfd;
    uint8_t buffer[1500];

    struct ethhdr *eth = (struct ethhdr *)buffer;
    struct iphdr  *ip  = (struct iphdr *)(buffer + sizeof(struct ethhdr));
    struct udphdr *udp = (struct udphdr *)(buffer + sizeof(struct ethhdr) + sizeof(struct iphdr));
    uint8_t *payload   = buffer + sizeof(struct ethhdr) + sizeof(struct iphdr) + sizeof(struct udphdr);

    const char *msg = "Hello from raw Ethernet!";
    int payload_len = strlen(msg);

    /* Ethernet header */
    uint8_t dst_mac[] = DST_MAC;
    uint8_t src_mac[] = SRC_MAC;
    memcpy(eth->h_dest, dst_mac, ETH_ALEN);
    memcpy(eth->h_source, src_mac, ETH_ALEN);
    eth->h_proto = htons(ETH_P_IP);

    /* IP header */
    ip->ihl      = 5;
    ip->version  = 4;
    ip->tos      = 0;
    ip->tot_len  = htons(sizeof(struct iphdr) + sizeof(struct udphdr) + payload_len);
    ip->id       = htons(0xdead);
    ip->frag_off = 0;
    ip->ttl      = 64;
    ip->protocol = IPPROTO_UDP;
    ip->check    = 0;
    ip->saddr    = inet_addr(SRC_IP);
    ip->daddr    = inet_addr(DST_IP);
    ip->check    = checksum(ip, sizeof(struct iphdr));

    /* UDP header */
    udp->source  = htons(SRC_PORT);
    udp->dest    = htons(DST_PORT);
    udp->len     = htons(sizeof(struct udphdr) + payload_len);
    udp->check   = 0;  // optional for IPv4

    memcpy(payload, msg, payload_len);

    /* Create raw socket */
    sockfd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if (sockfd < 0) {
        perror("socket");
        return 1;
    }

    struct sockaddr_ll addr = {0};
    addr.sll_family   = AF_PACKET;
    addr.sll_ifindex  = if_nametoindex(IFACE);
    addr.sll_halen    = ETH_ALEN;
    memcpy(addr.sll_addr, dst_mac, ETH_ALEN);

    int frame_len = sizeof(struct ethhdr) + sizeof(struct iphdr) +
                    sizeof(struct udphdr) + payload_len;

    if (sendto(sockfd, buffer, frame_len, 0,
               (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("sendto");
        close(sockfd);
        return 1;
    }

    printf("Packet sent successfully\n");
    close(sockfd);
    return 0;
}