#include "cpp_dep.hpp"

class Counter {
private:
    unsigned int count;
    Container limit;

public:
    Counter();
    void initialize(unsigned int initialCount, unsigned int maxLimit);
    unsigned int increment();
};
