-------------------------------------------------------------------------------
--
-- FPGA Adventure Vision
--
-- $Id: av_comp_pack-p.vhd,v 1.12 2006/05/06 23:40:56 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package av_comp_pack is

  component av_main
    port (
      -- System Interface -----------------------------------------------------
      clk_11m_i         : in  std_logic;
      reset_n_i         : in  std_logic;
      por_n_o           : out  std_logic;
      -- Cartridge Interface --------------------------------------------------
      cart_a_o          : out std_logic_vector(11 downto 0);
      cart_oe_n_o       : out std_logic;
      cart_d_i          : in  std_logic_vector( 7 downto 0);
      -- Controller Interface -------------------------------------------------
      ctrl_i            : in  std_logic_vector( 7 downto 3);
      -- Sound Interface ------------------------------------------------------
      snd_res_n_o       : out std_logic;
      snd_p2_o          : out std_logic_vector( 7 downto 4);
      -- Display Interface ----------------------------------------------------
      disp_d_o          : out std_logic_vector( 7 downto 0);
      disp_p24_n_o      : out std_logic;
      disp_rd_n_o       : out std_logic;
      disp_p2_o         : out std_logic_vector( 7 downto 5);
      disp_reset_clk_i  : in  std_logic;
      disp_photo_int_i  : in  std_logic;
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

  component av_ctrl
    port (
      -- Control Interface ----------------------------------------------------
      ctrl_o      : out std_logic_vector(7 downto 3);
      -- Buttons and Stick Interface ------------------------------------------
      but_1_n_i   : in  std_logic;
      but_2_n_i   : in  std_logic;
      but_3_n_i   : in  std_logic;
      but_4_n_i   : in  std_logic;
      stick_l_n_i : in  std_logic;
      stick_r_n_i : in  std_logic;
      stick_u_n_i : in  std_logic;
      stick_d_n_i : in  std_logic;
      -- Sound Interface ------------------------------------------------------
      clk_11m_i   : in  std_logic;
      por_n_i     : in  std_logic;
      snd_res_n_i : in  std_logic;
      snd_p2_i    : in  std_logic_vector(7 downto 4);
      audio_o     : out std_logic_vector(1 downto 0)
    );
  end component;

  component av_disp
    port (
      -- System Interface -----------------------------------------------------
      clk_11m_i        : in  std_logic;
      por_n_i          : in  std_logic;
      -- Display Interface ----------------------------------------------------
      disp_d_i         : in  std_logic_vector( 7 downto 0);
      disp_p24_n_i     : in  std_logic;
      disp_rd_n_i      : in  std_logic;
      disp_p2_i        : in  std_logic_vector( 7 downto 5);
      disp_reset_clk_o : out std_logic;
      disp_photo_int_o : out std_logic;
      -- LED Interface --------------------------------------------------------
      led_n_o          : out std_logic_vector(39 downto 0)
    );
  end component;

end av_comp_pack;
