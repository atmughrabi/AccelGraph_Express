  #!/usr/bin/tclsh

# if { $argc != 1 } {
#   puts "Default Project cu_CSR_PageRank_pull"
#   set project_algorithm "cu_CSR_PageRank_pull"
# } else {
#   puts "SET Project to [lindex $argv 0]"
#   set project_algorithm "[lindex $argv 0]"
# }

set afu_control_dir "../../../01_capi_precis/01_capi_integration"
set cu_control_dir "../.."

# recompile
proc r  {} {
  global graph_algorithm
  global data_structure
  global direction
  global cu_precision
  global cu_count
  global afu_control_dir
  global cu_control_dir
  # compile SystemVerilog files

  # compile libs
  echo "Compiling libs"

  # compile packages
  echo "Compiling Packages AFU-1"
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_pkgs/globals_afu_pkg.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_pkgs/capi_pkg.sv

  vlog -quiet $afu_control_dir/accelerator_rtl/afu_pkgs/credit_pkg.sv


  echo "Compiling CU Packages"
  echo "Algorithm $graph_algorithm"
  echo "Datastructure $data_structure"
  echo "Direction $direction"
  echo "Precision $cu_precision"
  echo "CU Count  $cu_count"

  if {$graph_algorithm eq "cu_PageRank"} {
    if {$data_structure eq "CSR"} {

     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_pkg/wed_pkg.sv
     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/$cu_precision/pkg/globals_cu_pkg.sv
     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_pkg/cu_pkg.sv

   } elseif {$data_structure eq "GRID"} {


   } else {
    echo "UNKNOWN Datastructure"
  }

   } elseif {$graph_algorithm eq "cu_BFS"} {
    if {$data_structure eq "CSR"} {

     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_pkg/wed_pkg.sv
     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/$cu_precision/pkg/globals_cu_pkg.sv
     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_pkg/cu_pkg.sv

   } elseif {$data_structure eq "GRID"} {
   } else {
    echo "UNKNOWN Datastructure"
  }

   } elseif {$graph_algorithm eq "cu_SPMV"} {
    if {$data_structure eq "CSR"} {

     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_pkg/wed_pkg.sv
     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/$cu_precision/pkg/globals_cu_pkg.sv
     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_pkg/cu_pkg.sv

   } elseif {$data_structure eq "GRID"} {
   } else {
    echo "UNKNOWN Datastructure"
  }

   } elseif {$graph_algorithm eq "cu_ConnectedComponents"} {
    if {$data_structure eq "CSR"} {

     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_pkg/wed_pkg.sv
     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/$cu_precision/pkg/globals_cu_pkg.sv
     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_pkg/cu_pkg.sv

   } elseif {$data_structure eq "GRID"} {
   } else {
    echo "UNKNOWN Datastructure"
  }

   }  elseif {$graph_algorithm eq "cu_TriangleCount"} {
    if {$data_structure eq "CSR"} {

     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_pkg/wed_pkg.sv
     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/$cu_precision/pkg/globals_cu_pkg.sv
     vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_pkg/cu_pkg.sv

   } elseif {$data_structure eq "GRID"} {
   } else {
    echo "UNKNOWN Datastructure"
  }

   } else {
    echo "UNKNOWN Algorithm"
  }


  echo "Compiling Packages AFU-2"
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_pkgs/afu_pkg.sv

  # compile afu
  echo "Compiling RTL General"
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/parity.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/reset_filter.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/reset_control.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/error_control.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/done_control.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/ram.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/fifo.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/priority_arbiters.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/round_robin_priority_arbiter.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/fixed_priority_arbiter.sv

  echo "Compiling RTL AFU Control"
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/credit_control.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/response_statistics_control.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/response_control.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/restart_control.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/command_control.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/tag_control.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/read_data_control.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/write_data_control.sv
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/afu_control.sv

  echo "Compiling RTL JOB"
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/job.sv

  echo "Compiling RTL MMIO"
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/mmio.sv

  echo "Compiling RTL WED_control"
  vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/wed_control.sv

  echo "Compiling RTL CU control "
  echo "Algorithm $graph_algorithm"
  echo "Datastructure $data_structure"
  echo "Direction $direction"
  echo "Precision $cu_precision"

  if {$graph_algorithm eq "cu_PageRank"} {
    if {$data_structure eq "CSR"} {

        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/sum_reduce.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/demux_bus.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/array_struct_type_demux_bus.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/array_struct_type_filter_command_demux_bus.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/array_struct_type_filter_vertex_criterion_demux_bus.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_cache_base_module.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_cache_resue_module.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/$cu_precision/cu/cu_sum_kernel_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_write_command_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_cache_extract_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_read_extract_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_read_command_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_job_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_job_filter.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_job_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_graph_algorithm_arbiter_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_pagerank_arbiter_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_pagerank.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_graph_algorithm_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_graph_algorithm_cu_clusters_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_cache_reuse_control.sv

   } elseif {$data_structure eq "GRID"} {

   } else {
    echo "UNKNOWN Datastructure"
    }
    
   } elseif {$graph_algorithm eq "cu_BFS"} {
      if {$data_structure eq "CSR"} {

          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/sum_reduce.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/demux_bus.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/array_struct_type_demux_bus.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/$cu_precision/cu/cu_update_kernel_control.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_write_command_control.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_read_extract_control.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_read_command_control.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_job_control.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_job_filter.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_job_control.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_cluster_arbiter_control.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_bfs_arbiter_control.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_bfs.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_cluster_control.sv
          vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_control.sv

     } elseif {$data_structure eq "GRID"} {

     } else {
      echo "UNKNOWN Datastructure"
    }

   } elseif {$graph_algorithm eq "cu_SPMV"} {
    if {$data_structure eq "CSR"} {

        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/sum_reduce.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/demux_bus.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/array_struct_type_demux_bus.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/$cu_precision/cu/cu_sum_kernel_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_write_command_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_read_extract_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_read_command_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_job_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_job_filter.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_job_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_cluster_arbiter_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_spmv_arbiter_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_spmv.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_cluster_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_control.sv

   } elseif {$data_structure eq "GRID"} {

   } else {
    echo "UNKNOWN Datastructure"
    }
   }  elseif {$graph_algorithm eq "cu_ConnectedComponents"} {
    if {$data_structure eq "CSR"} {

        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/sum_reduce.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/demux_bus.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/array_struct_type_demux_bus.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/$cu_precision/cu/cu_update_kernel_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_write_command_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_read_extract_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_read_command_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_job_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_job_filter.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_job_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_cluster_arbiter_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_connectedComponents_arbiter_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_connectedComponents.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_cluster_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_control.sv

   } elseif {$data_structure eq "GRID"} {

   } else {
    echo "UNKNOWN Datastructure"
    }
   }  elseif {$graph_algorithm eq "cu_TriangleCount"} {
    if {$data_structure eq "CSR"} {

        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/sum_reduce.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/demux_bus.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/array_struct_type_demux_bus.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/$cu_precision/cu/cu_update_kernel_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_write_command_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_read_extract_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_data_read_command_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_edge_job_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_job_filter.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_job_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_cluster_arbiter_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_triangleCount_arbiter_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_triangleCount.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_vertex_cluster_control.sv
        vlog -quiet $cu_control_dir/accelerator_rtl/cu_control/$graph_algorithm/$data_structure/$direction/global_cu/cu_control.sv

   } elseif {$data_structure eq "GRID"} {

   } else {
    echo "UNKNOWN Datastructure"
    }
   }  else {
    echo "UNKNOWN Algorithm"
  }

    echo "Compiling RTL AFU"
    vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/afu.sv
    vlog -quiet $afu_control_dir/accelerator_rtl/afu_control/cached_afu.sv


  # compile top level
  echo "Compiling top level"
  # vlog -quiet       pslse/afu_driver/verilog/top.v
  vlog -quiet -sv +define+PSL8=PSL8 $afu_control_dir/pslse/afu_driver/verilog/top.v

}

