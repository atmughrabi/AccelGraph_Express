// By mohannad Ibrahim

#include <stdio.h>
#include <stdlib.h>

#include <linux/types.h>
#include "quantization.h"

/* function to find min and max values simultanuously amongst the ranks (array)
 it has an O(N) complexity*/
struct MinMax getMinMax(float ranks[], int size)
{
    struct MinMax x;
    
    if (size == 1)
    {
        x.max = ranks[0];
        x.min = ranks[0];
        return x;
    }
    
    if (ranks[0] > ranks[1])
    {
        x.max = ranks[0];
        x.min = ranks[1];
    }
    else
    {
        x.max = ranks[1];
        x.min = ranks[0];
    }

    for (int i = 2; i < size; i++)
    {
        if (ranks[i] > x.max)
            x.max = ranks[i];
        else if (ranks[i] < x.min)
            x.min = ranks[i];
    }
    return x;
}


/* In a form of a function: It receives an array of values (ranks) and extract
the appropraite quantization parameters (scale and zero-offset)
inputs:    ranks array, size of array */
/*
 struct quant_params get_quant_params(float ranks[], int size)
{
    struct quant_params q;
    struct MinMax x;
    
    // 1. Find min and max values
    x = getMinMax(ranks, size);
    
    // 2. Find the scale value
    if (x.min != x.max)
        q.scale = ABS((x.max - x.min))/RANGE_MAX;
    else
        q.scale = 1.0;
        
    // 3. Find the zero-offset value
    q.zero = CLAMP(RANGE_MAX - ROUND(x.max/q.scale), RANGE_MIN, RANGE_MAX);
        
    return q;
}
*/