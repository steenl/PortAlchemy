#pragma once
#include <vector>
#include <memory>
#include "layers.h"
#include <string.h>

struct Packet {
  std::vector<std::unique_ptr<Layer>> layers;
  template <class L> Packet& push(const L& l) {
    layers.push_back(std::make_unique<L>(l));
    return *this;
  }
  void update();
  void send(const uint8_t* payload);
};

template<class P, class Q>
Packet operator/(const P& p, const Q& q) {
  Packet pac;
  pac.push(p);
  pac.push(q);
  return pac;
}

template<class P>
Packet operator/(Packet&& pac, const P& p) {
  pac.push(p);
  return std::move(pac);
}