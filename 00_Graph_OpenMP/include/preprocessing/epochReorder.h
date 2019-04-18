#ifndef EPOCHREORDER_H
#define EPOCHREORDER_H

#include <linux/types.h>
#include "graphCSR.h"
#include "bitmap.h"
#include "arrayQueue.h"

struct EpochReorder
{

	__u32 softThreshold;
	__u32 hardThreshold;
	__u32 numCounters;  //frequncy[numcounters][numverticies]
	__u32 numVertices;
	__u32* frequency;
	struct Bitmap* recencyBits;

};



struct EpochReorder* newEpochReoder( __u32 softThreshold, __u32 hardThreshold, __u32 numCounters, __u32 numVertices);
void freeEpochReorder(struct EpochReorder* epochReorder);

void epochReorderRecordPageRank(struct EpochReorder* epochReorder, struct GraphCSR* graph);
float* epochReorderPageRankPullGraphCSR(struct EpochReorder* epochReorder, double epsilon,  __u32 iterations, struct GraphCSR* graph);

void epochReorderBreadthFirstSearchGraphCSR(struct EpochReorder* epochReorder, __u32 source, struct GraphCSR* graph);
__u32 epochReorderBottomUpStepGraphCSR(struct EpochReorder* epochReorder, struct GraphCSR* graph, struct Bitmap* bitmapCurr, struct Bitmap* bitmapNext);
__u32 epochReorderTopDownStepGraphCSR(struct EpochReorder* epochReorder, struct GraphCSR* graph, struct ArrayQueue* sharedFrontierQueue, struct ArrayQueue** localFrontierQueues);

__u32* epochReorderCreateLabels(struct EpochReorder* epochReorder);

#endif