# simulate
proc c {} {
  global graph_algorithm
  global data_structure
  global direction
  global cu_precision
  global afu_control_dir
  global cu_control_dir
  # vsim -t ns -novopt -c -pli pslse/afu_driver/src/veriuser.sl +nowarnTSCALE work.top
  # vsim -t ns -L work -L work_lib -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver -novopt  -voptargs=+acc=npr -c -sv_lib ../../pslse/afu_driver/src/libdpi +nowarnTSCALE work.top
  vsim -t ns -novopt -voptargs=+acc=npr -c -sv_lib $afu_control_dir/pslse/afu_driver/src/libdpi +nowarnTSCALE work.top
  view wave
  radix h
  log * -r
  # do wave.do
  # do watch_job_interface.do
  # do watch_mmio_interface.do
  # do watch_command_interface.do
  # do watch_buffer_interface.do
  # do watch_response_interface.do
  # vcd file ${graph_algorithm}_${data_structure}_${direction}_${cu_precision}.vcd

  # vcd add * -r
  # view structure
  # view signals
  # view wave
  run -all
  # run 40
}

proc c_fp {} {

  global afu_control_dir
  global cu_control_dir
  # vsim -t ns -novopt -c -pli pslse/afu_driver/src/veriuser.sl +nowarnTSCALE work.top
  vsim -novopt -t ns -L work -L work_lib -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver   -voptargs=+acc=npr -c -sv_lib $afu_control_dir/pslse/afu_driver/src/libdpi +nowarnTSCALE work.top
  view wave
  radix h
  log * -r
  # do wave.do
  # do watch_job_interface.do
  # do watch_mmio_interface.do
  # do watch_command_interface.do
  # do watch_buffer_interface.do
  # do watch_response_interface.do

  # view structure
  # view signals
  # view wave
  run -all
  # run 40
}

