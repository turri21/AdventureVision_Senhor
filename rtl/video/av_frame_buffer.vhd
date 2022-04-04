-------------------------------------------------------------------------------
--
-- FPGA Adventure Vision
--
-- $Id: av_frame_buffer.vhd,v 1.6 2006/04/02 18:53:04 arnim Exp $
--
-- Framebuffer module
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

entity av_frame_buffer is

  port (
    -- System Interface -------------------------------------------------------
    clk_11m_i        : in  std_logic;
    por_n_i          : in  std_logic;
    -- Display Interface ------------------------------------------------------
    disp_photo_int_i : in  std_logic;
    led_n_i          : in  std_logic_vector(39 downto 0);
    -- Framebuffer Interface --------------------------------------------------
    fb_a_i           : in  std_logic_vector(12 downto 0);
    fb_d_o           : out std_logic;
    fb_sync_o        : out std_logic
  );

end av_frame_buffer;


library ieee;
use ieee.numeric_std.all;

use work.tech_comp_pack.generic_ram;

architecture rtl of av_frame_buffer is

  constant y_off_c : natural := 150;
  type     y_offset_t is array (natural range 39 downto 0) of natural;
  constant y_offset_c : y_offset_t := (
    00 * y_off_c, 01 * y_off_c, 02 * y_off_c, 03 * y_off_c, 04 * y_off_c,
    05 * y_off_c, 06 * y_off_c, 07 * y_off_c, 08 * y_off_c, 09 * y_off_c,
    10 * y_off_c, 11 * y_off_c, 12 * y_off_c, 13 * y_off_c, 14 * y_off_c,
    15 * y_off_c, 16 * y_off_c, 17 * y_off_c, 18 * y_off_c, 19 * y_off_c,
    20 * y_off_c, 21 * y_off_c, 22 * y_off_c, 23 * y_off_c, 24 * y_off_c,
    25 * y_off_c, 26 * y_off_c, 27 * y_off_c, 28 * y_off_c, 29 * y_off_c,
    30 * y_off_c, 31 * y_off_c, 32 * y_off_c, 33 * y_off_c, 34 * y_off_c,
    35 * y_off_c, 36 * y_off_c, 37 * y_off_c, 38 * y_off_c, 39 * y_off_c);

  signal cnt_x_q      : unsigned(7 downto 0);
  signal cnt_y_q      : unsigned(5 downto 0);

  subtype  cnt_capt_t           is unsigned(9 downto 0);
  signal   cnt_capt_q           : cnt_capt_t;
  -- times the first capture after photo interruptor trigger
  constant cnt_capt_photo_int_c : cnt_capt_t :=
                                  to_unsigned(798, cnt_capt_t'length);
  -- times each x position in a way that the slots 50 and 150
  -- do not result in a desynchronization
  -- slots 50 and 150 are 83us long instead of 60us, presumably due to
  -- switching the memory regions in the BIOS routine
  constant cnt_capt_scan_c      : cnt_capt_t :=
                                  to_unsigned(660, cnt_capt_t'length);

  signal photo_int_q  : std_logic;

  signal frame_q      : std_logic;

  type   scan_state_t is (IDLE, SCANNING);
  signal scan_state_q : scan_state_t;

  type   fb_a_t       is array (natural range 1 downto 0) of
                         std_logic_vector(12 downto 0);
  signal fb_a_s       : fb_a_t;
  signal fb_w_s       : std_logic_vector(1 downto 0);
  subtype fb_dbit_t   is std_logic_vector(0 downto 0);
  type    fb_d_t      is array (natural range 1 downto 0) of fb_dbit_t;
  signal fb_din_s     : fb_dbit_t;
  signal fb_dout_s    : fb_d_t;

  signal fb_sync_q    : std_logic_vector( 1 downto 0);

begin

  -----------------------------------------------------------------------------
  -- Process seq
  --
  -- Purpose:
  --   Implements the sequential control elements.
  --
  seq: process (clk_11m_i, por_n_i)
    variable photo_int_fall_v : boolean;
    variable cnt_x_at_150_v   : boolean;
    variable cnt_y_at_39_v    : boolean;
    variable cnt_capt_zero_v  : boolean;
  begin
    if por_n_i = '0' then
      cnt_x_q      <= (others => '0');
      cnt_y_q      <= (others => '0');
      photo_int_q  <= '1';
      frame_q      <= '0';
      scan_state_q <= IDLE;
      fb_sync_q    <= (others => '0');
      cnt_capt_q   <= cnt_capt_photo_int_c;

    elsif clk_11m_i'event and clk_11m_i = '1' then
      cnt_x_at_150_v   := cnt_x_q = 150;
      cnt_y_at_39_v    := cnt_y_q = 39;
      cnt_capt_zero_v  := cnt_capt_q = 0;
      -- edge detector
      photo_int_fall_v := disp_photo_int_i = '0' and photo_int_q = '1';

      photo_int_q      <= disp_photo_int_i;

      -- scan FSM
      case scan_state_q is
        when IDLE =>
          if cnt_capt_zero_v and not cnt_x_at_150_v then
            scan_state_q <= SCANNING;
          end if;

        when SCANNING =>
          -- stop scanning when last led is being saved
          -- or upon new sync
          if cnt_y_at_39_v or photo_int_fall_v then
            scan_state_q <= IDLE;
          end if;

        when others =>
          null;
      end case;

      -- x counter
      if    photo_int_fall_v then
        cnt_x_q <= (others => '0');
      elsif cnt_y_at_39_v and not cnt_x_at_150_v then
        cnt_x_q <= cnt_x_q + 1;
      end if;

      -- edge detection for frame sync
      if cnt_x_at_150_v then
        fb_sync_q(0)   <= '1';

        if fb_sync_q(0) = '0' then
          fb_sync_q(1) <= '1';
        else
          fb_sync_q(1) <= '0';
        end if;

      else
        fb_sync_q(0)   <= '0';
        fb_sync_q(1)   <= '0';
      end if;

      -- y counter
      if scan_state_q = SCANNING and
         not cnt_y_at_39_v then
        cnt_y_q <= cnt_y_q + 1;
      else
        cnt_y_q   <= (others => '0');
      end if;

      -- frame selector
      if fb_sync_q(1) = '1' then
        frame_q <= not frame_q;
      end if;

      -- capture counter
      if    disp_photo_int_i = '0' then
        cnt_capt_q <= cnt_capt_photo_int_c;
      elsif cnt_capt_zero_v then
        cnt_capt_q <= cnt_capt_scan_c;
      else
        cnt_capt_q <= cnt_capt_q - 1;
      end if;

    end if;
  end process seq;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process fb_ctrl
  --
  -- Purpose:
  --   Control logic for the framebuffers.
  --
  fb_ctrl: process (scan_state_q,
                    frame_q,
                    cnt_x_q, cnt_y_q,
                    fb_a_i,
                    fb_dout_s,
                    led_n_i)
    variable a_v : unsigned(12 downto 0);
    variable w_v : std_logic;
  begin
    -- calculate address for write
    a_v := "0" & "0000" & cnt_x_q + y_offset_c(to_integer(cnt_y_q));

    -- write whenever scan FSM is in state SCANNING
    if scan_state_q = SCANNING then
      w_v := '1';
    else
      w_v := '0';
    end if;

    -- MUX address, write enable and write data
    if frame_q = '0' then
      fb_a_s(0) <= std_logic_vector(a_v);
      fb_w_s(0) <= w_v;
      --
      fb_a_s(1) <= fb_a_i;
      fb_w_s(1) <= '0';
      --
      fb_d_o    <= fb_dout_s(1)(0);

    else
      fb_a_s(0) <= fb_a_i;
      fb_w_s(0) <= '0';
      --
      fb_a_s(1) <= std_logic_vector(a_v);
      fb_w_s(1) <= w_v;
      --
      fb_d_o    <= fb_dout_s(0)(0);

    end if;

    -- select framebuffer write data
    fb_din_s(0) <= not led_n_i(to_integer(cnt_y_q));

  end process fb_ctrl;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Framebuffer RAMs
  -----------------------------------------------------------------------------
  fbs: for idx in 0 to 1 generate
    fb_b : generic_ram
      generic map (
        addr_width_g => 13,
        data_width_g => 1
      )
      port map (
        clk_i => clk_11m_i,
        a_i   => fb_a_s(idx),
        we_i  => fb_w_s(idx),
        d_i   => fb_din_s,
        d_o   => fb_dout_s(idx)
      );
  end generate;


  -----------------------------------------------------------------------------
  -- Output mapping
  -----------------------------------------------------------------------------
  fb_sync_o <= fb_sync_q(1);

end rtl;
