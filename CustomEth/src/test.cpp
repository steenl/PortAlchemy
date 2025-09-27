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
    */
    FPGAInterface fpg_int("enp36s0", "aa:aa:aa:aa:aa:aa", "aa:aa:ab:aa:aa:aa");

    fpg_int.send_single_wait_ack(100, 3, 0x10);
    
    std::array<uint8_t,28> payload_write_req_1;
    std::array<uint8_t,28> payload_write_req_2;
    std::array<uint8_t,28> payload_write_req_3;

    std::vector<std::array<uint8_t,28>> payload_batch;
    payload_batch.push_back(payload_write_req_1);
    payload_batch.push_back(payload_write_req_2);
    payload_batch.push_back(payload_write_req_3);

    fpg_int.send_batch_wait_ack(payload_batch, 0x2000, 2, 0x10);
}
