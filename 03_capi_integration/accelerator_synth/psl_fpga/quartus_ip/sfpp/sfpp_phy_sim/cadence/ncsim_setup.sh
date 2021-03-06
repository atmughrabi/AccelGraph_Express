
# (C) 2001-2020 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and 
# other software and tools, and its AMPP partner logic functions, and 
# any output files any of the foregoing (including device programming 
# or simulation files), and any associated documentation or information 
# are expressly subject to the terms and conditions of the Altera 
# Program License Subscription Agreement, Altera MegaCore Function 
# License Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by Altera 
# or its authorized distributors. Please refer to the applicable 
# agreement for further details.

# ACDS 18.1 625 linux 2020.02.23.20:51:25

# ----------------------------------------
# ncsim - auto-generated simulation script

# ----------------------------------------
# This script provides commands to simulate the following IP detected in
# your Quartus project:
#     sfpp_phy
# 
# Altera recommends that you source this Quartus-generated IP simulation
# script from your own customized top-level script, and avoid editing this
# generated script.
# 
# To write a top-level shell script that compiles Altera simulation libraries
# and the Quartus-generated IP in your project, along with your design and
# testbench files, copy the text from the TOP-LEVEL TEMPLATE section below
# into a new file, e.g. named "ncsim.sh", and modify text as directed.
# 
# You can also modify the simulation flow to suit your needs. Set the
# following variables to 1 to disable their corresponding processes:
# - SKIP_FILE_COPY: skip copying ROM/RAM initialization files
# - SKIP_DEV_COM: skip compiling the Quartus EDA simulation library
# - SKIP_COM: skip compiling Quartus-generated IP simulation files
# - SKIP_ELAB and SKIP_SIM: skip elaboration and simulation
# 
# ----------------------------------------
# # TOP-LEVEL TEMPLATE - BEGIN
# #
# # QSYS_SIMDIR is used in the Quartus-generated IP simulation script to
# # construct paths to the files required to simulate the IP in your Quartus
# # project. By default, the IP script assumes that you are launching the
# # simulator from the IP script location. If launching from another
# # location, set QSYS_SIMDIR to the output directory you specified when you
# # generated the IP script, relative to the directory from which you launch
# # the simulator. In this case, you must also copy the generated files
# # "cds.lib" and "hdl.var" - plus the directory "cds_libs" if generated - 
# # into the location from which you launch the simulator, or incorporate
# # into any existing library setup.
# #
# # Run Quartus-generated IP simulation script once to compile Quartus EDA
# # simulation libraries and Quartus-generated IP simulation files, and copy
# # any ROM/RAM initialization files to the simulation directory.
# # - If necessary, specify any compilation options:
# #   USER_DEFINED_COMPILE_OPTIONS
# #   USER_DEFINED_VHDL_COMPILE_OPTIONS applied to vhdl compiler
# #   USER_DEFINED_VERILOG_COMPILE_OPTIONS applied to verilog compiler
# #
# source <script generation output directory>/cadence/ncsim_setup.sh \
# SKIP_ELAB=1 \
# SKIP_SIM=1 \
# USER_DEFINED_COMPILE_OPTIONS=<compilation options for your design> \
# USER_DEFINED_VHDL_COMPILE_OPTIONS=<VHDL compilation options for your design> \
# USER_DEFINED_VERILOG_COMPILE_OPTIONS=<Verilog compilation options for your design> \
# QSYS_SIMDIR=<script generation output directory>
# #
# # Compile all design files and testbench files, including the top level.
# # (These are all the files required for simulation other than the files
# # compiled by the IP script)
# #
# ncvlog <compilation options> <design and testbench files>
# #
# # TOP_LEVEL_NAME is used in this script to set the top-level simulation or
# # testbench module/entity name.
# #
# # Run the IP script again to elaborate and simulate the top level:
# # - Specify TOP_LEVEL_NAME and USER_DEFINED_ELAB_OPTIONS.
# # - Override the default USER_DEFINED_SIM_OPTIONS. For example, to run
# #   until $finish(), set to an empty string: USER_DEFINED_SIM_OPTIONS="".
# #
# source <script generation output directory>/cadence/ncsim_setup.sh \
# SKIP_FILE_COPY=1 \
# SKIP_DEV_COM=1 \
# SKIP_COM=1 \
# TOP_LEVEL_NAME=<simulation top> \
# USER_DEFINED_ELAB_OPTIONS=<elaboration options for your design> \
# USER_DEFINED_SIM_OPTIONS=<simulation options for your design>
# #
# # TOP-LEVEL TEMPLATE - END
# ----------------------------------------
# 
# IP SIMULATION SCRIPT
# ----------------------------------------
# If sfpp_phy is one of several IP cores in your
# Quartus project, you can generate a simulation script
# suitable for inclusion in your top-level simulation
# script by running the following command line:
# 
# ip-setup-simulation --quartus-project=<quartus project>
# 
# ip-setup-simulation will discover the Altera IP
# within the Quartus project, and generate a unified
# script which supports all the Altera IP within the design.
# ----------------------------------------
# ACDS 18.1 625 linux 2020.02.23.20:51:25
# ----------------------------------------
# initialize variables
TOP_LEVEL_NAME="sfpp_phy"
QSYS_SIMDIR="./../"
QUARTUS_INSTALL_DIR="/home/ab/intelFPGA/18.1/quartus/"
SKIP_FILE_COPY=0
SKIP_DEV_COM=0
SKIP_COM=0
SKIP_ELAB=0
SKIP_SIM=0
USER_DEFINED_ELAB_OPTIONS=""
USER_DEFINED_SIM_OPTIONS="-input \"@run 100; exit\""

