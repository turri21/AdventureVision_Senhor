-------------------------------------------------------------------------------
--
-- FPGA Adventure Vision
--
-- $Id: av_disp.vhd,v 1.9 2006/04/02 18:37:59 arnim Exp $
--
-- Display PCB
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

entity av_disp is

  port (
    -- System Interface -------------------------------------------------------
    clk_11m_i        : in  std_logic;
    por_n_i          : in  std_logic;
    -- Display Interface ------------------------------------------------------
    disp_d_i         : in  std_logic_vector( 7 downto 0);
    disp_p24_n_i     : in  std_logic;
    disp_rd_n_i      : in  std_logic;
    disp_p2_i        : in  std_logic_vector( 7 downto 5);
    disp_reset_clk_o : out std_logic;
    disp_photo_int_o : out std_logic;
    -- LED Interface ----------------------------------------------------------
    led_n_o          : out std_logic_vector(39 downto 0)
  );

end av_disp;


library ieee;
use ieee.numeric_std.all;

architecture rtl of av_disp is

  constant mirror_cnt_width_c   : natural :=    24;
  -- interruptor closed time: 200 us
  constant interruptor_reload_c : natural :=  2220;
  -- mirror rotation time from : 66.67 ms - interruptor closed time
  constant mirror_rot_reload_c  : natural := 739918 -
                                             interruptor_reload_c;

  signal mirror_cnt_q         : unsigned(mirror_cnt_width_c-1 downto 0);
  signal interruptor_closed_q : std_logic;
  signal disp_photo_int_s     : std_logic;

  signal led_pre_n_q,
         led_n_q              : std_logic_vector(39 downto 0);

  signal p24_n_q              : std_logic;

begin

  -----------------------------------------------------------------------------
  -- Process mirror
  --
  -- Purpose:
  --   Implements the counter that emulates the rotating mirror.
  --
  mirror: process (clk_11m_i, por_n_i)
  begin
    if por_n_i = '0' then
      mirror_cnt_q           <= to_unsigned(mirror_rot_reload_c,
                                            mirror_cnt_width_c);
      interruptor_closed_q   <= '0';

    elsif clk_11m_i'event and clk_11m_i = '1' then
      if mirror_cnt_q = 0 then
        if interruptor_closed_q = '0' then
          -- mirror moved to position where interruptor will be closed
          -- time closing phase
          mirror_cnt_q       <= to_unsigned(interruptor_reload_c,
                                            mirror_cnt_width_c);
        else
          -- mirror moved out of interruptor
          mirror_cnt_q       <= to_unsigned(mirror_rot_reload_c,
                                            mirror_cnt_width_c);
        end if;

        -- flip interruptor
        interruptor_closed_q <= not interruptor_closed_q;

      else
        mirror_cnt_q         <= mirror_cnt_q - 1;
      end if;

    end if;
  end process mirror;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process leds
  --
  -- Purpose:
  --   Implements the registers for saving the LED data.
  --   Data is stored in two steps:
  --     a) sequential write to led_pre_q
  --     b) full parallel update to led_q
  --
  --  Note that the LED signals are active low. I.e. LEDs are lit when control
  --  signals are pulled to GND.
  --
  leds: process (clk_11m_i, por_n_i)
  begin
    if por_n_i = '0' then
      led_pre_n_q <= (others => '1');
      led_n_q     <= (others => '1');
      p24_n_q     <= '0';

    elsif clk_11m_i'event and clk_11m_i = '1' then
      p24_n_q <= disp_p24_n_i;

      -- latch while /RD is active
      if disp_rd_n_i = '0'then
        case disp_p2_i is
          when "001" =>
            led_pre_n_q( 7 downto  0) <= disp_d_i;
          when "010" =>
            led_pre_n_q(15 downto  8) <= disp_d_i;
          when "011" =>
            led_pre_n_q(23 downto 16) <= disp_d_i;
          when "100" =>
            led_pre_n_q(31 downto 24) <= disp_d_i;
          when "101" =>
            led_pre_n_q(39 downto 32) <= disp_d_i;
          when others =>
            null;
        end case;
      end if;

      if interruptor_closed_q = '0' then
        -- detect falling edge on /P2.4
        if disp_p24_n_i = '0' and p24_n_q = '1' then
          -- update LEDs
          led_n_q <= led_pre_n_q;
        end if;

      else
        -- clear LEDs
        -- required for Super Cobra
        led_n_q <= (others => '1');
      end if;

    end if;
  end process leds;
  --
  disp_photo_int_s <= not interruptor_closed_q;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Output mapping
  -----------------------------------------------------------------------------
  disp_photo_int_o <= disp_photo_int_s;
  led_n_o          <= led_n_q;
  -- propagate /RD to reset flip-flop clock when P2 is set to C
  disp_reset_clk_o <=   disp_rd_n_i
                      when disp_p2_i = "110" else
                        '1';

end rtl;
