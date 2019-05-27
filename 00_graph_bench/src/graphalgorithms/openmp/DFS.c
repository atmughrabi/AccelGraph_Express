#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "arrayStack.h"
#include "bitmap.h"
#include "DFS.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

// ********************************************************************************************
// ***************                  Stats DataStructure                          **************
// ********************************************************************************************

struct DFSStats *newDFSStatsGraphCSR(struct GraphCSR *graph)
{

    __u32 vertex_id;

    struct DFSStats *stats = (struct DFSStats *) my_malloc(sizeof(struct DFSStats));

    stats->distances  = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->parents = (int *) my_malloc(graph->num_vertices * sizeof(int));
    stats->processed_nodes = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;

    // optimization for DFS implentaion instead of -1 we use -out degree to for hybrid approach counter
    #pragma omp parallel for default(none) private(vertex_id) shared(stats,graph)
    for(vertex_id = 0; vertex_id < graph->num_vertices ; vertex_id++)
    {
        stats->distances[vertex_id] = 0;
        stats->parents[vertex_id] = -1;
    }

    return stats;

}

struct DFSStats *newDFSStatsGraphGrid(struct GraphGrid *graph)
{

    __u32 vertex_id;

    struct DFSStats *stats = (struct DFSStats *) my_malloc(sizeof(struct DFSStats));

    stats->distances  = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->parents = (int *) my_malloc(graph->num_vertices * sizeof(int));
    stats->processed_nodes = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;

    #pragma omp parallel for default(none) private(vertex_id) shared(stats,graph)
    for(vertex_id = 0; vertex_id < graph->num_vertices ; vertex_id++)
    {
        stats->distances[vertex_id] = 0;
        stats->parents[vertex_id] = -1;
    }

    return stats;
}

struct DFSStats *newDFSStatsGraphAdjArrayList(struct GraphAdjArrayList *graph)
{

    __u32 vertex_id;

    struct DFSStats *stats = (struct DFSStats *) my_malloc(sizeof(struct DFSStats));

    stats->distances  = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->parents = (int *) my_malloc(graph->num_vertices * sizeof(int));
    stats->processed_nodes = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;


    #pragma omp parallel for default(none) private(vertex_id) shared(stats,graph)
    for(vertex_id = 0; vertex_id < graph->num_vertices ; vertex_id++)
    {
        stats->distances[vertex_id] = 0;
        stats->parents[vertex_id] = -1;
    }

    return stats;
}

struct DFSStats *newDFSStatsGraphAdjLinkedList(struct GraphAdjLinkedList *graph)
{

    __u32 vertex_id;

    struct DFSStats *stats = (struct DFSStats *) my_malloc(sizeof(struct DFSStats));

    stats->distances  = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->parents = (int *) my_malloc(graph->num_vertices * sizeof(int));
    stats->processed_nodes = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;


    #pragma omp parallel for default(none) private(vertex_id) shared(stats,graph)
    for(vertex_id = 0; vertex_id < graph->num_vertices ; vertex_id++)
    {
        stats->distances[vertex_id] = 0;
        stats->parents[vertex_id] = -1;
    }

    return stats;
}

void freeDFSStats(struct DFSStats *stats)
{


    if(stats)
    {
        if(stats->distances)
            free(stats->distances);
        if(stats->parents)
            free(stats->parents);

        free(stats);
    }

}


// ********************************************************************************************
// ***************                  CSR DataStructure                            **************
// ********************************************************************************************



struct DFSStats  *depthFirstSearchGraphCSRBase(__u32 source, struct GraphCSR *graph)
{

    struct DFSStats *stats = newDFSStatsGraphCSR(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct ArrayStack *sharedFrontierStack = newArrayStack(graph->num_vertices);

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Depth First Search (SOURCE NODE)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices)
    {
        printf(" -----------------------------------------------------\n");
        printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
        printf(" -----------------------------------------------------\n");
        return stats;
    }


    pushArrayStack(sharedFrontierStack, source);
    stats->parents[source] = source;

