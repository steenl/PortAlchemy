#include <sys/socket.h>
#include <linux/if_packet.h>
#include <linux/if_ether.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <netinet/in.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>

class RawEth {
public:
    int fd = -1;
    explicit RawEth (const std::string& iface) {
        fd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
        struct ifreq iface_id;
        struct sockaddr_ll sock_addr;
        uint32_t if_index = if_nametoindex(iface.c_str());
        memset(&sock_addr, 0, sizeof(sock_addr));
        sock_addr.sll_family   = AF_PACKET;
        sock_addr.sll_ifindex  = static_cast<int>(if_index);
        sock_addr.sll_protocol = htons(ETH_P_ALL);
        std::cout << "Initializing the socket \n";

        if (bind(fd, reinterpret_cast<sockaddr*>(&sock_addr), sizeof(sock_addr)) < 0) {
            close(fd);
            throw std::runtime_error(std::string("bind(AF_PACKET): "));
        }
        int flags = fcntl(fd, F_GETFL, 0);
        fcntl(fd, F_SETFL, flags | O_NONBLOCK);
    }

    bool send_on_wire(const uint8_t* p, int n) {
        ssize_t r = send(fd, p, n, 0);
        return (r == static_cast<ssize_t>(n));
    }

    bool recv_on_wire(uint8_t* buf, uint16_t cap) {
        pollfd pfd;
        pfd.fd = fd;
        pfd.events = POLLIN;

        int ret = poll(&pfd, 1, 10);

        if (ret < 0 || ret == 0) {
            return false;
        }

        if (ret > 0) {
            ssize_t n = recv(fd, buf, cap, 0);
            if (n >= 0) return true;
            return false;
        }
        return false;
    }
};
