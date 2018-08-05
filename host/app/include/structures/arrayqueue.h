#ifndef ARRAYQUEUE_H
#define ARRAYQUEUE_H

#include <linux/types.h>
#include "bitmap.h"

struct __attribute__((__packed__)) ArrayQueue
{
	__u32 head;
	__u32 tail;
	__u32 size;
	__u32* queue;
	struct Bitmap* bitmap;

};


struct ArrayQueue *newArrayQueue (__u32 size);
void 	freeArrayQueue	(struct ArrayQueue *q);
void	 enArrayQueue 	(struct ArrayQueue *q, __u32 k);
__u32 	deArrayQueue	(struct ArrayQueue *q);
__u32 	frontArrayQueue (struct ArrayQueue *q);
__u8  isEmptyArrayQueue (struct ArrayQueue *q);
__u8  isEnArrayQueued 	(struct ArrayQueue *q, __u32 k);


#endif

