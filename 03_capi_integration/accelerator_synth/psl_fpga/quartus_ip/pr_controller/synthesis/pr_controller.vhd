-- pr_controller.vhd

-- Generated using ACDS version 13.1 162 at 2014.08.27.09:44:37

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pr_controller is
	port (
		alt_pr_0_pr_start_pr_start     : in  std_logic                     := '0';             --   alt_pr_0_pr_start.pr_start
		alt_pr_0_double_pr_double_pr   : in  std_logic                     := '0';             --  alt_pr_0_double_pr.double_pr
		alt_pr_0_data_valid_data_valid : in  std_logic                     := '0';             -- alt_pr_0_data_valid.data_valid
		alt_pr_0_freeze_freeze         : out std_logic;                                        --     alt_pr_0_freeze.freeze
		alt_pr_0_data_data             : in  std_logic_vector(31 downto 0) := (others => '0'); --       alt_pr_0_data.data
		alt_pr_0_data_read_data_read   : out std_logic;                                        --  alt_pr_0_data_read.data_read
		alt_pr_0_status_status         : out std_logic_vector(1 downto 0);                     --     alt_pr_0_status.status
		alt_pr_0_clk_clk               : in  std_logic                     := '0';             --        alt_pr_0_clk.clk
		alt_pr_0_nreset_reset          : in  std_logic                     := '0'              --     alt_pr_0_nreset.reset
	);
end entity pr_controller;

architecture rtl of pr_controller is
	component alt_pr is
		generic (
			PR_INTERNAL_HOST  : boolean := true;
			ENABLE_JTAG       : boolean := true;
			DATA_WIDTH_INDEX  : integer := 16;
			CDRATIO           : integer := 1;
			EDCRC_OSC_DIVIDER : integer := 1;
			UNIQUE_IDENTIFIER : integer := 2013;
			DEVICE_FAMILY     : string  := ""
		);
		port (
			clk            : in  std_logic                     := 'X';             -- clk
			nreset         : in  std_logic                     := 'X';             -- reset
			pr_start       : in  std_logic                     := 'X';             -- pr_start
			double_pr      : in  std_logic                     := 'X';             -- double_pr
			data_valid     : in  std_logic                     := 'X';             -- data_valid
			data           : in  std_logic_vector(31 downto 0) := (others => 'X'); -- data
			freeze         : out std_logic;                                        -- freeze
			data_read      : out std_logic;                                        -- data_read
			status         : out std_logic_vector(1 downto 0);                     -- status
			pr_ready_pin   : in  std_logic                     := 'X';             -- pr_ready_pin
			pr_done_pin    : in  std_logic                     := 'X';             -- pr_done_pin
			pr_error_pin   : in  std_logic                     := 'X';             -- pr_error_pin
			crc_error_pin  : in  std_logic                     := 'X';             -- crc_error_pin
			pr_request_pin : out std_logic;                                        -- pr_request_pin
			pr_clk_pin     : out std_logic;                                        -- pr_clk_pin
			pr_data_pin    : out std_logic_vector(15 downto 0)                     -- pr_data_pin
		);
	end component alt_pr;

begin

	alt_pr_0 : component alt_pr
		generic map (
			PR_INTERNAL_HOST  => true,
			ENABLE_JTAG       => true,
			DATA_WIDTH_INDEX  => 32,
			CDRATIO           => 1,
			EDCRC_OSC_DIVIDER => 1,
			UNIQUE_IDENTIFIER => 29464078,
			DEVICE_FAMILY     => "Stratix V"
		)
		port map (
			clk            => alt_pr_0_clk_clk,               --        clk.clk
			nreset         => alt_pr_0_nreset_reset,          --     nreset.reset
			pr_start       => alt_pr_0_pr_start_pr_start,     --   pr_start.pr_start
			double_pr      => alt_pr_0_double_pr_double_pr,   --  double_pr.double_pr
			data_valid     => alt_pr_0_data_valid_data_valid, -- data_valid.data_valid
			data           => alt_pr_0_data_data,             --       data.data
			freeze         => alt_pr_0_freeze_freeze,         --     freeze.freeze
			data_read      => alt_pr_0_data_read_data_read,   --  data_read.data_read
			status         => alt_pr_0_status_status,         --     status.status
			pr_ready_pin   => '0',                            -- (terminated)
			pr_done_pin    => '0',                            -- (terminated)
			pr_error_pin   => '0',                            -- (terminated)
			crc_error_pin  => '0',                            -- (terminated)
			pr_request_pin => open,                           -- (terminated)
			pr_clk_pin     => open,                           -- (terminated)
			pr_data_pin    => open                            -- (terminated)
		);

end architecture rtl; -- of pr_controller
