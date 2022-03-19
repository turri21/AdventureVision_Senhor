-------------------------------------------------------------------------------
--
-- FPGA Adventure Vision
--
-- $Id: av_ctrl.vhd,v 1.7 2006/05/09 21:11:29 arnim Exp $
--
-- Controller PCB
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

entity av_ctrl is

  port (
    -- Control Interface ------------------------------------------------------
    ctrl_o      : out std_logic_vector(7 downto 3);
    -- Buttons and Stick Interface --------------------------------------------
    but_1_n_i   : in  std_logic;
    but_2_n_i   : in  std_logic;
    but_3_n_i   : in  std_logic;
    but_4_n_i   : in  std_logic;
    stick_l_n_i : in  std_logic;
    stick_r_n_i : in  std_logic;
    stick_u_n_i : in  std_logic;
    stick_d_n_i : in  std_logic;
    -- Sound Interface --------------------------------------------------------
    clk_11m_i   : in  std_logic;
    por_n_i     : in  std_logic;
    snd_res_n_i : in  std_logic;
    snd_p2_i    : in  std_logic_vector(7 downto 4);
    audio_o     : out std_logic_vector(1 downto 0)
  );

end av_ctrl;


library ieee;
use ieee.numeric_std.all;

use work.t400_opt_pack.all;
use work.t400_system_comp_pack.t410_notri;

architecture rtl of av_ctrl is

  signal io_l_s  : std_logic_vector(7 downto 0);
  signal io_d_s,
         io_g_s  : std_logic_vector(3 downto 0);

  signal clk_842k_en_s  : std_logic;
  signal clk_842k_cnt_q : unsigned(3 downto 0);

  signal gnd4_s  : std_logic_vector(3 downto 0);

begin

  gnd4_s <= (others => '0');

  -----------------------------------------------------------------------------
  -- COP411L sound controller
  -----------------------------------------------------------------------------
  io_l_s(7 downto 4) <= (others => '0');
  io_l_s(3 downto 0) <= snd_p2_i;
  --
  cop411_b : t410_notri
    generic map (
      opt_ck_div_g => t400_opt_ck_div_16_c
    )
    port map (
      ck_i      => clk_11m_i,
      ck_en_i   => clk_842k_en_s,
      reset_n_i => snd_res_n_i,
      cko_i     => gnd4_s(0),
      io_l_i    => io_l_s,
      io_l_o    => open,
      io_l_en_o => open,
      io_d_o    => io_d_s,
      io_d_en_o => open,
      io_g_i    => gnd4_s,
      io_g_o    => io_g_s,
      io_g_en_o => open,
      si_i      => gnd4_s(0),
      so_o      => open,
      so_en_o   => open,
      sk_o      => open,
      sk_en_o   => open
    );
  --
  audio_o(1) <= io_d_s(0);              -- 0 = high, 1 = low volume
  audio_o(0) <= io_g_s(0);              -- digital sound waveform


  -----------------------------------------------------------------------------
  -- Process clk_842
  --
  -- Purpose:
  --   Generates the 842 kHz clock for the COP411L.
  --
  clk_842: process (clk_11m_i, por_n_i)
  begin
    if por_n_i = '0' then
      clk_842k_cnt_q   <= to_unsigned(12, 4);
    elsif clk_11m_i'event and clk_11m_i = '1' then
      if clk_842k_en_s = '1' then
        clk_842k_cnt_q <= to_unsigned(12, 4);
      else
        clk_842k_cnt_q <= clk_842k_cnt_q - 1;
      end if;
    end if;
  end process clk_842;
  --
  clk_842k_en_s <=   '1'
                   when clk_842k_cnt_q = 0 else
                     '0';
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process ctrl
  --
  -- Purpose:
  --   Encodes the button and stick inputs to the control bus.
  --
  ctrl: process (but_1_n_i,   but_2_n_i,   but_3_n_i,   but_4_n_i,
                 stick_l_n_i, stick_r_n_i, stick_u_n_i, stick_d_n_i)
    variable ctrl_v : std_logic_vector(7 downto 3);
  begin
    ctrl_v      := (others => '1');

    if but_1_n_i = '0' then
      ctrl_v(5) := '0';
      ctrl_v(4) := '0';
    end if;
    if but_2_n_i = '0' then
      ctrl_v(6) := '0';
      ctrl_v(4) := '0';
    end if;
    if but_3_n_i = '0' then
      ctrl_v(3) := '0';
    end if;
    if but_4_n_i = '0' then
      ctrl_v(7) := '0';
      ctrl_v(4) := '0';
    end if;

    -- priority encoder required here
    -- joystick is only 4-way, positions NW, NE, SW and SE do not exist
    if    stick_l_n_i = '0' then
      ctrl_v(7) := '0';
    elsif stick_r_n_i = '0' then
      ctrl_v(6) := '0';
    elsif stick_u_n_i = '0' then
      ctrl_v(5) := '0';
    elsif stick_d_n_i = '0' then
      ctrl_v(4) := '0';
    end if;

    ctrl_o      <= ctrl_v;
  end process ctrl;
  --
  -----------------------------------------------------------------------------

end rtl;
