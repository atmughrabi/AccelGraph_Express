package CU_PKG;

 // parameter INVALID_ID      	= 8'h00; 		defined at capi_pkg
 // parameter WED_ID 			= 8'h01; 		defined at wed_pkg

// Relating to Vertex int types and sizes

parameter VERTEX_SIZE = 4; // vertex size is 4 bytes
parameter EDGE_SIZE = 4; // vertex size is 4 bytes
parameter CACHELINE_SIZE = 128; // cacheline is 128bytes
parameter CACHELINE_VERTEX_NUM = (128 >> $clog2(VERTEX_SIZE)); // number of vertices in one cacheline
parameter CACHELINE_EDGE_NUM = (128 >> $clog2(EDGE_SIZE)); // number of edges in one cacheline
// Relating to CU IDs
parameter VERTEX_CONTROL_ID = 8'h02;			// This is the CU that requests and schedules graph vertices to other CUs
		

endpackage