#include "c_lib.h"
#include "c_dep.h"

unsigned int increment(c_data* data) {
    // Increment count if it is less than limit, 
    // otherwise set equal to zero.
    if (data->count < data->limit) {
        data->count = add_1(data->count);
    } else {
        data->count = 0;
    }

    // Return the current count.
    return data->count;
}

