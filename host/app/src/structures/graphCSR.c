#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "edgeList.h"
#include "vertex.h"
#include "myMalloc.h"
#include "graphCSR.h"
#include "graphConfig.h"

//edgelist prerpcessing
#include "countsort.h"
#include "radixsort.h"

#include "timer.h"



void graphCSRFree (struct GraphCSR* graphCSR){

	if(graphCSR->vertices)
		freeVertexArray(graphCSR->vertices);
	if(graphCSR->parents)
		free(graphCSR->parents);
	if(graphCSR->sorted_edges_array)
		freeEdgeArray(graphCSR->sorted_edges_array);
	

	#if DIRECTED
		if(graphCSR->inverse_vertices)
			freeVertexArray(graphCSR->inverse_vertices);
		if(graphCSR->inverse_sorted_edges_array)
			freeEdgeArray(graphCSR->inverse_sorted_edges_array);
	#endif


	if(graphCSR)
		free(graphCSR);

}

void graphCSRPrint(struct GraphCSR* graphCSR){

	
	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "GraphCSR Properties");
    printf(" -----------------------------------------------------\n");
    #if WEIGHTED       
                printf("| %-51s | \n", "WEIGHTED");
    #else
                printf("| %-51s | \n", "UN-WEIGHTED");
    #endif

    #if DIRECTED
                printf("| %-51s | \n", "DIRECTED");
    #else
       			printf("| %-51s | \n", "UN-DIRECTED");
    #endif
	printf(" -----------------------------------------------------\n"); 
    printf("| %-51s | \n", "Number of Vertices (V)");
    printf("| %-51u | \n", graphCSR->num_vertices);
    printf(" -----------------------------------------------------\n"); 
    printf("| %-51s | \n", "Number of Edges (E)");
    printf("| %-51u | \n", graphCSR->num_edges);  
    printf(" -----------------------------------------------------\n");
    vertexArrayMaxOutdegree(graphCSR->vertices, graphCSR->num_vertices);
 	vertexArrayMaxInDegree(graphCSR->vertices, graphCSR->num_vertices);
 // 	printVertexArray(graphCSR->vertices, graphCSR->num_vertices);
	// __u32 i;

	// printf("Edge List (E) : %d \n", graphCSR->num_edges);  
 //    for(i = 0; i < graphCSR->num_edges; i++){

 //    	#if WEIGHTED
 //        	printf("%u -> %u w: %d \n", graphCSR->sorted_edges_array[i].src, graphCSR->sorted_edges_array[i].dest, graphCSR->sorted_edges_array[i].weight);   
 //        #else
 //        	printf("%u -> %u \n", graphCSR->sorted_edges_array[i].src, graphCSR->sorted_edges_array[i].dest);   
 //        #endif
 //     }

 //    printf("Inverted Edge List (E) : %d \n", graphCSR->num_edges);  
 //      for(i = 0; i < graphCSR->num_edges; i++){

 //    	#if WEIGHTED
 //        	printf("%u -> %u w: %d \n", graphCSR->inverse_sorted_edges_array[i].src, graphCSR->inverse_sorted_edges_array[i].dest, graphCSR->inverse_sorted_edges_array[i].weight);   
 //        #else
 //        	printf("%u -> %u \n", graphCSR->inverse_sorted_edges_array[i].src, graphCSR->inverse_sorted_edges_array[i].dest);   
 //        #endif
 //     }

   
}


struct GraphCSR* graphCSRNew(__u32 V, __u32 E, __u8 inverse){
	int i;
	// struct GraphCSR* graphCSR = (struct GraphCSR*) aligned_alloc(CACHELINE_BYTES, sizeof(struct GraphCSR));
	#if ALIGNED
		struct GraphCSR* graphCSR = (struct GraphCSR*) my_aligned_alloc( sizeof(struct GraphCSR));
	#else
        struct GraphCSR* graphCSR = (struct GraphCSR*) my_malloc( sizeof(struct GraphCSR));
    #endif

	graphCSR->num_vertices = V;
	graphCSR->num_edges = E;

