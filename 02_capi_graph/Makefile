
#########################################################
#       		 GENERAL DIRECTOIRES   	    			#
#########################################################
# globals binaary /bin/accel-graph name doesn't need to match main/accel-graph.c
APP_CAPI          ?= accel-graph

# test name needs to match the file name test/test_accel-graph.c
#   APP_TEST          = test_accel-graph
APP_TEST          ?= test_accel-graph


# dirs Root app
APP_DIR           		?= .
APP_DIR_OPEN_GRAPH      ?= ../00_open_graph/00_graph_bench
APP_DIR_CAPI_PRECIS  	?= ./01_capi_precis
CAPI_PRECIS_INTEG_DIR   ?= $(APP_DIR_CAPI_PRECIS)/01_capi_integration
CAPI_INTEG_DIR      	?= 03_capi_integration
SCRIPT_DIR          	?= 05_scripts

BENCHMARKS_DIR_LOCAL    ?= 01_test_graphs

BENCHMARKS_DIR 			=  ../00_open_graph/$(BENCHMARKS_DIR_LOCAL)
# BENCHMARKS_DIR    		= ../../$(BENCHMARKS_DIR_LOCAL)

#dir root/managed_folders
SRC_DIR           	?= src
OBJ_DIR			  	?= obj
INC_DIR			  	?= include
BIN_DIR			  	?= bin
RES_DIR			  	?= results

#if you want to compile from cmake you need this directory
#cd build
#cmake ..
BUILD_DIR		  	?= build

# relative directories used for managing src/obj files
STRUCT_DIR		  	?= structures
PREPRO_DIR		  	?= preprocess
ALGO_DIR		  	?= algorithms
UTIL_DIR		  	?= utils
CONFIG_DIR			?= config
CAPI_UTIL_DIR		?= capi_utils

# Folders needed when using CAPI


#contains the tests use make run-test to compile what in this directory
TEST_DIR		  	?= tests

#contains the main for the graph processing framework
MAIN_DIR		  	?= main

##################################################
##################################################

#########################################################
#       		 ACCEL RUN GRAPH ARGUMENTS    			#
#########################################################

# export BENCHMARKS_DIR    	?= ../../01_GraphDatasets
export BENCHMARKS_DIR    	?= ../01_test_graphs

# export GRAPH_SUIT ?=
export GRAPH_SUIT ?= TEST
# export GRAPH_SUIT ?= LAW
# export GRAPH_SUIT ?= GAP
# export GRAPH_SUIT ?= SNAP
# export GRAPH_SUIT ?= KONECT
# export GRAPH_SUIT ?= GONG

# TEST # small test graphs
# export GRAPH_NAME ?= test
# export GRAPH_NAME ?= v51_e1021
# export GRAPH_NAME ?= v300_e2730
export GRAPH_NAME ?= graphbrew

# GONG # https://gonglab.pratt.duke.edu/google-dataset
# export GRAPH_NAME ?= GONG-gplus
# export GRAPH_NAME ?= Gong-gplus

# GAP # https://sparse.tamu.edu/MM/GAP/
# export GRAPH_NAME ?= GAP-twitter
# export GRAPH_NAME ?= GAP-road

# SNAP # https://snap.stanford.edu/data/
# export GRAPH_NAME ?= SNAP-cit-Patents
# export GRAPH_NAME ?= SNAP-com-Orkut
# export GRAPH_NAME ?= SNAP-soc-LiveJournal1
# export GRAPH_NAME ?= SNAP-soc-Pokec
# export GRAPH_NAME ?= SNAP-web-Google

# KONECT # http://konect.cc/networks/wikipedia_link_en/
# export GRAPH_NAME ?= KONECT-wikipedia_link_en

# LAW # https://sparse.tamu.edu/MM/LAW/
# export GRAPH_NAME ?= LAW-amazon-2008
# export GRAPH_NAME ?= LAW-arabic-2005
# export GRAPH_NAME ?= LAW-cnr-2000
# export GRAPH_NAME ?= LAW-dblp-2010
# export GRAPH_NAME ?= LAW-enron
# export GRAPH_NAME ?= LAW-eu-2005
# export GRAPH_NAME ?= LAW-hollywood-2009
# export GRAPH_NAME ?= LAW-in-2004
# export GRAPH_NAME ?= LAW-indochina-2004
# export GRAPH_NAME ?= LAW-it-2004
# export GRAPH_NAME ?= LAW-ljournal-2008
# export GRAPH_NAME ?= LAW-uk-2002
# export GRAPH_NAME ?= LAW-uk-2005
# export GRAPH_NAME ?= LAW-webbase-2001