# ----------------------------------------
# overwrite variables - DO NOT MODIFY!
# This block evaluates each command line argument, typically used for 
# overwriting variables. An example usage:
#   sh <simulator>_setup.sh SKIP_SIM=1
for expression in "$@"; do
  eval $expression
  if [ $? -ne 0 ]; then
    echo "Error: This command line argument, \"$expression\", is/has an invalid expression." >&2
    exit $?
  fi
done

# ----------------------------------------
# initialize simulation properties - DO NOT MODIFY!
ELAB_OPTIONS=""
SIM_OPTIONS=""
if [[ `ncsim -version` != *"ncsim(64)"* ]]; then
  :
else
  :
fi

# ----------------------------------------
# create compilation libraries
mkdir -p ./libraries/work/
mkdir -p ./libraries/sfpp_phy/
mkdir -p ./libraries/altera_ver/
mkdir -p ./libraries/lpm_ver/
mkdir -p ./libraries/sgate_ver/
mkdir -p ./libraries/altera_mf_ver/
mkdir -p ./libraries/stratixv_ver/
mkdir -p ./libraries/stratixv_hssi_ver/
mkdir -p ./libraries/stratixv_pcie_hip_ver/
mkdir -p ./libraries/altera/
mkdir -p ./libraries/lpm/
mkdir -p ./libraries/sgate/
mkdir -p ./libraries/altera_mf/
mkdir -p ./libraries/altera_lnsim/
mkdir -p ./libraries/stratixv/
mkdir -p ./libraries/stratixv_hssi/
mkdir -p ./libraries/stratixv_pcie_hip/

# ----------------------------------------
# copy RAM/ROM files to simulation directory

