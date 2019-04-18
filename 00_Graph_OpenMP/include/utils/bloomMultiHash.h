#ifndef BLOOMMULTIHASH_H
#define BLOOMMULTIHASH_H


#include <linux/types.h>
#include "bitmap.h"

struct BloomMultiHash{
   	struct Bitmap* bloom;
   	struct Bitmap* bloomPrime;
   	struct Bitmap* bloomHistory;
   	struct Bitmap* lowestCounter;

   __u32 *counter;
   __u32 *counterHistory;
   __u32 size; // size of bloom filter
   __u32 partition; // partition m/k as a prime number
   __u32 k; // number of hash function


   //pass these variables after find in bloomfilter
   __u32 membership;
   __u32 temperature;


   	//pass these variables after find in bloomfilter
   __u32 threashold;
   __u32 decayPeriod;
   __u32 numIO;
};


struct BloomMultiHash * newBloomMultiHash(__u32 size, __u32 k);
void freeBloomMultiHash( struct BloomMultiHash * bloomMultiHash);
void clearBloomMultiHash( struct BloomMultiHash * bloomMultiHash);
void addToBloomMultiHash(struct BloomMultiHash * bloomMultiHash, __u32 item);
__u32 findInBloomMultiHash(struct BloomMultiHash * bloomMultiHash, __u32 item);




#endif