# export FILE_BIN_TYPE ?= graph
export FILE_BIN_TYPE ?= graph.bin
# export FILE_BIN_TYPE ?= graph.wbin

# export FILE_LABEL_TYPE ?= graph_Gorder.labels
export FILE_LABEL_TYPE ?= graph_Rabbit.labels

#GRAPH file
export FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_SUIT)/$(GRAPH_NAME)/$(FILE_BIN_TYPE)
export FILE_LABEL = $(BENCHMARKS_DIR)/$(GRAPH_SUIT)/$(GRAPH_NAME)/$(FILE_LABEL_TYPE)

LAW ?= amazon-2008 arabic-2005 cnr-2000 dblp-2010 enron eu-2005 hollywood-2009 in-2004 indochina-2004 it-2004 ljournal-2008 sk-2005 uk-2002 uk-2005 webbase-2001
MIX ?= GAP-kron GAP-road GAP-twitter GAP-urand GAP-web
CU_CONFIG_MODES ?= 0x00000000 0x00041000 0x00841000 0x10041000 0x10841000

#GRAPH RUN
SORT_TYPE 		?= 0
REORDER 		?= 0
DATA_STRUCTURES ?= 0
ALGORITHMS 		?= 1

ROOT 			?= 164
PULL_PUSH 		?= 2
TOLERANCE 		?= 1e-8
DELTA 			?= 800

START_THREADS   ?= 1
INC_THREADS     ?= 1
NUM_THREADS  	?= 64
# NUM_THREADS  	= $(shell grep -c ^processor /proc/cpuinfo)
NUM_ITERATIONS 	?= 1
NUM_TRIALS 		?= 1

FILE_FORMAT 	?= 1
CONVERT_FORMAT 	?= 1

#STATS COLLECTION VARIABLES
BIN_SIZE ?= 512
INOUT_STATS ?= 2

export ARGS ?= -k -M $(MASK_MODE) -j $(INOUT_STATS) -g $(BIN_SIZE) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS_PRE) -N $(NUM_THREADS_ALGO) -K $(NUM_THREADS_KER) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -F $(FILE_LABEL) -l $(REORDER_LAYER1) -L $(REORDER_LAYER2) -O $(REORDER_LAYER3) -b $(DELTA) -C $(CACHE_SIZE)

export ARGS_CAPI = -q $(CU_CONFIG_GENERIC) -m $(AFU_CONFIG_GENERIC) $(ARGS)

##############################################
# CAPI FPGA  GRAPH AFU PERFORMANCE CONFIG    #
##############################################
# // cu_vertex_job_control        5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [19] [18] [15:17]
# // 0b 00000 00000 00000 00000 00000 00000 00
CU_CONFIG_MODE?=0x00000000

# // cu_vertex_job_control        5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits STRICT | READ_CL_S  | WRITE_NA 00010 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits STRICT | READ_CL_NA | WRITE_MS 00001 [22:26] [19] [18] [15:17]
# // 0b 00000 00000 00010 00001 00000 00000 00
# export CU_CONFIG_MODE=0x00041000

# // cu_vertex_job_control        5-bits ABORT | READ_CL_NA | WRITE_NA 10000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits ABORT | READ_CL_NA | WRITE_NA 10000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits ABORT | READ_CL_S  | WRITE_NA 10010 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits ABORT | READ_CL_NA | WRITE_MS 10001 [22:26] [19] [18] [15:17]
#  // 0b 10000 10000 10010 10001 00000 00000 00
# export CU_CONFIG_MODE=0x84251000

# // cu_vertex_job_control        5-bits PREF | READ_CL_NA | WRITE_NA 11000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits PREF | READ_CL_NA | WRITE_NA 11000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits PREF | READ_CL_NA | WRITE_NA 11000 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits PREF | READ_CL_NA | WRITE_NA 11000 [22:26] [19] [18] [15:17]
# // 0b 11000 11000 11000 11000 00000 00000 00
# export CU_CONFIG_MODE=0xC6318000

