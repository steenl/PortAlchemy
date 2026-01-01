/*  Kedar's 2025 code to implement UDP memcached client 
    with some mods by Steen
First compile the program - g++ udp_memcached.cpp
on one terminal run memcached -u nobody -m 64 -U 11211 (assuming you have memcached installed)
on second terminal run ./a.out 127.0.0.1 11211 set foo bar  (set key value) - you should see "STORED" printed
then on the same terminal run /a.out 127.0.0.1 11211 get foo  (get key)  - you will see the value printed
optionally, on a third terminal you can run sudo tcpdump -i lo port 11211 -w memcached_udp.pcap to capture the traffic if you want

*/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

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

int main(int argc, char *argv[]) {
    if (argc < 5) {
        fprintf(stderr,
            "Usage:\n"
            "  %s <server_ip> <port> get <key>\n"
            "  %s <server_ip> <port> set <key> <value>\n",
            argv[0], argv[0]);
        return EXIT_FAILURE;
    }

    const char *server_ip = argv[1];
    int port = atoi(argv[2]);
    const char *op = argv[3];
    const char *key = argv[4];
    const char *value = NULL;

    int is_set = 0;
    if (strcmp(op, "get") == 0) {
        is_set = 0;
        if (argc != 5) {
            fprintf(stderr, "get requires: %s <ip> <port> get <key>\n", argv[0]);
            return EXIT_FAILURE;
        }
    } else if (strcmp(op, "set") == 0) {
        is_set = 1;
        if (argc != 6) {
            fprintf(stderr, "set requires: %s <ip> <port> set <key> <value>\n", argv[0]);
            return EXIT_FAILURE;
        }
        value = argv[5];
    } else {
        fprintf(stderr, "Unknown op '%s', use 'get' or 'set'\n", op);
        return EXIT_FAILURE;
    }

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
    struct memc_udp_header hdr;
    hdr.request_id = htons(0x1234);
    hdr.seq_number = htons(0);
    hdr.total_pkts = htons(1);
    hdr.reserved   = htons(0);

    unsigned char send_buf[MAX_BUF];
    if ((int)(sizeof(hdr) + cmd_len) > (int)sizeof(send_buf)) {
        fprintf(stderr, "Total packet too large\n");
        return EXIT_FAILURE;
    }

    memcpy(send_buf, &hdr, sizeof(hdr));
    memcpy(send_buf + sizeof(hdr), cmd_buf, cmd_len);
    int send_len = sizeof(hdr) + cmd_len;
    printf("Total UDP packet length: %d\n", send_len);

    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) die("socket");

    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    if (inet_pton(AF_INET, server_ip, &server_addr.sin_addr) <= 0) {
        fprintf(stderr, "Invalid server IP address: %s\n", server_ip);
        close(sock);
        return EXIT_FAILURE;
    }
    printf("Sending to %s:%d\n", server_ip, port);
    ssize_t n = sendto(sock, send_buf, send_len, 0,
                       (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (n < 0) die("sendto");

    unsigned char recv_buf[MAX_BUF];
    struct sockaddr_in from_addr;
    socklen_t from_len = sizeof(from_addr);
    n = recvfrom(sock, recv_buf, sizeof(recv_buf) - 1, 0,
                 (struct sockaddr *)&from_addr, &from_len);
    printf("Received %zd bytes\n", n);
    if (n < 0) die("recvfrom");

    /*
    if (n < (ssize_t)sizeof(struct memc_udp_header)) {
        fprintf(stderr, "Received packet too small (%zd bytes)\n", n);
        close(sock);
        return EXIT_FAILURE;
    }
    */

    recv_buf[n] = '\0';

    struct memc_udp_header resp_hdr;
    memcpy(&resp_hdr, recv_buf, sizeof(resp_hdr));

    // The rest is ASCII protocol text
    int payload_len = n - sizeof(struct memc_udp_header);
    char* payload = (char*) (recv_buf + sizeof(struct memc_udp_header));

    if (is_set) {
        if (strncmp(payload, "STORED", 6) == 0) {
            printf ("STORED \n");
        }
    } else {
        if (strncmp(payload, "VALUE", 5) != 0) {
            printf ("NOT FOUND \n");
        } else {
            char key_buf[256];
            int flags = 0;
            int value_len = 0;

            sscanf (payload, "VALUE %255s %u %d\r\n", key_buf, &flags, &value_len);

            char* line_end = strstr (payload, "\r\n");
            char* data_start = line_end + 2;

            fwrite (data_start, 1, value_len, stdout);
            printf ("\n");
        }
    }

    close(sock);
    return 0;
}