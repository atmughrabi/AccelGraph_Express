
#include <linux/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <omp.h>

#include "arrayQueue.h"
#include "graphCSR.h"
#include "myMalloc.h"
#include "epochReorder.h"
#include "bitmap.h"
#include "timer.h"

#include "pageRank.h"
#include "BFS.h"




struct EpochReorder* newEpochReoder( __u32 softThreshold, __u32 hardThreshold, __u32 numCounters, __u32 numVertices){

        // struct EdgeList* newEdgeList = (struct EdgeList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct EdgeList));
		#if ALIGNED
                struct EpochReorder* epochReorder = (struct EpochReorder*) my_aligned_malloc(sizeof(struct EpochReorder));  
        #else
                struct EpochReorder* epochReorder = (struct EpochReorder*) my_malloc(sizeof(struct EpochReorder));
        #endif

        epochReorder->rrIndex = 0;
        epochReorder->softcounter = 0;
        epochReorder->hardcounter = 0;
		epochReorder->softThreshold = softThreshold;
        epochReorder->hardThreshold = hardThreshold;
        epochReorder->numCounters = numCounters;
        epochReorder->numVertices = numVertices;

        epochReorder->recencyBits = newBitmap(numVertices);

        #if ALIGNED
                epochReorder->frequency = (__u32*) my_aligned_malloc(sizeof(__u32)*numCounters*numVertices);
        #else
                epochReorder->frequency = (__u32*) my_malloc(sizeof(__u32)*numCounters*numVertices);
        #endif
        
        return epochReorder;

}


void epochReorderRecordPageRank(struct EpochReorder* epochReorder, struct GraphCSR* graph){

	double epsilon = 0.00001;
	__u32 iterations = 10;

	epochReorderPageRankPullGraphCSR(epochReorder, epsilon, iterations, graph);

}


float* epochReorderPageRankPullGraphCSR(struct EpochReorder* epochReorder, double epsilon,  __u32 iterations, struct GraphCSR* graph){

  __u32 iter;
  __u32 j;
  __u32 v;
  __u32 u;
  __u32 degree;
  __u32 edge_idx;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Vertex* vertices = NULL;
  __u32* sorted_edges_array = NULL;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

  #if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edge_array;
  #else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edge_array;
  #endif

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
     pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
      else
        riDividedOnDiClause[v] = 0.0f;
    }
 
    #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,edge_idx) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      float nodeIncomingPR = 0.0f;
      degree = vertices[v].out_degree;
      edge_idx = vertices[v].edges_idx;
      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = sorted_edges_array[j];
        nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
      }
      pageRanksNext[v] = nodeIncomingPR;
    }

    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // printf(" -----------------------------------------------------\n");
  // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
  // printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanksNext);
  free(riDividedOnDiClause);
	
   return pageRanks;
}


void epochReorderRecordBFS(struct EpochReorder* epochReorder, struct GraphCSR* graph){

	__u32 source = 0;

	epochReorderBreadthFirstSearchGraphCSR( epochReorder, source, graph);



}



// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************



// breadth-first-search(graph, source)
// 	sharedFrontierQueue ← {source}
// 	next ← {}
// 	parents ← [-1,-1,. . . -1]
// 		while sharedFrontierQueue 6= {} do
// 			top-down-step(graph, sharedFrontierQueue, next, parents)
// 			sharedFrontierQueue ← next
// 			next ← {}
// 		end while
// 	return parents