# // cu_vertex_job_control        5-bits PREF | READ_CL_NA | WRITE_NA 11000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits PREF | READ_CL_NA | WRITE_NA 11000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits PREF | READ_CL_S  | WRITE_NA 11010 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits PREF | READ_CL_NA | WRITE_MS 11001 [22:26] [19] [18] [15:17]
# // 0b 11000 11000 11010 11001 00000 00000 00
# export CU_CONFIG_MODE=0xC6359000

##############################################
# CAPI FPGA AFU ARBITER CONFIG               #
##############################################
# shift credits >>
# read_credits            [0:3]
# write_credits           [4:7]
# prefetch_read_credits   [8:11]
# prefetch_write_credits  [12:15]
# FIXED_ARB               [62]
# ROUND_ROBIN_ARB         [63]

ROUND_ROBIN_ARB?=0x1111000000000001
FIXED_ARB?=0x1111000000000002

##############################################
# CAPI FPGA AFU/CU      CONFIG               #
##############################################

AFU_CONFIG_MODE?=$(ROUND_ROBIN_ARB)
# export AFU_CONFIG_MODE=$(FIXED_ARB)

CU_CONFIG_GENERIC?=$(CU_CONFIG_MODE)
AFU_CONFIG_GENERIC?=$(AFU_CONFIG_MODE)
##################################################
##################################################


##############################################
#      ACCEL GRAPH COMPILATION VARIABLES     #
##############################################


