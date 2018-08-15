#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "grid.h"
#include "edgeList.h"
#include "vertex.h"
#include "myMalloc.h"
#include "graphConfig.h"


void gridPrint(struct Grid *grid){


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Grid Properties");
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
    printf("| %-51u | \n", grid->num_vertices);
    printf(" -----------------------------------------------------\n"); 
    printf("| %-51s | \n", "Number of Edges (E)");
    printf("| %-51u | \n", grid->num_edges);  
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Number of Partitions (P)");
    printf("| %-51u | \n", grid->num_partitions);  
    printf(" -----------------------------------------------------\n");

  //   __u32 i;
  //    for ( i = 0; i < (grid->num_partitions*grid->num_partitions); ++i)
  //       {

  //       __u32 x = i % grid->num_partitions;    // % is the "modulo operator", the remainder of i / width;
		// __u32 y = i / grid->num_partitions;
	

  //       printf("| %-11s (%u,%u)   | \n", "Partition: ", y, x);
  //  		printf("| %-11s %-40u  | \n", "Edges: ", grid->partitions[i].num_edges);  
  //  		printf("| %-11s %-40u  | \n", "Vertices: ", grid->partitions[i].num_vertices);  
  //  		edgeListPrint(grid->partitions[i].edgeList);
  //       }


}



struct Grid * gridNew(struct EdgeList* edgeList){

	
	__u32 totalPartitions = 0;

	#if ALIGNED
		struct Grid* grid = (struct Grid*) my_aligned_alloc(sizeof(struct Grid));
	#else
        struct Grid* grid = (struct Grid*) my_malloc( sizeof(struct Grid));
    #endif

    grid->num_edges = edgeList->num_edges;
    grid->num_vertices = edgeList->num_vertices;
    grid->num_partitions = gridCalculatePartitions(edgeList);
    totalPartitions = grid->num_partitions * grid->num_partitions;

    #if ALIGNED
		grid->partitions = (struct Partition*) my_aligned_alloc(totalPartitions * sizeof(struct Partition));
	#else
        grid->partitions = (struct Partition*) my_malloc(totalPartitions * sizeof(struct Partition));
    #endif

        __u32 i;
        for (i = 0; i < totalPartitions; ++i)
        {

		 grid->partitions[i].num_edges = 0;
		 grid->partitions[i].num_vertices = 0;	/* code */
        
        }


    grid = gridPartitionSizePreprocessing(grid, edgeList);
    grid = gridPartitionsMemoryAllocations(grid);
    grid = gridPartitionEdgePopulation(grid, edgeList);

    return grid;
}



void  gridFree(struct Grid *grid){
	__u32 totalPartitions = grid->num_partitions * grid->num_partitions;
	__u32 i;

	for (i = 0; i < totalPartitions; ++i){

           freeEdgeList(grid->partitions[i].edgeList);
	}


	free(grid->partitions);
	free(grid);

}

struct Grid * gridPartitionSizePreprocessing(struct Grid *grid, struct EdgeList* edgeList){

	__u32 i;
	__u32 src;
	__u32 dest;
	__u32 num_partitions = grid->num_partitions;
	__u32 num_vertices = grid->num_vertices;

	__u32 row;
	__u32 col;


	for(i = 0; i < edgeList->num_edges; i++){

		src  = edgeList->edges_array[i].src;
		dest = edgeList->edges_array[i].dest;
		row = getPartitionID(num_vertices, num_partitions, src);
		col = getPartitionID(num_vertices, num_partitions, dest);
		grid->partitions[(row*grid->num_partitions)+col].num_edges++;
		grid->partitions[(row*grid->num_partitions)+col].num_vertices = maxTwoIntegers(grid->partitions[(row*grid->num_partitions)+col].num_vertices,maxTwoIntegers(src, dest));
               
	}

	return grid;


}


struct Grid * gridPartitionEdgePopulation(struct Grid *grid, struct EdgeList* edgeList){

	__u32 i;
	__u32 src;
	__u32 dest;
	__u32 Partition_idx;

	__u32 num_partitions = grid->num_partitions;
	__u32 num_vertices = grid->num_vertices;

	__u32 row;
	__u32 col;


	for(i = 0; i < edgeList->num_edges; i++){


		src  = edgeList->edges_array[i].src;
		dest = edgeList->edges_array[i].dest;
		row = getPartitionID(num_vertices, num_partitions, src);
		col = getPartitionID(num_vertices, num_partitions, dest);
		Partition_idx= (row*grid->num_partitions)+col;

		grid->partitions[Partition_idx].edgeList->edges_array[grid->partitions[Partition_idx].num_edges] = edgeList->edges_array[i];
		grid->partitions[Partition_idx].num_edges++;         
	}

	return grid;


}


struct Grid * gridPartitionsMemoryAllocations(struct Grid *grid){

	__u32 i;
	__u32 totalPartitions = grid->num_partitions*grid->num_partitions;
	
	 for ( i = 0; i < totalPartitions; ++i)
        {

		 
		 grid->partitions[i].edgeList = newEdgeList(grid->partitions[i].num_edges);
		 grid->partitions[i].edgeList->num_vertices = grid->partitions[i].num_vertices;
         grid->partitions[i].num_edges = 0;

        }

	return grid;


}

__u32 gridCalculatePartitions(struct EdgeList* edgeList){
	//epfl everything graph
	__u32 num_vertices  = edgeList->num_vertices;
	__u32 num_Paritions = (num_vertices * 8 / 1024) / 20;
	if(num_Paritions > 2000) 
		num_Paritions = 256;
	if(num_Paritions == 0 ) 
		num_Paritions = 4;

	return num_Paritions;

}



__u32 getPartitionID(__u32 vertices, __u32 partitions, __u32 vertex_id) {
        
        __u32 partition_size = vertices / partitions;

        if (vertices % partitions == 0) {

                return vertex_id / partition_size;
        }

        partition_size += 1;

        __u32 split_point = vertices % partitions * partition_size;

        return (vertex_id < split_point) ? vertex_id / partition_size : (vertex_id - split_point) / (partition_size - 1) + (vertices % partitions);
}

__u32 getPartitionRangeBegin(__u32 vertices, __u32 partitions, __u32 partition_id) {
        
        __u32 split_partition = vertices % partitions;
        __u32 partition_size = vertices / partitions + 1;

        if (partition_id < split_partition) {
				__u32 begin = partition_id * partition_size;
				return begin;
        }
        __u32 split_point = split_partition * partition_size;
        __u32 begin = split_point + (partition_id - split_partition) * (partition_size - 1);
  
        return begin;
}

__u32 getPartitionRangeEnd(__u32 vertices, __u32 partitions, __u32 partition_id) {
        
        __u32 split_partition = vertices % partitions;
        __u32 partition_size = vertices / partitions + 1;

        if (partition_id < split_partition) {
                 __u32 end = (partition_id + 1) * partition_size;
                return  end;
        }
        __u32 split_point = split_partition * partition_size;
        __u32 end = split_point + (partition_id - split_partition + 1) * (partition_size - 1);

        return  end;
}