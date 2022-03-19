-------------------------------------------------------------------------------
--
-- FPGA Adventure Vision
--
-- $Id: av_main.vhd,v 1.14 2006/05/13 14:54:55 arnim Exp $
--
-- Main PCB
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

entity av_main is

  port (
    -- System Interface -------------------------------------------------------
    clk_11m_i         : in  std_logic;
    reset_n_i         : in  std_logic;
    por_n_o           : out  std_logic;
    -- Cartridge Interface ----------------------------------------------------
    cart_a_o          : out std_logic_vector(11 downto 0);
    cart_oe_n_o       : out std_logic;
    cart_d_i          : in  std_logic_vector( 7 downto 0);
    -- Controller Interface ---------------------------------------------------
    ctrl_i            : in  std_logic_vector( 7 downto 3);
    -- Sound Interface --------------------------------------------------------
    snd_res_n_o       : out std_logic;
    snd_p2_o          : out std_logic_vector( 7 downto 4);
    -- Display Interface ------------------------------------------------------
    disp_d_o          : out std_logic_vector( 7 downto 0);
    disp_p24_n_o      : out std_logic;
    disp_rd_n_o       : out std_logic;
    disp_p2_o         : out std_logic_vector( 7 downto 5);
    disp_reset_clk_i  : in  std_logic;
    disp_photo_int_i  : in  std_logic;
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

end av_main;


use work.tech_comp_pack.av_por;
use work.t48_system_comp_pack.t8048_notri;
use work.tech_comp_pack.generic_ram;

architecture struct of av_main is

  -- System connections
  signal por_n_s       : std_logic;
  signal reset_n_s     : std_logic;
  signal a_q           : std_logic_vector(7 downto 0);

  -- T48 connections
  signal ale_s         : std_logic;
  signal rd_n_s,
         wr_n_s        : std_logic;
  signal psen_n_s      : std_logic;
  signal db_to_t48_s,
         db_from_t48_s : std_logic_vector(7 downto 0);
  signal db_dir_s      : std_logic;
  signal t1_s          : std_logic;
  signal p1_to_t48_s,
         p1_from_t48_s : std_logic_vector(7 downto 0);
  signal p2_to_t48_s,
         p2_from_t48_s : std_logic_vector(7 downto 0);

  -- RAM connections
  signal ram_we_s      : std_logic;
  signal d_ram_s,
         d_from_ram_s  : std_logic_vector(7 downto 0);
  signal ram_a_s       : std_logic_vector(9 downto 0);

  signal d_from_cart_s : std_logic_vector(7 downto 0);

  signal disp_enable_s : std_logic;

  signal db0_q         : std_logic;
  signal disp_reset_clk_q : std_logic;
  signal snd_res_n_q   : std_logic;

  signal vdd_s         : std_logic;

begin

  vdd_s <= '1';

  -----------------------------------------------------------------------------
  -- Power-on reset circuit
  -- Reset active for at most 28.5 ms.
  -- The power-on reset time is calculated from the RC element present at
  -- the reset pin of the 8048:
  --   C = 1 uF, R = 20 kOhm (estimated from pin input leakage I_LI2)
  --   V_IH = 3.8 V
  -----------------------------------------------------------------------------
  por_b : av_por
    generic map (
      delay_g     => 6315,
      cnt_width_g => 19
    )
    port map (
      clk_i   => clk_11m_i,
      por_n_o => por_n_s
    );
  por_n_o   <= por_n_s;
  reset_n_s <= reset_n_i and por_n_s;


  -----------------------------------------------------------------------------
  -- T48 uController in 8048 flavour without tri-states
  -----------------------------------------------------------------------------
  t8048_notri_b : t8048_notri
    generic map (
      gate_port_input_g => 1
    )
    port map (
      xtal_i        => clk_11m_i,
      reset_n_i     => reset_n_s,
      t0_i          => exp_t0_i,
      t0_o          => exp_t0_o,
      t0_dir_o      => exp_t0_dir_o,
      int_n_i       => vdd_s,
      ea_i          => p1_from_t48_s(2),
      rd_n_o        => rd_n_s,
      psen_n_o      => psen_n_s,
      wr_n_o        => wr_n_s,
      ale_o         => ale_s,
      db_i          => db_to_t48_s,
      db_o          => db_from_t48_s,
      db_dir_o      => db_dir_s,
      t1_i          => t1_s,
      p2_i          => p2_to_t48_s,
      p2_o          => p2_from_t48_s,
      p2l_low_imp_o => exp_p2l_low_imp_o,
      p2h_low_imp_o => exp_p2h_low_imp_o,
      p1_i          => p1_to_t48_s,
      p1_o          => p1_from_t48_s,
      p1_low_imp_o  => exp_p1_low_imp_o,
      prog_n_o      => exp_prog_n_o
    );

  -- build DB input bus
  db_to_t48_s             <= d_from_ram_s  and
                             d_from_cart_s and
                             exp_d_i;
  -- set bus from cartridge to inactive when cartridge is not selected
  d_from_cart_s           <=   cart_d_i
                             when psen_n_s = '0' else
                               (others => '1');

  -- build P1 input bus
  p1_to_t48_s(2 downto 0) <= (others => '1');
  p1_to_t48_s(7 downto 3) <= ctrl_i and exp_p1_i;

  -- build P2 input bus
  p2_to_t48_s(3 downto 0) <= exp_p2_i;
  p2_to_t48_s(7 downto 4) <= (others => '1');

  t1_s                    <= not disp_photo_int_i;


  -----------------------------------------------------------------------------
  -- Process alatch
  --
  -- Purpose:
  --   Implements the address latch.
  --
  alatch: process (clk_11m_i, por_n_s)
  begin
    if por_n_s = '0' then
      a_q   <= (others => '0');
    elsif clk_11m_i'event and clk_11m_i = '1' then
      if ale_s = '1' then
        a_q <= db_from_t48_s;
      end if;
    end if;
  end process alatch;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- External RAM
  -----------------------------------------------------------------------------
  ram_we_s <= not wr_n_s;
  ram_a_s  <= p1_from_t48_s(1) & p1_from_t48_s(0) &
              a_q;
  --
  ext_ram_b : generic_ram
    generic map (
      addr_width_g => 10,
      data_width_g => 8
    )
    port map (
      clk_i => clk_11m_i,
      a_i   => ram_a_s,
      we_i  => ram_we_s,
      d_i   => db_from_t48_s,
      d_o   => d_ram_s
    );
  -- set bus from RAM to inactive state when RAM is not selected
  d_from_ram_s <=   d_ram_s
                  when rd_n_s = '0' else
                    (others => '1');


  -----------------------------------------------------------------------------
  -- Display disabled for at most 240 ms.
  -- The disable time is calculated from the RC element present at
  -- pin 2 of the 74LS00:
  --   C = 47 uF, R = 10 kOhm
  --   V_IH = 2 V
  -----------------------------------------------------------------------------
  disp_en_b : av_por
    generic map (
      delay_g     => 3706,
      cnt_width_g => 26
    )
    port map (
      clk_i   => clk_11m_i,
      por_n_o => disp_enable_s
    );


  -----------------------------------------------------------------------------
  -- Process db_reg
  --
  -- Purpose:
  --   Saves DB(0) when DB is written to by MOVX.
  --
  db_reg: process (clk_11m_i, por_n_s)
  begin
    if por_n_s = '0' then
      db0_q   <= '0';
    elsif clk_11m_i'event and clk_11m_i = '1' then
      if wr_n_s = '0' then
        db0_q <= db_from_t48_s(0);
      end if;
    end if;
  end process db_reg;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process snd_res
  --
  -- Purpose:
  --   Implements the flip-flop for resetting the COP411L sound controller.
  --
  snd_res: process (clk_11m_i, por_n_s)
  begin
    if por_n_s = '0' then
      disp_reset_clk_q <= '0';
      snd_res_n_q      <= '0';
    elsif clk_11m_i'event and clk_11m_i = '1' then
      disp_reset_clk_q <= disp_reset_clk_i;
      if disp_reset_clk_i = '1' and disp_reset_clk_q = '0' then
        snd_res_n_q    <= db0_q;
      end if;
    end if;
  end process snd_res;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Output mapping
  -----------------------------------------------------------------------------
  -- Sound Interface
  snd_res_n_o  <= snd_res_n_q;
  snd_p2_o     <= p2_from_t48_s(7 downto 4);
  -- Cartridge Interface
  cart_a_o     <= p2_from_t48_s(3) & p2_from_t48_s(2) &
                  p2_from_t48_s(1) & p2_from_t48_s(0) &
                  a_q;
  cart_oe_n_o  <= psen_n_s;
  -- Display Interface
  disp_d_o     <= db_to_t48_s;
  disp_p24_n_o <= disp_enable_s nand p2_from_t48_s(4);
  disp_rd_n_o  <= rd_n_s;
  disp_p2_o    <= p2_from_t48_s(7 downto 5);
  -- Expansion Interface
  exp_rd_n_o   <= rd_n_s;
  exp_psen_n_o <= psen_n_s;
  exp_wr_n_o   <= wr_n_s;
  exp_ale_o    <= ale_s;
  exp_d_o      <= db_from_t48_s;
  exp_p1_o     <= p1_from_t48_s(7 downto 3);
  exp_p2_o     <= p2_from_t48_s(3 downto 0);

end struct;
