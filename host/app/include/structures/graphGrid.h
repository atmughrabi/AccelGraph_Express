#ifndef GRAPHGRID_H
#define GRAPHGRID_H

#include <linux/types.h>

#include "edgeList.h"
#include "grid.h"
#include "graphConfig.h"


// A structure to represent an adjacency list
struct  GraphGrid {

	__u32 num_edges;
	__u32 num_vertices;
	__u32 iteration;
	__u32 processed_nodes;
	

	
	int* parents;       // specify parent for each vertex
	struct Grid* grid;
	

};

void  graphGridReset(struct GraphGrid *graphGrid);
void  graphGridPrint(struct GraphGrid *graphGrid);
struct GraphGrid * graphGridNew(struct EdgeList* edgeList);
void   graphGridFree(struct GraphGrid *graphGrid);
void   graphGridPrintMessageWithtime(const char * msg, double time);
struct GraphGrid* graphGridPreProcessingStep (const char * fnameb, __u32 sort,  __u32 lmode);

#endif