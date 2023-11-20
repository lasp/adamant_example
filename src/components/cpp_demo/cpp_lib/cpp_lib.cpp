#include "cpp_lib.hpp"

Counter::Counter () {}

void Counter::initialize(unsigned int initialCount, unsigned int maxLimit) {
    count = initialCount;
    limit.set(maxLimit);
}

unsigned int Counter::increment() {
    if (count < limit.get()) {
        count++;
    } else {
        count = 0;
    }
    return count;
}
