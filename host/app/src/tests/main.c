#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <omp.h>

#include "graphRun.h"
#include "edgeList.h"
#include "myMalloc.h"
#include "timer.h"

int numThreads;

static void usage(void) {
  printf("\nUsage: ./main -f <graph file> -d [data structure] -a [algorithm] -r [root] -n [num threads] [-u -s -w]\n");
  printf("\t-a [algorithm] : 0 bfs, 1 pagerank, 2 SSSP\n");
  printf("\t-d [data structure] : 0 CSR, 1 Grid, 2 Adj Linked List, 3 Adj Array List [4-5] same order bitmap frontiers\n");
  printf("\t-r [root]: BFS & SSSP root\n");
  printf("\t-p [algorithm direction] 0 push 1 pull 2 push/pull\n");
  printf("\t-n [num threads] default:max number of threads the system has\n");
  printf("\t-i [num iterations] number of random trials [default:0]\n");
  printf("\t-t [num iterations] number of iterations for page rank random\n");
  printf("\t-e [epsilon/tolerance ] tolerance value of for page rank [default:0.0001]\n");
  printf("\t-c: convert to bin file on load example:-f <graph file> -c\n");
  printf("\t-u: create undirected on load => check graphConfig.h #define DIRECTED 0 then recompile\n");
  printf("\t-w: weighted input graph check graphConfig.h #define WEIGHTED 1 then recompile\n");
  printf("\t-s: symmetric graph, if not given set of incoming edges will be created \n"); 
  _exit(-1);
}

int main (int argc, char **argv)
{
  int uflag = 0;
  int wflag = 0;
  int sflag = 0;
  int cflag = 0;

  char *fvalue = NULL;
  char *avalue = NULL;
  char *rvalue = NULL;
  char *dvalue = NULL;
  char *nvalue = NULL;
  char *ivalue = NULL;
  char *tvalue = NULL;
  char *evalue = NULL;
  char *pvalue = NULL;

  int iterations = 0;
  int trials = 20;
  double epsilon = 0.0001;
  int root = -1;
  int algorithm = 0;
  int datastructure = 0;
  int pushpull = 0;
  numThreads = omp_get_max_threads();

  char *fnameb = NULL;
  void *graph = NULL;


  int c;
  opterr = 0;

  while ((c = getopt (argc, argv, "h:f:d:a:r:n:i:uswc")) != -1)
    switch (c)
      {
      case 'h':
        usage();
        break;
      case 'f':
        fvalue = optarg;
        fnameb = fvalue;
        break;
      case 'd':
        dvalue = optarg;
        datastructure = atoi(dvalue);
        break;
      case 'a':
        avalue = optarg;
        algorithm = atoi(avalue);
        break;
      case 'r':
        rvalue = optarg;
        root = atoi(rvalue);
        break;
       break;
      case 'n':
        nvalue = optarg;
        numThreads = atoi(nvalue);
        break;
      case 'i':
        ivalue = optarg;
        iterations = atoi(ivalue);
        break;
      case 't':
        tvalue = optarg;
        trials = atoi(tvalue);
        break;
      case 'e':
        evalue = optarg;
        epsilon = atof(evalue);
        break;
      case 'p':
        pvalue = optarg;
        pushpull = atof(pvalue);
        break;
      case 'u':
        uflag = 1;
        break;
      case 's':
        wflag = 1;
        break;
      case 'w':
        sflag = 1;
        break;
      case 'c':
        cflag = 1;
        break;
      case '?':
        if (optopt == 'f')
          fprintf (stderr, "Option -%c <graph file> requires an argument  .\n", optopt);
        else if (optopt == 'd')
          fprintf (stderr, "Option -%c [data structure] requires an argument.\n", optopt);
        else if (optopt == 'a')
          fprintf (stderr, "Option -%c [algorithm] requires an argument.\n", optopt);
        else if (optopt == 'r')
          fprintf (stderr, "Option -%c [root] requires an argument.\n", optopt);
        else if (optopt == 'n')
          fprintf (stderr, "Option -%c [num threads] requires an argument.\n", optopt);
        else if (optopt == 'i')
          fprintf (stderr, "Option -%c [num iterations] requires an argument.\n", optopt);
        else if (optopt == 't')
          fprintf (stderr, "Option -%c [num trials] requires an argument.\n", optopt);
        else if (optopt == 'e')
          fprintf (stderr, "Option -%c [epsilon] requires an argument.\n", optopt);
        else if (optopt == 'p')
          fprintf (stderr, "Option -%c [push/pull] requires an argument.\n", optopt);
        else if (isprint (optopt))
          fprintf (stderr, "Unknown option `-%c'.\n", optopt);
        else
          fprintf (stderr,
                   "Unknown option character `\\x%x'.\n",
                   optopt);

        usage();
        return 1;
      default:
        abort ();
      }

      struct Timer* timer = (struct Timer*) my_malloc(sizeof(struct Timer));
      
      init_genrand(27491095);
      omp_set_nested(1);
      omp_set_num_threads(numThreads);

      if(cflag)
      {
        Start(timer);
        fnameb = readEdgeListstxt(fnameb);
        Stop(timer);
        printf("Read Edge List From File converted to binary : %f Seconds \n",Seconds(timer));
      }

      
      graph = generateGraphDataStructure(fnameb, datastructure);
      runGraphAlgorithms(graph, datastructure, algorithm, root, iterations, epsilon, trials);


      free(timer);
  return 0;
}



