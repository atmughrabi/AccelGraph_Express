#ifndef ADJLINKEDLIST_H
#define ADJLINKEDLIST_H

#include <linux/types.h>

#include "edgeList.h"
#include "graphConfig.h"
#include "graphCSR.h"

// A structure to represent an adjacency list node
struct  AdjLinkedListNode {

	__u32 dest;
	// __u32 src;

	#if WEIGHTED
	__u32 weight;
	#endif

	struct AdjLinkedListNode* next;

}__attribute__((packed));

// A structure to represent an adjacency list
struct  AdjLinkedList {

	__u8 visited;
	__u32 out_degree;
	struct AdjLinkedListNode* outNodes;

	#if DIRECTED
		__u32 in_degree;
		struct AdjLinkedListNode* inNodes;
	#endif

}__attribute__((packed));

// // A structure to represent a GraphAdjLinkedList. A GraphAdjLinkedList
// // is an array of adjacency lists.
// // Size of array will be V (number of vertices 
// // in GraphAdjLinkedList)
// struct  GraphAdjLinkedList
// {
// 	__u32 num_vertices;
// 	__u32 num_edges;
// 	struct AdjLinkedList* vertices;
	
// };



// A utility function to create a new adjacency list node
struct AdjLinkedListNode* newAdjLinkedListOutNode(struct Edge * edge);
struct AdjLinkedListNode* newAdjLinkedListInNode(struct Edge * edge);

#endif