SRC_FILES_UTIL		=	$(wildcard $(APP_DIR_OPEN_GRAPH)/$(SRC_DIR)/$(UTIL_DIR)/*.c)
SRC_FILES_PREPRO	=	$(wildcard $(APP_DIR_OPEN_GRAPH)/$(SRC_DIR)/$(PREPRO_DIR)/*.c)
SRC_FILES_STRUCT	=	$(wildcard $(APP_DIR_OPEN_GRAPH)/$(SRC_DIR)/$(STRUCT_DIR)/*.c)
SRC_FILES_MAIN		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/*.c)
SRC_FILES_TEST		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/*.c)


OBJ_FILES_UTIL 		= $(patsubst $(APP_DIR_OPEN_GRAPH)/$(SRC_DIR)/$(UTIL_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%.o,$(SRC_FILES_UTIL))
OBJ_FILES_PREPRO 	= $(patsubst $(APP_DIR_OPEN_GRAPH)/$(SRC_DIR)/$(PREPRO_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%.o,$(SRC_FILES_PREPRO))
OBJ_FILES_STRUCT 	= $(patsubst $(APP_DIR_OPEN_GRAPH)/$(SRC_DIR)/$(STRUCT_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%.o,$(SRC_FILES_STRUCT))
OBJ_FILES_MAIN  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/%.o,$(SRC_FILES_MAIN))
OBJ_FILES_TEST  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/%.o,$(SRC_FILES_TEST))

CC				  = gcc

OPENMP_INC = 	-I$(APP_DIR_OPEN_GRAPH)/$(INC_DIR)/$(STRUCT_DIR)    \
				-I$(APP_DIR_OPEN_GRAPH)/$(INC_DIR)/$(PREPRO_DIR)    \
				-I$(APP_DIR_OPEN_GRAPH)/$(INC_DIR)/$(UTIL_DIR)		\
				-I$(APP_DIR)/$(INC_DIR)/$(ALGO_DIR)/capi 			\
				-I$(APP_DIR)/$(INC_DIR)/$(CONFIG_DIR)   


# flags
CFLAGS   =  -O3 -Wall -m64 -fopenmp -g
LFLAGS 	 = -lm -lJudy


# TEST PASS OR FAIL
PASS = \033[92mPASS\033[0m
FAIL = \033[91mFAIL\033[0m

##################################################
##################################################

##############################################
#      CAPI  GRAPH COMPILATION VARIABLES     #
##############################################

ARCHITECTURE = $(shell uname -p) # store the output of the command in a variable if on intel run simulation if power8 run fpga

PSLSE_DIR         		 = ../$(CAPI_PRECIS_INTEG_DIR)/pslse
LIBCXL_DIR        		 = ../$(CAPI_PRECIS_INTEG_DIR)/libcxl
IBM_CAPI_UTILS_DIR       = ../$(CAPI_PRECIS_INTEG_DIR)/capi-utils
CAPI_SERVER		  		 = ../$(CAPI_INTEG_DIR)/accelerator_sim/server
CAPI_SIM		  		 = ../$(CAPI_INTEG_DIR)/accelerator_sim/sim



PSLSE_COMMON_DIR  = $(PSLSE_DIR)/common
# PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl


SRC_FILES_ALGO_CAPI			=  $(wildcard $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/capi/*.c)
OBJ_FILES_ALGO_CAPI 		=  $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/capi/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/capi/%.o,$(SRC_FILES_ALGO_CAPI))

SRC_FILES_CAPI_UTIL			=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(CAPI_UTIL_DIR)/*.c)
OBJ_FILES_CAPI_UTIL 		=   $(patsubst $(APP_DIR)/$(SRC_DIR)/$(CAPI_UTIL_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(CAPI_UTIL_DIR)/%.o,$(SRC_FILES_CAPI_UTIL))


CAPI_LINKFLAGS = -lrt -lpthread

# CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
# CAPI_FLAGS = -DSIM -DVERBOSE

##################################################
##################################################

INC_FILES_ALGO_CAPI	=	$(wildcard $(APP_DIR)/$(INC_DIR)/$(ALGO_DIR)/capi/*.h)
INC_FILES_CAPI_UTIL	=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(CAPI_UTIL_DIR)/*.h)
INC_FILES_CONFIG    =   $(wildcard $(APP_DIR)/$(INC_DIR)/$(CONFIG_DIR)/*.h)
INC_FILES_UTIL		=	$(wildcard $(APP_DIR_OPEN_GRAPH)/$(INC_DIR)/$(UTIL_DIR)/*.h)
INC_FILES_PREPRO	=	$(wildcard $(APP_DIR_OPEN_GRAPH)/$(INC_DIR)/$(PREPRO_DIR)/*.h)
INC_FILES_STRUCT	=	$(wildcard $(APP_DIR_OPEN_GRAPH)/$(INC_DIR)/$(STRUCT_DIR)/*.h)



ALL_HEADER_FILES    =   $(INC_FILES_ALGO_CAPI) $(INC_FILES_CAPI_UTIL) $(INC_FILES_UTIL) $(INC_FILES_PREPRO) $(INC_FILES_STRUCT) $(INC_FILES_CONFIG)

#########################################################
#       		 OPEN GRAPH LIBRARY     				#
#########################################################

.PHONY: directories
directories :
	@mkdir -p $(APP_DIR)/$(BIN_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)

$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(APP_CAPI).o : $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/accel-graph.c
	$(CC) $(CFLAGS) $(CAPI_INC) $(OPENMP_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%.o : $(APP_DIR_OPEN_GRAPH)/$(SRC_DIR)/$(UTIL_DIR)/%.c $(ALL_HEADER_FILES)
	$(CC) $(CFLAGS) $(CAPI_INC) $(OPENMP_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%.o : $(APP_DIR_OPEN_GRAPH)/$(SRC_DIR)/$(PREPRO_DIR)/%.c $(ALL_HEADER_FILES)
	$(CC) $(CFLAGS) $(CAPI_INC) $(OPENMP_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%.o : $(APP_DIR_OPEN_GRAPH)/$(SRC_DIR)/$(STRUCT_DIR)/%.c $(ALL_HEADER_FILES)
	$(CC) $(CFLAGS) $(CAPI_INC) $(OPENMP_INC) -c -o $@ $<


##################################################
##################################################

#########################################################
#       		 CAPI GRAPH GENERATION    				#
#########################################################

.PHONY: clean-pslse
clean-pslse:
	@cd $(PSLSE_DIR)/afu_driver/src && make clean
	@cd $(PSLSE_DIR)/pslse && make clean
	@cd $(PSLSE_DIR)/libcxl && make clean

.PHONY: app-capi
app-capi : directories directories-capi $(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> AccelGraph: ./$(word 3,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: test-capi
test-capi : directories directories-capi $(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-capi
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> TEST: ./$(word 3,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: directories-capi
directories-capi :
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/capi
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(CAPI_UTIL_DIR)

$(PSLSE_DIR)/afu_driver/src/libdpi.so:
	@cd $(PSLSE_DIR)/afu_driver/src && make clean && BIT32=y make

$(PSLSE_LIBCXL_DIR)/libcxl.a:
	@cd $(PSLSE_LIBCXL_DIR) && make

$(PSLSE_DIR)/pslse/pslse:
	@cd $(PSLSE_DIR)/pslse && make DEBUG=1

.PHONY: build-libdpi
build-libdpi: $(PSLSE_DIR)/afu_driver/src/libdpi.so

.PHONY: build-libcxl
build-libcxl: $(PSLSE_LIBCXL_DIR)/libcxl.a

.PHONY: build-pslse
build-pslse: $(PSLSE_DIR)/pslse/pslse

$(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi : $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(APP_CAPI).o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO_CAPI) $(OBJ_FILES_CAPI_UTIL) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT)
	@$(CC) $(CFLAGS) -o $@ $^ $(LFLAGS) $(PSLSE_LIBCXL_DIR)/libcxl.a $(CAPI_LINKFLAGS)

$(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-capi : $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(APP_TEST)-capi.o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO_CAPI) $(OBJ_FILES_CAPI_UTIL) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT)
	@$(CC) $(CFLAGS) -o $@ $^ $(LFLAGS) $(PSLSE_LIBCXL_DIR)/libcxl.a $(CAPI_LINKFLAGS)

$(APP_DIR)/$(OBJ_DIR)/$(CAPI_UTIL_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(CAPI_UTIL_DIR)/%.c build-libcxl $(ALL_HEADER_FILES)
	$(CC) $(CFLAGS) $(OPENMP_INC) $(CAPI_INC) -c -o $@ $< $(CAPI_FLAGS)

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/capi/%.o : $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/capi/%.c $(ALL_HEADER_FILES)
	$(CC) $(CFLAGS) $(OPENMP_INC) $(CAPI_INC) -c -o $@ $< $(CAPI_FLAGS)

$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(APP_TEST)-capi.o : $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(APP_TEST).c $(ALL_HEADER_FILES)
	$(CC) $(CFLAGS) $(OPENMP_INC) $(CAPI_INC) -c -o $@ $< $(CAPI_FLAGS)

.PHONY: clean-sim
clean-sim:
	@rm -f $(CAPI_SIM)/modelsim.ini
	@rm -f $(CAPI_SIM)/transcript
	@rm -f $(CAPI_SIM)/vsim_stacktrace.vstf
	@rm -f $(CAPI_SIM)/vish_stacktrace.vstf
	@rm -f $(CAPI_SIM)/vsim.wlf
	@rm -f $(CAPI_SIM)/*.vcd
	@rm -rf $(CAPI_SIM)/work
	@rm -rf $(CAPI_SIM)/libraries
	@rm -f $(CAPI_SERVER)/debug.log
	@rm -f $(CAPI_SIM)/gmon.out
	@cd $(PSLSE_DIR)/afu_driver/src && make clean
	@cd $(PSLSE_DIR)/libcxl && make clean
	@cd $(PSLSE_DIR)/pslse && make  clean

.PHONY: clean
clean:
	@rm -fr $(APP_DIR)/$(OBJ_DIR)
	@rm -fr $(APP_DIR)/$(BIN_DIR)

.PHONY: scrub
scrub: clean clean-sim

##################################################
##################################################
##################################################

 PART?=5SGXMA7H2F35C2
 PROJECT?= accel-graph
 CU_SET_SIM?=$(shell python ../$(SCRIPT_DIR)/choose_algorithm_sim.py $(DATA_STRUCTURES) $(ALGORITHMS) $(PULL_PUSH) $(NUM_THREADS))

##############################################
#      ACCEL GRAPH CAPI TOP LEVEL RULES      #
##############################################

.PHONY: run-capi-sim
run-capi-sim: CAPI_FLAGS = -DSIM
run-capi-sim: PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl
run-capi-sim: CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-sim: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi  -f $(FILE_BIN) $(ARGS_CAPI)

.PHONY: run-capi-sim-verbose
run-capi-sim-verbose: CAPI_FLAGS = -DSIM -DVERBOSE
run-capi-sim-verbose: PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl
run-capi-sim-verbose: CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-sim-verbose: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi  -f $(FILE_BIN) $(ARGS_CAPI)

.PHONY: run-capi-sim-verbose2
run-capi-sim-verbose2: CAPI_FLAGS = -DSIM -DVERBOSE -DVERBOSE_2
run-capi-sim-verbose2: PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl
run-capi-sim-verbose2: CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-sim-verbose2: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi  -f $(FILE_BIN) $(ARGS_CAPI)

.PHONY: run-capi-sim-verbose3
run-capi-sim-verbose3: CAPI_FLAGS = -DSIM -DVERBOSE -DVERBOSE_3
run-capi-sim-verbose3: PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl
run-capi-sim-verbose3: CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-sim-verbose3: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi  -f $(FILE_BIN) $(ARGS_CAPI)

.PHONY: run-capi-fpga
run-capi-fpga: CAPI_FLAGS =
run-capi-fpga: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
run-capi-fpga: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-fpga: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi  -f $(FILE_BIN) $(ARGS_CAPI)

.PHONY: run-capi-fpga-verbose
run-capi-fpga-verbose: CAPI_FLAGS = -DVERBOSE
run-capi-fpga-verbose: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
run-capi-fpga-verbose: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-fpga-verbose: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi  -f $(FILE_BIN) $(ARGS_CAPI)

.PHONY: run-capi-fpga-verbose2
run-capi-fpga-verbose2: CAPI_FLAGS = -DVERBOSE -DVERBOSE_2
run-capi-fpga-verbose2: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
run-capi-fpga-verbose2: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-fpga-verbose2: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi  -f $(FILE_BIN) $(ARGS_CAPI)

.PHONY: run-capi-fpga-verbose3
run-capi-fpga-verbose3: CAPI_FLAGS = -DVERBOSE -DVERBOSE_3
run-capi-fpga-verbose3: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
run-capi-fpga-verbose3: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-fpga-verbose3: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi  -f $(FILE_BIN) $(ARGS_CAPI)

.PHONY: run-test-capi
run-test-capi: CAPI_FLAGS = -DVERBOSE -DALGO_DIRECTION=$(PULL_PUSH)
run-test-capi: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
run-test-capi: CAPI_INC   = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-test-capi: test-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-capi

.PHONY: run-test-capi-sim
run-test-capi-sim: CAPI_FLAGS = -DSIM -DVERBOSE -DALGO_DIRECTION=$(PULL_PUSH)
run-test-capi-sim: PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl
run-test-capi-sim: CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-test-capi-sim: test-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-capi

.PHONY: run-vsim
run-vsim: build-libdpi
	cd $(CAPI_SIM) && vsim -do "$(CU_SET_SIM);source vsim.tcl"

.PHONY: run-pslse
run-pslse: build-pslse
	cd $(CAPI_SIM) && ./../../../$(CAPI_PRECIS_INTEG_DIR)/pslse/pslse/pslse

.PHONY: law-capi
law-capi: CAPI_FLAGS = -DVERBOSE
law-capi: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
law-capi: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
law-capi: app-capi
	@for config in $(CU_CONFIG_MODES); do \
		for graph in $(LAW); do \
		    for num in `seq $(START_THREADS) $(INC_THREADS) $(NUM_THREADS)`; do \
		    	echo $$config $$graph $$num ; \
		    	./$(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi  -j $(INOUT_STATS) -f $(BENCHMARKS_DIR)/$$graph/graph.wbin -q $$config -m $(AFU_CONFIG_GENERIC) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $$num  -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA) ;\
		    done ; \
	    done ; \
	done

.PHONY: mix-capi
mix-capi: CAPI_FLAGS = -DVERBOSE
mix-capi: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
mix-capi: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
mix-capi: app-capi
	@for config in $(CU_CONFIG_MODES); do \
		for graph in $(LAW); do \
		    for num in `seq $(START_THREADS) $(INC_THREADS) $(NUM_THREADS)`; do \
		    	echo $$config $$graph $$num ; \
		    	./$(APP_DIR)/$(BIN_DIR)/$(APP_CAPI)-capi  -j $(INOUT_STATS) -f $(BENCHMARKS_DIR)/$$graph/graph.wbin -q $$config -m $(AFU_CONFIG_GENERIC) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $$num  -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA) ;\
		    done ; \
	    done ; \
	done

##################################################
##################################################