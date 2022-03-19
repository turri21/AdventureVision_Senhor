-------------------------------------------------------------------------------
--
-- FPGA Adventure Vision
--
-- $Id: av_machine_comp_pack-p.vhd,v 1.5 2006/04/02 18:51:11 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package av_machine_comp_pack is

  component av_machine
    port (
      -- System Interface -----------------------------------------------------
      clk_11m_i         : in  std_logic;
      reset_n_i         : in  std_logic;
      por_n_o           : out std_logic;
      -- Cartridge Interface --------------------------------------------------
      cart_a_o          : out std_logic_vector(11 downto 0);
      cart_oe_n_o       : out std_logic;
      cart_d_i          : in  std_logic_vector( 7 downto 0);
      -- Buttons and Stick Interface ------------------------------------------
      but_1_n_i         : in  std_logic;
      but_2_n_i         : in  std_logic;
      but_3_n_i         : in  std_logic;
      but_4_n_i         : in  std_logic;
      stick_l_n_i       : in  std_logic;
      stick_r_n_i       : in  std_logic;
      stick_u_n_i       : in  std_logic;
      stick_d_n_i       : in  std_logic;
      -- Sound Interface ------------------------------------------------------
      audio_o           : out std_logic_vector( 1 downto 0);
      -- Display Interface ----------------------------------------------------
      led_n_o           : out std_logic_vector(39 downto 0);
      disp_p24_n_o      : out std_logic;
      disp_photo_int_o  : out std_logic;
      -- Expansion Interface --------------------------------------------------
      exp_t0_i          : in  std_logic;
      exp_t0_o          : out std_logic;
      exp_t0_dir_o      : out std_logic;
      exp_rd_n_o        : out std_logic;
      exp_psen_n_o      : out std_logic;
      exp_wr_n_o        : out std_logic;
      exp_ale_o         : out std_logic;
      exp_d_i           : in  std_logic_vector( 7 downto 0);
      exp_d_o           : out std_logic_vector( 7 downto 0);
      exp_p1_i          : in  std_logic_vector( 7 downto 3);
      exp_p1_o          : out std_logic_vector( 7 downto 3);
      exp_p1_low_imp_o  : out std_logic;
      exp_p2_i          : in  std_logic_vector( 3 downto 0);
      exp_p2_o          : out std_logic_vector( 3 downto 0);
      exp_p2l_low_imp_o : out std_logic;
      exp_p2h_low_imp_o : out std_logic;
      exp_prog_n_o      : out std_logic
    );
  end component;

end av_machine_comp_pack;