# ----------------------------------------
# compile device library files
if [ $SKIP_DEV_COM -eq 0 ]; then
  ncvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                      -work altera_ver           
  ncvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                               -work lpm_ver              
  ncvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                                  -work sgate_ver            
  ncvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                              -work altera_mf_ver        
  ncvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_atoms.v"                         -work stratixv_ver         
  ncvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_atoms.v"                    -work stratixv_hssi_ver    
  ncvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_atoms.v"                -work stratixv_pcie_hip_ver
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_syn_attributes.vhd"                -work altera               
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_standard_functions.vhd"            -work altera               
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/alt_dspbuilder_package.vhd"               -work altera               
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_europa_support_lib.vhd"            -work altera               
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives_components.vhd"         -work altera               
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.vhd"                    -work altera               
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/220pack.vhd"                              -work lpm                  
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.vhd"                             -work lpm                  
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate_pack.vhd"                           -work sgate                
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.vhd"                                -work sgate                
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf_components.vhd"                 -work altera_mf            
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.vhd"                            -work altera_mf            
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                          -work altera_lnsim         
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim_components.vhd"              -work altera_lnsim         
  ncvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cadence/stratixv_atoms_ncrypt.v"          -work stratixv             
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_atoms.vhd"                       -work stratixv             
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_components.vhd"                  -work stratixv             
  ncvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cadence/stratixv_hssi_atoms_ncrypt.v"     -work stratixv_hssi        
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_components.vhd"             -work stratixv_hssi        
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_atoms.vhd"                  -work stratixv_hssi        
  ncvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cadence/stratixv_pcie_hip_atoms_ncrypt.v" -work stratixv_pcie_hip    
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_components.vhd"         -work stratixv_pcie_hip    
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_atoms.vhd"              -work stratixv_pcie_hip    
fi

# ----------------------------------------
# compile design files in correct order
if [ $SKIP_COM -eq 0 ]; then
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_functions.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_custom.sv"                   -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_custom_nr.sv"                    -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_custom_native.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_resync.sv"                      -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_common_h.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_common.sv"                  -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_pcs8g_h.sv"                 -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_pcs8g.sv"                   -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_selector.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_mgmt2dec.sv"                    -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_wait_generate.v"                  -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_pcs.sv"                               -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_pcs_ch.sv"                            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_pma.sv"                               -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_to_xcvr.sv"           -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_to_ip.sv"             -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_merger.sv"            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_rx_pma.sv"                            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_tx_pma.sv"                            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_tx_pma_ch.sv"                         -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_h.sv"                            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_avmm_csr.sv"                     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_avmm_dcd.sv"                     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_avmm.sv"                         -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_data_adapter.sv"                 -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_native.sv"                       -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_plls.sv"                         -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_10g_rx_pcs_rbc.sv"               -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_10g_tx_pcs_rbc.sv"               -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_8g_rx_pcs_rbc.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_8g_tx_pcs_rbc.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_8g_pcs_aggregate_rbc.sv"         -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_common_pcs_pma_interface_rbc.sv" -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_common_pld_pcs_interface_rbc.sv" -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_pipe_gen1_2_rbc.sv"              -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_pipe_gen3_rbc.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_rx_pcs_pma_interface_rbc.sv"     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_rx_pld_pcs_interface_rbc.sv"     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_tx_pcs_pma_interface_rbc.sv"     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_tx_pld_pcs_interface_rbc.sv"     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_reset_control.sv"            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_reset_counter.sv"               -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_arbiter.sv"                     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_m2s.sv"                         -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvhdl -v93 $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS   "$QSYS_SIMDIR/sfpp_phy.vhd"                                                                                                     
fi

# ----------------------------------------
# elaborate top level design
if [ $SKIP_ELAB -eq 0 ]; then
  export GENERIC_PARAM_COMPAT_CHECK=1
  ncelab -access +w+r+c -namemap_mixgen -relax $ELAB_OPTIONS $USER_DEFINED_ELAB_OPTIONS $TOP_LEVEL_NAME
fi

# ----------------------------------------
# simulate
if [ $SKIP_SIM -eq 0 ]; then
  eval ncsim -licqueue $SIM_OPTIONS $USER_DEFINED_SIM_OPTIONS $TOP_LEVEL_NAME
fi
