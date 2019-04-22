
#include <linux/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <omp.h>
#include <limits.h>

#include "graphCSR.h"
#include "mt19937.h"
#include "reorder.h"
#include "arrayQueue.h"
#include "myMalloc.h"
#include "epochReorder.h"
#include "bitmap.h"
#include "timer.h"

#include "pageRank.h"
#include "BFS.h"


__u32 epochAtomicMin(__u32 *dist , __u32 newValue){

	__u32 oldValue;
	__u32 flag = 0;

	do{

		oldValue = *dist;
		if(oldValue > newValue){
			if(__sync_bool_compare_and_swap(dist, oldValue, 0)){
	    		flag = 1;
	   			// printf("| %-15s | %-30u | \n","Hard hardThreshold", newValue);
				// printf("| %-15s | %-30u | \n","Hard counter", oldValue);
	    	}
		}
		else{
			return 0;
		}
	}while(!flag);

	return 1;
}



struct EpochReorder* newEpochReoder( __u32 softThreshold, __u32 hardThreshold, __u32 numCounters, __u32 numVertices){

		__u32 v =0;
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


        #pragma omp parallel for
		  for(v = 0; v < (numCounters*numVertices); v++){
		     epochReorder->frequency[v] = 0;
		  }
        
        return epochReorder;

}

__u32* epochReorderPageRank(struct GraphCSR* graph){

	
	 __u32 numCounters = 20;
	 __u32 hardThreshold = 4096;
	 __u32 softThreshold = 8192;
	 double epsilon = 1e-6;
	__u32 iterations = 2;
	__u32* labels;

	struct EpochReorder* epochReorder = newEpochReoder(softThreshold, hardThreshold, numCounters, graph->num_vertices);

	epochReorderPageRankPullGraphCSR(epochReorder, epsilon, iterations, graph);

	labels = epochReorderCreateLabels(epochReorder);

	freeEpochReorder(epochReorder);

	return labels;

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
    printf("| %-51s | \n", "Starting Page Rank Epoch Pull (tolerance/epsilon)");
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
      // epochReorderIncrementCounters(epochReorder,v);

      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = sorted_edges_array[j];
        nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
        atomicEpochReorderIncrementCounters( epochReorder, u);
      }

      // epochReorderIncrementCounters(epochReorder,v);
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