    Start(timer);
    while(!isEmptyArrayStackCurr(sharedFrontierStack))  // start while
    {

        __u32 v = popArrayStack(sharedFrontierStack);

        stats->processed_nodes++;
        __u32 edge_idx = graph->vertices->edges_idx[v];
        __u32 j;


        for(j = edge_idx ; j < (edge_idx + graph->vertices->out_degree[v]) ; j++)
        {

            __u32 u = graph->sorted_edges_array->edges_array_dest[j];
            int u_parent = stats->parents[u];
            if(u_parent < 0 )
            {
                stats->parents[u] = v;
                stats->distances[u] = stats->distances[v]+1;
                pushArrayStack(sharedFrontierStack, u);
            }
        }


    } // end while
    Stop(timer);

    stats->time_total = Seconds(timer);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "No OverHead", stats->processed_nodes,  stats->time_total);
    printf(" -----------------------------------------------------\n");
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "total", stats->processed_nodes, Seconds(timer));
    printf(" -----------------------------------------------------\n");

    freeArrayStack(sharedFrontierStack);

    free(timer);

    return stats;
}



struct DFSStats  *depthFirstSearchGraphCSR(__u32 source, struct GraphCSR *graph)
{

    struct DFSStats *stats = newDFSStatsGraphCSR(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct ArrayStack *sharedFrontierStack = newArrayStack(graph->num_vertices);


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Depth First Search (SOURCE NODE)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices)
    {
        printf(" -----------------------------------------------------\n");
        printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
        printf(" -----------------------------------------------------\n");
        return stats;
    }

    pushArrayStack(sharedFrontierStack, source);
    stats->parents[source] = source;



    Start(timer);
    while(!isEmptyArrayStackCurr(sharedFrontierStack))  // start while
    {

        __u32 v = popArrayStack(sharedFrontierStack);

        stats->processed_nodes++;
        __u32 edge_idx = graph->vertices->edges_idx[v];
        __u32 j;

        for(j = edge_idx ; j < (edge_idx + graph->vertices->out_degree[v]) ; j++)
        {

            __u32 u = graph->sorted_edges_array->edges_array_dest[j];
            int u_parent = stats->parents[u];
            if(u_parent < 0 )
            {
                stats->parents[u] = v;
                stats->distances[u] = stats->distances[v]+1;
                pushArrayStack(sharedFrontierStack, u);
            }
        }


    } // end while
    Stop(timer);

    stats->time_total = Seconds(timer);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "No OverHead", stats->processed_nodes,  stats->time_total);
    printf(" -----------------------------------------------------\n");
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "total", stats->processed_nodes, Seconds(timer));
    printf(" -----------------------------------------------------\n");

    freeArrayStack(sharedFrontierStack);

    free(timer);

    return stats;
}

struct DFSStats  *pDepthFirstSearchGraphCSR(__u32 source, struct GraphCSR *graph)
{

    struct DFSStats *stats = newDFSStatsGraphCSR(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting P-Depth First Search (SOURCE NODE)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices)
    {
        printf(" -----------------------------------------------------\n");
        printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
        printf(" -----------------------------------------------------\n");
        return stats;
    }

    stats->parents[source] = source;

    Start(timer);
    parallelDepthFirstSearchGraphCSRTask(source, graph, stats);
    Stop(timer);

    stats->time_total = Seconds(timer);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "No OverHead", stats->processed_nodes,  stats->time_total);
    printf(" -----------------------------------------------------\n");
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "total", stats->processed_nodes, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    free(timer);

    return stats;

}

void parallelDepthFirstSearchGraphCSRTask(__u32 source, struct GraphCSR *graph, struct DFSStats *stats)
{

    __u32 v = source;

    #pragma omp atomic update
    stats->processed_nodes++;

    // printf("%u \n", stats->processed_nodes);

    __u32 edge_idx = graph->vertices->edges_idx[v];
    __u32 j;

    for(j = edge_idx ; j < (edge_idx + graph->vertices->out_degree[v]) ; j++)
    {

        __u32 u = graph->sorted_edges_array->edges_array_dest[j];
        int u_parent = stats->parents[u];
        if(u_parent < 0 )
        {
            if(__sync_bool_compare_and_swap(&(stats->parents[u]), u_parent, v))
            {

                
                stats->distances[u] = stats->distances[v]+1;

                // #pragma omp task
                parallelDepthFirstSearchGraphCSRTask( u, graph, stats);

            }
        }
    }

}