#include "cpp_dep.hpp"

Container::Container() {}

unsigned int Container::get() {
    return value;
}

void Container::set(unsigned int newValue) {
    value = newValue;
}
