
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <argp.h>
#include <stdbool.h>
#include <omp.h>


#include "graphStats.h"
#include "edgeList.h"
#include "myMalloc.h"

#include "graphCSR.h"
#include "graphAdjLinkedList.h"
#include "graphAdjArrayList.h"
#include "graphGrid.h"

#include "mt19937.h"
#include "graphConfig.h"
#include "timer.h"
#include "graphRun.h"

#include "BFS.h"
#include "DFS.h"
#include "pageRank.h"
#include "incrementalAggregation.h"
#include "bellmanFord.h"
#include "SSSP.h"

#include <assert.h>
#include "graphTest.h"


__u32 compareRealRanks(__u32 *arr1, __u32 *arr2, __u32 arr1_size, __u32 arr2_size)
{
    __u32 i = 0;
    __u32 missmatch = 0;
    __u32 rank_diff = 0;

    if(arr1_size != arr2_size)
        return 1;

    __u32 *labels1 = (__u32 *) my_malloc(arr1_size * sizeof(__u32));
    __u32 *labels2 = (__u32 *) my_malloc(arr2_size * sizeof(__u32));

    for(i = 0; i < arr1_size; i++)
    {
        labels1[arr1[i]] = i;
        labels2[arr2[i]] = i;
    }


    for(i = 0 ; i < arr1_size; i++)
    {

        if(labels1[i] != labels2[i])
        {
            rank_diff = (labels1[i] > labels2[i]) ? (labels1[i] - labels2[i]) : (labels2[i] - labels1[i]);
            missmatch += rank_diff;
        }
    }

    free(labels1);
    free(labels2);
    return (missmatch / arr1_size);
}

__u32 compareDistanceArrays(__u32 *arr1, __u32 *arr2, __u32 arr1_size, __u32 arr2_size)
{
    __u32 i = 0;
    __u32 missmatch = 0;

    if(arr1_size != arr2_size)
        return 1;

    for(i = 0 ; i < arr1_size; i++)
    {
        if(arr1[i] != arr2[i])
        {
            missmatch++;
        }
    }
    return missmatch;
}

__u32 cmpGraphAlgorithmsTestStats(void *ref_stats, void *cmp_stats, __u32 algorithm)
{

    __u32 missmatch = 0;

    switch (algorithm)
    {
    case 0:  // bfs filename root
    {
        struct BFSStats *ref_stats_tmp = (struct BFSStats * )ref_stats;
        struct BFSStats *cmp_stats_tmp = (struct BFSStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->distances, cmp_stats_tmp->distances, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    case 1: // pagerank filename
    {
        struct PageRankStats *ref_stats_tmp = (struct PageRankStats * )ref_stats;
        struct PageRankStats *cmp_stats_tmp = (struct PageRankStats * )cmp_stats;
        missmatch += compareRealRanks(ref_stats_tmp->realRanks, cmp_stats_tmp->realRanks, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);

    }
    break;
    case 2: // SSSP-Dijkstra file name root
    {
        struct SSSPStats *ref_stats_tmp = (struct SSSPStats * )ref_stats;
        struct SSSPStats *cmp_stats_tmp = (struct SSSPStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->distances, cmp_stats_tmp->distances, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    case 3: // SSSP-Bellmanford file name root
    {
        struct BellmanFordStats *ref_stats_tmp = (struct BellmanFordStats * )ref_stats;
        struct BellmanFordStats *cmp_stats_tmp = (struct BellmanFordStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->distances, cmp_stats_tmp->distances, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    case 4: // DFS file name root
    {
        struct DFSStats *ref_stats_tmp = (struct DFSStats * )ref_stats;
        struct DFSStats *cmp_stats_tmp = (struct DFSStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->distances, cmp_stats_tmp->distances, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    case 5: // incremental Aggregation file name root
    {
        struct IncrementalAggregationStats *ref_stats_tmp = (struct IncrementalAggregationStats * )ref_stats;
        struct IncrementalAggregationStats *cmp_stats_tmp = (struct IncrementalAggregationStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->labels, cmp_stats_tmp->labels, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    default:// bfs file name root
    {
        struct BFSStats *ref_stats_tmp = (struct BFSStats * )ref_stats;
        struct BFSStats *cmp_stats_tmp = (struct BFSStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->distances, cmp_stats_tmp->distances, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    }

    return missmatch;
}

void *runGraphAlgorithmsTest(void *graph, struct Arguments *arguments)
{

    void *ref_stats = NULL;

    switch (arguments->algorithm)
    {
    case 0:  // bfs filename root
    {
        ref_stats = runBreadthFirstSearchAlgorithm( graph,  arguments->datastructure,  arguments->root,  arguments->pushpull);
    }
    break;
    case 1: // pagerank filename
    {
        ref_stats = runPageRankAlgorithm(graph,  arguments->datastructure,  arguments->epsilon,  arguments->iterations,  arguments->pushpull);
    }
    break;
    case 2: // SSSP-Dijkstra file name root
    {
        ref_stats = runSSSPAlgorithm(graph,  arguments->datastructure,  arguments->root,  arguments->iterations, arguments->pushpull,  arguments->delta);
    }
    break;
    case 3: // SSSP-Bellmanford file name root
    {
        ref_stats = runBellmanFordAlgorithm(graph,  arguments->datastructure,  arguments->root,  arguments->iterations, arguments->pushpull);
    }
    break;
    case 4: // DFS file name root
    {
        ref_stats = runDepthFirstSearchAlgorithm(graph,  arguments->datastructure,  arguments->root);
    }
    break;
    case 5: // incremental Aggregation file name root
    {
        ref_stats = runIncrementalAggregationAlgorithm(graph,  arguments->datastructure);
    }
    break;
    default:// bfs file name root
    {
        ref_stats = runBreadthFirstSearchAlgorithm(graph,  arguments->datastructure,  arguments->root, arguments->pushpull);
    }
    break;
    }

    return ref_stats;
}