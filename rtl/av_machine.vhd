-------------------------------------------------------------------------------
--
-- FPGA Adventure Vision
--
-- $Id: av_machine.vhd,v 1.6 2006/05/06 23:40:56 arnim Exp $
--
-- Toplevel of the Adventure Vision console
--
-- References:
--
--   * AdventureVision.com
--     The comprehensive source of information
--
--   * Dan Boris' technical resources of the Adventure Vision
--     http://www.atarihq.com/danb/adventurevision.shtml
--
--   * PCB Schematics, same source
--     http://www.atarihq.com/danb/files/AvSchematic.pdf
--
--   * Technical manual, same source
--     http://www.atarihq.com/danb/files/AvTechSpecs.pdf
--
-------------------------------------------------------------------------------
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity av_machine is

  port (
    -- System Interface -------------------------------------------------------
    clk_11m_i         : in  std_logic;
    reset_n_i         : in  std_logic;
    por_n_o           : out std_logic;
    -- Cartridge Interface ----------------------------------------------------
    cart_a_o          : out std_logic_vector(11 downto 0);
    cart_oe_n_o       : out std_logic;
    cart_d_i          : in  std_logic_vector( 7 downto 0);
    -- Buttons and Stick Interface --------------------------------------------
    but_1_n_i         : in  std_logic;
    but_2_n_i         : in  std_logic;
    but_3_n_i         : in  std_logic;
    but_4_n_i         : in  std_logic;
    stick_l_n_i       : in  std_logic;
    stick_r_n_i       : in  std_logic;
    stick_u_n_i       : in  std_logic;
    stick_d_n_i       : in  std_logic;
    -- Sound Interface --------------------------------------------------------
    audio_o           : out std_logic_vector( 1 downto 0);
    -- Display Interface ------------------------------------------------------
    led_n_o           : out std_logic_vector(39 downto 0);
    disp_p24_n_o      : out std_logic;
    disp_photo_int_o  : out std_logic;
    -- Expansion Interface ----------------------------------------------------
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

end av_machine;


use work.av_comp_pack.av_main;
use work.av_comp_pack.av_ctrl;
use work.av_comp_pack.av_disp;

architecture struct of av_machine is

  -- System connections
  signal por_n_s          : std_logic;

  -- Control connections
  signal ctrl_s           : std_logic_vector(7 downto 3);

  -- Sound connections
  signal snd_res_n_s      : std_logic;
  signal snd_p2_s         : std_logic_vector(7 downto 4);

  -- Display connections
  signal disp_d_s         : std_logic_vector(7 downto 0);
  signal disp_p24_n_s     : std_logic;
  signal disp_rd_n_s      : std_logic;
  signal disp_p2_s        : std_logic_vector(7 downto 5);
  signal disp_reset_clk_s : std_logic;
  signal disp_photo_int_s : std_logic;

begin

  -----------------------------------------------------------------------------
  -- Main PCB
  -----------------------------------------------------------------------------
  main_b : av_main
    port map (
      clk_11m_i         => clk_11m_i,
      reset_n_i         => reset_n_i,
      por_n_o           => por_n_s,
      cart_a_o          => cart_a_o,
      cart_oe_n_o       => cart_oe_n_o,
      cart_d_i          => cart_d_i,
      ctrl_i            => ctrl_s,
      snd_res_n_o       => snd_res_n_s,
      snd_p2_o          => snd_p2_s,
      disp_d_o          => disp_d_s,
      disp_p24_n_o      => disp_p24_n_s,
      disp_rd_n_o       => disp_rd_n_s,
      disp_p2_o         => disp_p2_s,
      disp_reset_clk_i  => disp_reset_clk_s,
      disp_photo_int_i  => disp_photo_int_s,
      exp_t0_i          => exp_t0_i,
      exp_t0_o          => exp_t0_o,
      exp_t0_dir_o      => exp_t0_dir_o,
      exp_rd_n_o        => exp_rd_n_o,
      exp_psen_n_o      => exp_psen_n_o,
      exp_wr_n_o        => exp_wr_n_o,
      exp_ale_o         => exp_ale_o,
      exp_d_i           => exp_d_i,
      exp_d_o           => exp_d_o,
      exp_p1_i          => exp_p1_i,
      exp_p1_o          => exp_p1_o,
      exp_p1_low_imp_o  => exp_p1_low_imp_o,
      exp_p2_i          => exp_p2_i,
      exp_p2_o          => exp_p2_o,
      exp_p2l_low_imp_o => exp_p2l_low_imp_o,
      exp_p2h_low_imp_o => exp_p2h_low_imp_o,
      exp_prog_n_o      => exp_prog_n_o
    );


  -----------------------------------------------------------------------------
  -- Controller PCB
  -----------------------------------------------------------------------------
  ctrl_b : av_ctrl
    port map (
      ctrl_o      => ctrl_s,
      but_1_n_i   => but_1_n_i,
      but_2_n_i   => but_2_n_i,
      but_3_n_i   => but_3_n_i,
      but_4_n_i   => but_4_n_i,
      stick_l_n_i => stick_l_n_i,
      stick_r_n_i => stick_r_n_i,
      stick_u_n_i => stick_u_n_i,
      stick_d_n_i => stick_d_n_i,
      clk_11m_i   => clk_11m_i,
      por_n_i     => por_n_s,
      snd_res_n_i => snd_res_n_s,
      snd_p2_i    => snd_p2_s,
      audio_o     => audio_o
    );


  -----------------------------------------------------------------------------
  -- Display PCB
  -----------------------------------------------------------------------------
  disp_b : av_disp
    port map (
      clk_11m_i        => clk_11m_i,
      por_n_i          => por_n_s,
      disp_d_i         => disp_d_s,
      disp_p24_n_i     => disp_p24_n_s,
      disp_rd_n_i      => disp_rd_n_s,
      disp_p2_i        => disp_p2_s,
      disp_reset_clk_o => disp_reset_clk_s,
      disp_photo_int_o => disp_photo_int_s,
      led_n_o          => led_n_o
    );


  -----------------------------------------------------------------------------
  -- Output mapping
  -----------------------------------------------------------------------------
  por_n_o          <= por_n_s;
  disp_p24_n_o     <= disp_p24_n_s;
  disp_photo_int_o <= disp_photo_int_s;

end struct;
