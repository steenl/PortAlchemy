#include "../include/fpga_interface.h"

int main() {
    /*
    Here we create a batch of packets to be sent out 
    And wait for ack 
    This is for requesting to write some payload into memory 
    */

    /*
    Create all the payloads to be sent here 
    Add them to a vector 
    Initiate it to be sent through the interface class 
    socket interface, Packet creation, src/dst mac addresses - members of the fpga interface

    // we are limited to 226 bytes on the payload 
    // 14 + 16 bytes for the ether + ualink headers 
    */
    FPGAInterface fpg_int("enp36s0", "aa:aa:aa:aa:aa:aa", "aa:aa:ab:aa:aa:aa");

    std::array<uint8_t,226> payload_write_req_1 = {0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99};
    std::array<uint8_t,226> payload_write_req_2 = {0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19};
    std::array<uint8_t,226> payload_write_req_3 = {0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29};

    std::vector<std::array<uint8_t,226>> payload_batch;
    payload_batch.push_back(payload_write_req_1);
    payload_batch.push_back(payload_write_req_2);
    payload_batch.push_back(payload_write_req_3);

    fpg_int.send_batch_wait_ack(payload_batch, 0x2000, 2, 0x10);
}