	graphCSR->vertices = newVertexArray(V);

	#if DIRECTED
		if (inverse)
			graphCSR->inverse_vertices = newVertexArray(V);
	#endif

	#if ALIGNED
		graphCSR->parents  = (int*) my_aligned_alloc( V * sizeof(int));
	#else
        graphCSR->parents  = (int*) my_malloc( V *sizeof(int));
    #endif


     for(i = 0; i < V; i++){
                graphCSR->parents[i] = -1;
     }
	


    return graphCSR;
}

void graphCSRPrintParentsArray(struct GraphCSR* graphCSR){


    __u32 i;

    printf("| %-15s | %-15s | %-15s | %-15s | \n", "Node", "out_degree", "Parent", "Visited");

    for(i =0; i < graphCSR->num_vertices; i++){

        if((graphCSR->vertices[i].out_degree > 0) || (graphCSR->vertices[i].in_degree > 0))
        printf("| %-15u | %-15u | %-15d | %-15u | \n",i,  graphCSR->vertices[i].out_degree, graphCSR->parents[i], graphCSR->vertices[i].visited);
    
    }

}


struct GraphCSR* graphCSRAssignEdgeList (struct GraphCSR* graphCSR, struct EdgeList* edgeList, __u8 inverse){


	#if DIRECTED
	    
	    if(inverse)
	        graphCSR->inverse_sorted_edges_array = edgeList->edges_array;
	    else
	        graphCSR->sorted_edges_array = edgeList->edges_array;

    #else

      	graphCSR->sorted_edges_array = edgeList->edges_array;
    
    #endif

  
	return mapVerticesWithInOutDegree (graphCSR,inverse);   
    
}


struct GraphCSR* graphCSRPreProcessingStep (const char * fnameb){

    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));

    printf("Filename : %s \n",fnameb);
    

    Start(timer);
    struct EdgeList* edgeList = readEdgeListsbin(fnameb,0);
    Stop(timer);
    // edgeListPrint(edgeList);
    graphCSRPrintMessageWithtime("Read Edge List From File (Seconds)",Seconds(timer));


    #if DIRECTED
        struct GraphCSR* graphCSR = graphCSRNew(edgeList->num_vertices, edgeList->num_edges, 1);
    #else
        struct GraphCSR* graphCSR = graphCSRNew(edgeList->num_vertices, edgeList->num_edges, 0);
    #endif

   
    Start(timer);
    edgeList = radixSortEdgesBySourceOptimized(edgeList);
    Stop(timer);
    graphCSRPrintMessageWithtime("Radix Sort Edges By Source (Seconds)",Seconds(timer));

    Start(timer);
    graphCSR = graphCSRAssignEdgeList (graphCSR,edgeList, 0);
    Stop(timer);
    graphCSRPrintMessageWithtime("Process In/Out degrees of Nodes (Seconds)",Seconds(timer));

     #if DIRECTED

        Start(timer);
        struct EdgeList* inverse_edgeList = readEdgeListsbin(fnameb,1);
        Stop(timer);
        // edgeListPrint(inverse_edgeList);
        graphCSRPrintMessageWithtime("Read Inverse Edge List From File (Seconds)",Seconds(timer));


        Start(timer);
        inverse_edgeList = radixSortEdgesBySourceOptimized(inverse_edgeList);
        Stop(timer);
        graphCSRPrintMessageWithtime("Radix Sort Inverse Edges By Source (Seconds)",Seconds(timer));

        Start(timer);
        graphCSR = graphCSRAssignEdgeList (graphCSR,inverse_edgeList, 1);
        Stop(timer);
        graphCSRPrintMessageWithtime("Process In/Out degrees of Inverse Nodes (Seconds)",Seconds(timer));

    #endif
    
   
    graphCSRPrint(graphCSR);

    free(timer);
    return graphCSR;

    
}


void graphCSRPrintMessageWithtime(const char * msg, double time){

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", msg);
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", time);
    printf(" -----------------------------------------------------\n");

}