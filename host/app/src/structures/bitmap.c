#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <linux/types.h>

#include "myMalloc.h"
#include "bitmap.h"

struct Bitmap* newBitmap( __u32 size){


	#if ALIGNED
		struct Bitmap* bitmap = (struct Bitmap*) my_aligned_alloc( sizeof(struct Bitmap));
	#else
        struct Bitmap* bitmap = (struct Bitmap*) my_malloc( sizeof(struct Bitmap));
	#endif


    #if ALIGNED
		bitmap->bitarray = (__u8*) my_aligned_alloc(sizeof(__u8)*((size+7)/8));
	#else
        bitmap->bitarray = (__u8*) my_malloc(sizeof(__u8)*((size+7)/8));
	#endif

    memset(bitmap->bitarray, 0, (sizeof(__u8)*((size+7)/8)));
	bitmap->size =  size;
	bitmap->numSetBits =  0;

	return bitmap;
}


void freeBitmap( struct Bitmap* bitmap){

        free(bitmap->bitarray);
        free(bitmap);
	
}

void reset(struct Bitmap* bitmap){

	 memset(bitmap->bitarray, 0, (sizeof(__u8)*((bitmap->size+7)/8)));
	 bitmap->numSetBits =  0;

}

void setBit(struct Bitmap* bitmap, __u32 pos){

	ba_set(bitmap->bitarray, pos);
	// bitmap->numSetBits++;

}

void setBitRange(struct Bitmap* bitmap, __u32 start,__u32 end){

 __u32 pos;

 for (pos = start; pos < end; ++pos)
 {
 	ba_set(bitmap->bitarray, pos);
 	// bitmap->numSetBits++;
 }

}

void setBitAtomic(struct Bitmap* bitmap, __u32 pos){

	// ba_set(bitmap->bitarray, pos);
	 __u8 *bitarray = bitmap->bitarray;
	 __u8 old_val, new_val;
    do {
      old_val = bitarray[(pos) >> 3];
      new_val = old_val | (__u8)(1 << ((pos) & 7));
    } while (!__sync_bool_compare_and_swap(&bitarray[(pos) >> 3], old_val, new_val));

	

}

__u8 getBit(struct Bitmap* bitmap, __u32 pos){

	__u8 bit = ba_get(bitmap->bitarray, pos);
	return bit;

}

void clearBit(struct Bitmap* bitmap, __u32 pos){

	ba_clear(bitmap->bitarray, pos);
	// bitmap->numSetBits--;

}

struct Bitmap*  orBitmap(struct Bitmap* bitmap1, struct Bitmap* bitmap2){


	__u32 i;
	__u8 *byte1 = bitmap1->bitarray;
	__u8 *byte2 = bitmap2->bitarray;
	bitmap1->numSetBits = 0;

	for(i= 0 ; i < ((bitmap1->size+7)/8); i++){
		byte1[i] = byte1[i] | byte2[i]; 

	}

	bitmap1->numSetBits = getNumOfSetBits(bitmap1);

	return bitmap1;

}


struct Bitmap*  andBitmap(struct Bitmap* bitmap1, struct Bitmap* bitmap2){


	__u32 i;
	__u8 *byte1 = bitmap1->bitarray;
	__u8 *byte2 = bitmap2->bitarray;
	bitmap1->numSetBits = 0;

	for(i= 0 ; i < ((bitmap1->size+7)/8); i++){
		byte1[i] = byte1[i] & byte2[i]; 

	}

	bitmap1->numSetBits = getNumOfSetBits(bitmap1);

	return bitmap1;

}


void swapBitmaps (struct Bitmap** bitmap1, struct Bitmap** bitmap2){

	
	struct Bitmap* temp_bitmap = *bitmap1;
	*bitmap1 = *bitmap2;
	*bitmap2 = temp_bitmap;

}



__u32 getNumOfSetBits (struct Bitmap* bitmap){

	__u32 i;
	__u32 numSetBits = 0;
	__u8 bit = 0;

	for(i= 0 ; i < (bitmap->size); i++){
		bit = ba_get(bitmap->bitarray, i);
		numSetBits += bit;
	}

	return numSetBits;
}

void printSetBits (struct Bitmap* bitmap){

	__u32 i;
	__u8 bit = 0;

	for(i= 0 ; i < (bitmap->size); i++){
		bit = ba_get(bitmap->bitarray, i);
		if(bit){
			printf("**%u \n", i);
		}
		bit = 0;
	}

}