# shortcut for recompilation + simulation
proc rc {} {
  # init libs
  vlib work
  vmap work work

  r
  c
}

proc rcf {} {
  
  fp_single_add_acc_c
  fp_single_mul_c
  r
  c_fp
}

proc fp_single_add_acc_c {} {

  set QSYS_SIMDIR "../../accelerator_synth/psl_fpga/quartus_ip/fp/fp_single_precision_acc/fp_single_add_acc_sim"
  set USER_DEFINED_COMPILE_OPTIONS ""
  set USER_DEFINED_VHDL_COMPILE_OPTIONS ""
  set USER_DEFINED_VERILOG_COMPILE_OPTIONS ""

  source $QSYS_SIMDIR/mentor/msim_setup.tcl


  dev_com
  com
}

proc fp_single_mul_c {} {

  set QSYS_SIMDIR "../../accelerator_synth/psl_fpga/quartus_ip/fp/fp_single_precision_mul/fp_single_mul_sim"
  set USER_DEFINED_COMPILE_OPTIONS ""
  set USER_DEFINED_VHDL_COMPILE_OPTIONS ""
  set USER_DEFINED_VERILOG_COMPILE_OPTIONS ""

  source $QSYS_SIMDIR/mentor/msim_setup.tcl

  dev_com
  com
}

proc rcd {} {
  global direction

  if {$direction eq "PULL"} {
  set QSYS_SIMDIR "../../accelerator_synth/psl_fpga/quartus_ip/fp/fp_double_precision_acc/fp_double_add_acc_sim"
  } elseif {$direction eq "PUSH"} {
  set QSYS_SIMDIR "../../accelerator_synth/psl_fpga/quartus_ip/fp/fp_double_precision_add/fp_double_add_sim"
  } else {
  echo "UNKNOWN Packages CU"
  }

  set USER_DEFINED_COMPILE_OPTIONS ""
  set USER_DEFINED_VHDL_COMPILE_OPTIONS ""
  set USER_DEFINED_VERILOG_COMPILE_OPTIONS ""

  source $QSYS_SIMDIR/mentor/msim_setup.tcl

  dev_com
  com

  r
  c_fp
}

