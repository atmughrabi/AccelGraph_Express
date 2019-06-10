#!/usr/bin/env python
import sys

algorithm = int(sys.argv[1])
direction = int(sys.argv[2])

workloads = [[],["pageRankPullGraphCSRKernelAladdin", "pageRankPushGraphCSRKernelAladdin",
				 "pageRankPullFixedPointGraphCSRKernelAladdin", "pageRankPushFixedPointGraphCSRKernelAladdin"]]


try:
	print(workloads[algorithm][direction])
except IndexError:
 	print(" ")