void epochReorderBreadthFirstSearchGraphCSR(struct EpochReorder* epochReorder, __u32 source, struct GraphCSR* graph){

	
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
	double inner_time = 0;
	struct ArrayQueue* sharedFrontierQueue = newArrayQueue(graph->num_vertices);
	struct Bitmap* bitmapCurr = newBitmap(graph->num_vertices);
    struct Bitmap* bitmapNext = newBitmap(graph->num_vertices);

	__u32 P = numThreads;
	__u32 mu = graph->num_edges; // number of edges to check from sharedFrontierQueue
	__u32 mf = graph->vertices[source].out_degree; // number of edges from unexplored verticies
	__u32 nf = 0; // number of vertices in sharedFrontierQueue
	__u32 nf_prev = 0; // number of vertices in sharedFrontierQueue
	__u32 n = graph->num_vertices; // number of nodes
	__u32 alpha = 15;
	__u32 beta = 18;

	#if ALIGNED
		struct ArrayQueue** localFrontierQueues = (struct ArrayQueue**) my_aligned_malloc( P * sizeof(struct ArrayQueue*));
	#else
        struct ArrayQueue** localFrontierQueues = (struct ArrayQueue**) my_malloc( P * sizeof(struct ArrayQueue*));
    #endif

   __u32 i;
   for(i=0 ; i < P ; i++){
		localFrontierQueues[i] = newArrayQueue(graph->num_vertices);
		
   }

  	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Breadth First Search (SOURCE NODE)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices){
		printf(" -----------------------------------------------------\n");
    	printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	printf(" -----------------------------------------------------\n");
		return;
	}

	graphCSRReset(graph);

  	Start(timer_inner);
	enArrayQueue(sharedFrontierQueue, source);
    // setBit(sharedFrontierQueue->q_bitmap,source);
	graph->parents[source] = source;  
	Stop(timer_inner);
	inner_time +=  Seconds(timer_inner);
	// graph->vertices[source].visited = 1;
	
    
	printf("| TD %-12u | %-15u | %-15f | \n",graph->iteration++, ++graph->processed_nodes , Seconds(timer_inner));

    Start(timer);
	while(!isEmptyArrayQueue(sharedFrontierQueue)){ // start while 

		if(mf > (mu/alpha)){

			Start(timer_inner);
			arrayQueueToBitmap(sharedFrontierQueue,bitmapCurr);
			nf = sizeArrayQueue(sharedFrontierQueue);
			Stop(timer_inner);
			printf("| E  %-12s | %-15s | %-15f | \n"," ", " " , Seconds(timer_inner));

			do{
				Start(timer_inner);
				nf_prev = nf;
				nf = epochReorderBottomUpStepGraphCSR(epochReorder, graph,bitmapCurr,bitmapNext);
				swapBitmaps(&bitmapCurr, &bitmapNext);
				clearBitmap(bitmapNext);
				Stop(timer_inner);

				//stats collection
				inner_time +=  Seconds(timer_inner);
				graph->processed_nodes += nf;
				printf("| BU %-12u | %-15u | %-15f | \n",graph->iteration++, nf , Seconds(timer_inner));
			
			}while(( nf > nf_prev) || // growing;
				   ( nf > (n/beta)));

			Start(timer_inner);
			bitmapToArrayQueue( bitmapCurr,sharedFrontierQueue,localFrontierQueues);
			Stop(timer_inner);
			printf("| C  %-12s | %-15s | %-15f | \n"," ", " " , Seconds(timer_inner));

			mf = 1;

		}
		else{
			
			Start(timer_inner);
			mu -= mf;		
			mf = epochReorderTopDownStepGraphCSR(epochReorder, graph, sharedFrontierQueue,localFrontierQueues);
			slideWindowArrayQueue(sharedFrontierQueue);
			Stop(timer_inner);

			//stats collection
			inner_time +=  Seconds(timer_inner);
			graph->processed_nodes += sharedFrontierQueue->tail - sharedFrontierQueue->head;;
			printf("| TD %-12u | %-15u | %-15f | \n",graph->iteration++, sharedFrontierQueue->tail - sharedFrontierQueue->head, Seconds(timer_inner));

		}



	} // end while
	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","No OverHead", graph->processed_nodes, inner_time);
	printf(" -----------------------------------------------------\n");
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","total", graph->processed_nodes, Seconds(timer));
	printf(" -----------------------------------------------------\n");

	graphCSRReset(graph);
	for(i=0 ; i < P ; i++){
		freeArrayQueue(localFrontierQueues[i]);		
   	}
   	free(localFrontierQueues);
	freeArrayQueue(sharedFrontierQueue);
	freeBitmap(bitmapNext);
	freeBitmap(bitmapCurr);
	free(timer);
	free(timer_inner);
}


// top-down-step(graph, sharedFrontierQueue, next, parents)
// 	for v ∈ sharedFrontierQueue do
// 		for u ∈ neighbors[v] do
// 			if parents[u] = -1 then
// 				parents[u] ← v
// 				next ← next ∪ {u}
// 			end if
// 		end for
// 	end for