__u32* epochReorderRecordBFS(struct GraphCSR* graph){

	
	 __u32* labels;
	 __u32* labelsInverse;
	 __u32* degrees;
	 __u32 root = genrand_int31();
	 __u32 v;

    #if ALIGNED
        labels = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        labelsInverse = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    	degrees = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    
    #else
        labels = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        labelsInverse = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));

    #endif
	 
	 #pragma omp parallel for
	  for(v = 0; v < graph->num_vertices; v++){
	    labelsInverse[v]= v;
	    degrees[v]= graph->vertices[v].out_degree;

	    // printf("%u %u \n",labelsInverse[v],degrees[v] );
	  }

  	labelsInverse = radixSortEdgesByDegree(degrees, labelsInverse, graph->num_vertices);

   //decending order mapping
  // #pragma omp parallel for
  // for(v = 0; v < graph->num_vertices; v++){
  //   labels[labelsInverse[v]] = graph->num_vertices -1 - v;

  //   // printf("%u %u \n",labelsInverse[v],degrees[v] );
  // }

  	 __u32 numCounters = 50;
	 __u32 hardThreshold = graph->num_edges/numCounters;
	 __u32 softThreshold = graph->num_edges/degrees[graph->num_vertices-1];
	

	struct EpochReorder* epochReorder = newEpochReoder(softThreshold, hardThreshold, numCounters, graph->num_vertices);

	  // #pragma omp parallel for
		for(v = graph->num_vertices-1 ; v > 0; v--){
    		root = labelsInverse[v];

    		// printf("soft %u hard %u root %u degree %u \n",softThreshold, hardThreshold, root, degrees[v] );

              // if(graph->parents[root] < 0){

                epochReorderBreadthFirstSearchGraphCSR( epochReorder, root, graph);
              // }   
              // root = genrand_int31();

    //           if(((graph->processed_nodes*100.0f)/graph->num_vertices) > 50.0)
				// break;

				if(v < graph->num_vertices-10)
					break;

			printf(" -----------------------------------------------------\n");
			printf("| %-15s | %-30f | \n","SUM total", (graph->processed_nodes*100.0f)/graph->num_vertices);
			printf(" -----------------------------------------------------\n");
			printf(" -----------------------------------------------------\n");
			printf("| %-15s | %-30u | \n","EPOCH ", epochReorder->rrIndex);
			printf(" -----------------------------------------------------\n");

            }
        
    // printEpochs(epochReorder);
	
    free(labels);
    
	labels = epochReorderCreateLabels(epochReorder);



	freeEpochReorder(epochReorder);
	free(labelsInverse);
	free(degrees);
	

	return labels;


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

	// graphCSRReset(graph); // no need to recet once processed_nodes = num vertices we traveresed the whole graph
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


	#pragma omp parallel default (none) private(u,v,j,i,edge_idx) shared(epochReorder,localFrontierQueues,graph,sharedFrontierQueue,mf)
  	{
  		__u32 t_id = omp_get_thread_num();
  		struct ArrayQueue* localFrontierQueue = localFrontierQueues[t_id];
		
  		
  		#pragma omp for reduction(+:mf) schedule(auto)
		for(i = sharedFrontierQueue->head ; i < sharedFrontierQueue->tail; i++){
			v = sharedFrontierQueue->queue[i];
			edge_idx = graph->vertices[v].edges_idx;
			atomicEpochReorderIncrementCounters( epochReorder, v);
	    	for(j = edge_idx ; j < (edge_idx + graph->vertices[v].out_degree) ; j++){
	            u = graph->sorted_edge_array[j];
	            int u_parent = graph->parents[u];
	            atomicEpochReorderIncrementCounters( epochReorder, u);
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

	#pragma omp parallel for default(none) private(j,u,v,out_degree,edge_idx) shared(epochReorder,bitmapCurr,bitmapNext,graph,vertices,sorted_edges_array) reduction(+:nf) schedule(dynamic, 1024)
	for(v=0 ; v < graph->num_vertices ; v++){
				out_degree = vertices[v].out_degree;
				if(graph->parents[v] < 0){ // optmization 
					edge_idx = vertices[v].edges_idx;
					atomicEpochReorderIncrementCounters( epochReorder, v);
		    		for(j = edge_idx ; j < (edge_idx + out_degree) ; j++){
		    			 u = sorted_edges_array[j];
		    			 atomicEpochReorderIncrementCounters( epochReorder, u);
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

	__u32* labelsInverse = NULL;
	__u32* histMaps = NULL;
	__u32* histValues = NULL;
	__u32 v = 0;
	__u32 h = 0;
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Epoch Create Labels");
    printf(" -----------------------------------------------------\n");

    Start(timer);


	#if ALIGNED
      labelsInverse = (__u32*) my_aligned_malloc(epochReorder->numVertices*sizeof(__u32));
      histMaps = (__u32*) my_aligned_malloc(epochReorder->numVertices*sizeof(__u32));
      histValues = (__u32*) my_aligned_malloc(epochReorder->numVertices*sizeof(__u32));
      labels = (__u32*) my_aligned_malloc(epochReorder->numVertices*sizeof(__u32));

	#else
      labelsInverse = (__u32*) my_malloc(epochReorder->numVertices*sizeof(__u32));
      histMaps = (__u32*) my_malloc(epochReorder->numVertices*sizeof(__u32));
      histValues = (__u32*) my_malloc(epochReorder->numVertices*sizeof(__u32));
      labels = (__u32*) my_malloc(epochReorder->numVertices*sizeof(__u32));
	#endif

    #pragma omp parallel for
		for(v = 0; v < epochReorder->numVertices; v++){
			labelsInverse[v]= v;
			histMaps[v]=0;
			histValues[v]=0;
		}


	//find max histogram values
	#pragma omp parallel for private(h) shared(histValues, histMaps, epochReorder)
		for(v = 0; v < epochReorder->numVertices; v++){
			__u32 maxValue = 0;
			__u32 maxIndex = UINT_MAX/2;
			for(h = 0; h < epochReorder->numCounters; h++ ){
				if(epochReorder->frequency[(h*epochReorder->numVertices)+v] > maxValue){
					maxValue = epochReorder->frequency[(h*epochReorder->numVertices)+v];
					maxIndex = h;
				}
			}

			histMaps[v] = maxIndex;
			histValues[v] = maxValue;
		}


	labelsInverse = radixSortEdgesByEpochs(histValues, histMaps, labelsInverse, epochReorder->numVertices);

	Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Epoch Create Labels Complete");
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", Seconds(timer));
    printf(" -----------------------------------------------------\n");

  	free(timer);
	return labelsInverse;

}

void printEpochs(struct EpochReorder* epochReorder){

	__u32 v = 0;
	__u32 h = 0;

	for(v = 0; v < epochReorder->numVertices; v++){
		printf("v[%u] ",v);
			for(h = 0; h < epochReorder->numCounters; h++ ){
				printf("%u[%u] ", h,epochReorder->frequency[(h*epochReorder->numVertices)+v]);
			}
		printf("\n");
		}

}

void epochReorderIncrementCounters(struct EpochReorder* epochReorder, __u32 v){

	__u32 histogramIndex = 0;


	if(epochReorder->hardcounter > epochReorder->hardThreshold){
		epochReorder->hardcounter = 0;
		epochReorder->rrIndex++;
		epochReorder->rrIndex  %= epochReorder->numCounters;

	}
	

	if(epochReorder->softcounter > epochReorder->softThreshold){
		epochReorder->softcounter = 0;
		clearBitmap(epochReorder->recencyBits);
		
	}

		histogramIndex = epochReorder->rrIndex;
		epochReorder->frequency[(histogramIndex*epochReorder->numVertices)+v]++;
		epochReorder->hardcounter++;
		epochReorder->softcounter++;

}

void atomicEpochReorderIncrementCounters(struct EpochReorder* epochReorder, __u32 v){


	__u32 histogramIndex = 0;

	if(epochAtomicMin(&(epochReorder->hardcounter),epochReorder->hardThreshold)){

		epochReorder->rrIndex++;
		epochReorder->rrIndex  %= epochReorder->numCounters;
		
	}
	else{
		#pragma omp atomic update
			epochReorder->hardcounter++;
	}

	// if(epochAtomicMin(&(epochReorder->softcounter),epochReorder->softThreshold)){
	// 	clearBitmap(epochReorder->recencyBits);
	// }
	// else{
	// 	#pragma omp atomic update
	// 		epochReorder->softcounter++;
	// }
		
	#pragma omp atomic read
		histogramIndex = epochReorder->rrIndex;
	
	// if(!getBit(epochReorder->recencyBits, v)){
	//  	setBitAtomic(epochReorder->recencyBits, v);
	//  	#pragma omp atomic update
			epochReorder->frequency[(histogramIndex*epochReorder->numVertices)+v]++;
	// }
	// else{
	// 	#pragma omp atomic update
	// 		epochReorder->frequency[(histogramIndex*epochReorder->numVertices)+v] += 2;
	// }
	
	

}

void freeEpochReorder(struct EpochReorder* epochReorder){

	if(epochReorder){
	freeBitmap(epochReorder->recencyBits);
	free( epochReorder->frequency);
	free( epochReorder);
	}
}




void radixSortCountSortEdgesByEpochs (__u32** histValues, __u32** histValuesTemp,__u32** histMaps, __u32** histMapsTemp, __u32** labels, __u32** labelsTemp,__u32 radix, __u32 buckets, __u32* buckets_count, __u32 num_vertices){

	__u32* tempPointer1 = NULL;
	__u32* tempPointer2 = NULL; 
	__u32* tempPointer3 = NULL; 
    __u32 t = 0;
    __u32 o = 0;
    __u32 u = 0;
    __u32 i = 0;
    __u32 j = 0;
    __u32 P = numThreads;  // 32/8 8 bit radix needs 4 iterations
    __u32 t_id = 0;
    __u32 offset_start = 0;
    __u32 offset_end = 0;
    __u32 base = 0;

    #pragma omp parallel default(none) shared(histValues, histValuesTemp, histMaps, histMapsTemp,radix,labels,labelsTemp,buckets,buckets_count, num_vertices) firstprivate(t_id, P, offset_end,offset_start,base,i,j,t,u,o) 
    {
        P = omp_get_num_threads();
        t_id = omp_get_thread_num();
        offset_start = t_id*(num_vertices/P);


        if(t_id == (P-1)){
            offset_end = offset_start+(num_vertices/P) + (num_vertices%P) ;
        }
        else{
            offset_end = offset_start+(num_vertices/P);
        }
        

        //HISTOGRAM-KEYS 
        for(i=0; i < buckets; i++){ 
            buckets_count[(t_id*buckets)+i] = 0;
        }

       
        for (i = offset_start; i < offset_end; i++) {      
            u = (*histMaps)[i];
            t = (u >> (radix*8)) & 0xff;
            buckets_count[(t_id*buckets)+t]++;
        }


        #pragma omp barrier

       
        // SCAN BUCKETS
        if(t_id == 0){
            for(i=0; i < buckets; i++){
                 for(j=0 ; j < P; j++){
                 t = buckets_count[(j*buckets)+i];
                 buckets_count[(j*buckets)+i] = base;
                 base += t;
                }
            }
        }


        #pragma omp barrier

        //RANK-AND-PERMUTE
        for (i = offset_start; i < offset_end; i++) {       /* radix sort */
            u = (*histMaps)[i];
            t = (u >> (radix*8)) & 0xff;
            o = buckets_count[(t_id*buckets)+t];
            (*histMapsTemp)[o] = (*histMaps)[i];
            (*histValuesTemp)[o] = (*histValues)[i];
            (*labelsTemp)[o] = (*labels)[i];
            buckets_count[(t_id*buckets)+t]++;

        }

    }

    tempPointer1 = *labels;
    *labels = *labelsTemp;
    *labelsTemp = tempPointer1;


    tempPointer2 = *histValues;
    *histValues = *histValuesTemp;
    *histValuesTemp = tempPointer2;

    tempPointer3 = *histMaps;
    *histMaps = *histMapsTemp;
    *histMapsTemp = tempPointer3;
    
}


__u32* radixSortEdgesByEpochs (__u32* histValues,__u32* histMaps, __u32* labels, __u32 num_vertices){

	
	    // printf("*** START Radix Sort Edges By Source *** \n");

    // struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges, inverse);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number
    __u32 radix = 4;  // 32/8 8 bit radix needs 4 iterations
    __u32 P = numThreads;  // 32/8 8 bit radix needs 4 iterations
    __u32 buckets = 256; // 2^radix = 256 buckets
    __u32* buckets_count = NULL;

    // omp_set_num_threads(P);
   	
    __u32 j = 0; //1,2,3 iteration
    __u32 v = 0;


    __u32* histValuesTemp = NULL;
    __u32* histMapsTemp = NULL;
    __u32* labelsTemp = NULL;
  

    #if ALIGNED
        buckets_count = (__u32*) my_aligned_malloc(P * buckets * sizeof(__u32));
        histValuesTemp = (__u32*) my_aligned_malloc(num_vertices * sizeof(__u32));
        histMapsTemp = (__u32*) my_aligned_malloc(num_vertices * sizeof(__u32));
        labelsTemp = (__u32*) my_aligned_malloc(num_vertices * sizeof(__u32));
    #else
        buckets_count = (__u32*) my_malloc(P * buckets * sizeof(__u32));
        histValuesTemp = (__u32*) my_malloc(num_vertices * sizeof(__u32));
        histMapsTemp = (__u32*) my_malloc(num_vertices * sizeof(__u32));
        labelsTemp = (__u32*) my_malloc(num_vertices * sizeof(__u32));
    #endif

    #pragma omp parallel for
	for(v = 0; v < num_vertices; v++){
		histValuesTemp[v]=0;
		histMapsTemp[v]=UINT_MAX/2;
	}

    for(j=0 ; j < radix ; j++){
        radixSortCountSortEdgesByEpochs (&histMaps, &histMapsTemp, &histValues, &histValuesTemp, &labels, &labelsTemp,j, buckets, buckets_count, num_vertices);
    }

    for(j=0 ; j < radix ; j++){
        radixSortCountSortEdgesByEpochs (&histValues, &histValuesTemp, &histMaps, &histMapsTemp, &labels, &labelsTemp,j, buckets, buckets_count, num_vertices);
    }

    free(buckets_count);
    free(histValuesTemp);
    free(histMapsTemp);
    free(labelsTemp);

    return labels;

}