__u32 epochReorderTopDownStepGraphCSR(struct EpochReorder* epochReorder, struct GraphCSR* graph, struct ArrayQueue* sharedFrontierQueue, struct ArrayQueue** localFrontierQueues){


	
	__u32 v;
	__u32 u;
	__u32 i;
	__u32 j;
	__u32 edge_idx;
	__u32 mf = 0;


	#pragma omp parallel default (none) private(u,v,j,i,edge_idx) shared(localFrontierQueues,graph,sharedFrontierQueue,mf)
  	{
  		__u32 t_id = omp_get_thread_num();
  		struct ArrayQueue* localFrontierQueue = localFrontierQueues[t_id];
		
  		
  		#pragma omp for reduction(+:mf) schedule(auto)
		for(i = sharedFrontierQueue->head ; i < sharedFrontierQueue->tail; i++){
			v = sharedFrontierQueue->queue[i];
			edge_idx = graph->vertices[v].edges_idx;

	    	for(j = edge_idx ; j < (edge_idx + graph->vertices[v].out_degree) ; j++){
	         
	            u = graph->sorted_edge_array[j];
	            int u_parent = graph->parents[u]; 
	            if(u_parent < 0 ){
				if(__sync_bool_compare_and_swap(&graph->parents[u],u_parent,v))
					{ 
	                enArrayQueue(localFrontierQueue, u);
	                mf +=  -(u_parent);
	          	  }
	        	}
	        }

		} 

		flushArrayQueueToShared(localFrontierQueue,sharedFrontierQueue);
	}
	
	return mf;
}


// bottom-up-step(graph, sharedFrontierQueue, next, parents) //pull
// 	for v ∈ vertices do
// 		if parents[v] = -1 then
// 			for u ∈ neighbors[v] do
// 				if u ∈ sharedFrontierQueue then
// 				parents[v] ← u
// 				next ← next ∪ {v}
// 				break
// 				end if
// 			end for
// 		end if
// 	end for

__u32 epochReorderBottomUpStepGraphCSR(struct EpochReorder* epochReorder, struct GraphCSR* graph, struct Bitmap* bitmapCurr, struct Bitmap* bitmapNext){


	__u32 v;
	__u32 u;
	__u32 j;
	__u32 edge_idx;
	__u32 out_degree;
	struct Vertex* vertices = NULL;
	__u32* sorted_edges_array = NULL;

	// __u32 processed_nodes = bitmapCurr->numSetBits;
    __u32 nf = 0; // number of vertices in sharedFrontierQueue
    // graph->processed_nodes += processed_nodes;

    #if DIRECTED
		vertices = graph->inverse_vertices;
		sorted_edges_array = graph->inverse_sorted_edge_array;
	#else
		vertices = graph->vertices;
		sorted_edges_array = graph->sorted_edge_array;
	#endif

	#pragma omp parallel for default(none) private(j,u,v,out_degree,edge_idx) shared(bitmapCurr,bitmapNext,graph,vertices,sorted_edges_array) reduction(+:nf) schedule(dynamic, 1024)
	for(v=0 ; v < graph->num_vertices ; v++){
				out_degree = vertices[v].out_degree;
				if(graph->parents[v] < 0){ // optmization 
					edge_idx = vertices[v].edges_idx;

		    		for(j = edge_idx ; j < (edge_idx + out_degree) ; j++){
		    			 u = sorted_edges_array[j];
		    			 if(getBit(bitmapCurr, u)){
		    			 	graph->parents[v] = u;
		    			 	setBitAtomic(bitmapNext, v);
		    			 	nf++;
		    			 	break;
		    			 }
		    		}

		    	}
    	
	}
	return nf;
}



__u32* epochReorderCreateLabels(struct EpochReorder* epochReorder){

	__u32* labelsInverse;
	__u32* labels;
	__u32 v;

	#if ALIGNED
      labels = (__u32*) my_aligned_malloc(epochReorder->numVertices*sizeof(__u32));
      labelsInverse = (__u32*) my_aligned_malloc(epochReorder->numVertices*sizeof(__u32));
	#else
      labels = (__u32*) my_malloc(epochReorder->numVertices*sizeof(__u32));
      labelsInverse = (__u32*) my_malloc(epochReorder->numVertices*sizeof(__u32));
	#endif

    #pragma omp parallel for
		for(v = 0; v < epochReorder->numVertices; v++){
			labelsInverse[v]= v;
		}


	//create labels

	return labels;


}

void epochReorderIncrementCounters(struct EpochReorder* epochReorder, __u32 v){

	if(epochReorder->hardcounter > epochReorder->hardThreshold){
		epochReorder->hardcounter = 0;
		epochReorder->rrIndex = (epochReorder->rrIndex + 1 ) % epochReorder->numCounters;
	}

	if(epochReorder->softcounter > epochReorder->softThreshold){
		clearBitmap(epochReorder->recencyBits);
		epochReorder->softcounter = 0;
	}

	__u32 histogramIndex = epochReorder->rrIndex;

	epochReorder->frequency[(histogramIndex*epochReorder->numVertices)+v]++;
	epochReorder->hardcounter++;
	epochReorder->softcounter++;


}

void freeEpochReorder(struct EpochReorder* epochReorder){

	if(epochReorder){
	freeBitmap(epochReorder->recencyBits);
	free( epochReorder->frequency);
	free( epochReorder);
	}
}

