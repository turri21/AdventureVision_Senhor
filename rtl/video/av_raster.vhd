-------------------------------------------------------------------------------
--
-- FPGA Adventure Vision
--
-- $Id: av_raster.vhd,v 1.5 2006/04/02 18:53:04 arnim Exp $
--
-- Rasterizer module
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

entity av_raster is

  generic (
    is_pal_g      : integer := 0
  );
  port (
    -- System Interface -------------------------------------------------------
    clk_11m_i     : in  std_logic;
    por_n_i       : in  std_logic;
    -- Framebuffer Interface --------------------------------------------------
    fb_a_o        : out std_logic_vector(12 downto 0);
    fb_d_i        : in  std_logic;
    fb_sync_i     : in  std_logic;
    -- RGB Video Interface ----------------------------------------------------
    rgb_r_o       : out std_logic_vector( 2 downto 0);
    rgb_hsync_n_o : out std_logic;
    rgb_vsync_n_o : out std_logic;
    rgb_csync_n_o : out std_logic;
    vblank        : out std_logic;
    hblank        : out std_logic;
    -- Core Options -----------------------------------------------------------
    fixed_intensity: in  std_logic
  );

end av_raster;


library ieee;
use ieee.numeric_std.all;

architecture rtl of av_raster is

  -- horizontal prescaler
  subtype  hprescal_t is unsigned(1 downto 0);
  constant hprescal_reload_c : hprescal_t := to_unsigned(2, hprescal_t'length);
  signal   hprescal_q        : hprescal_t;
  signal   hprescal_zero_s   : boolean;

  -- vertical prescaler
  subtype  vprescal_t is unsigned(1 downto 0);
  constant vprescal_reload_c : vprescal_t := to_unsigned(2, vprescal_t'length);
  signal   vprescal_q        : vprescal_t;
  signal   vprescal_zero_s   : boolean;

  -- Horizontal video timing --------------------------------------------------
  --
  subtype hcnt_t          is signed(7+1 downto 0);
  signal  hcnt_q          : hcnt_t;
  signal  hcnt_at_start_q : boolean;
  --
  -- start value for horizontal counter
  signal  hstart_s        : hcnt_t;
  -- end of horizontal sync
  signal  hsync_end_s     : hcnt_t;
  -- start of active area
  signal  hstart_active_s : hcnt_t;
  -- last pixel of active area
  signal  hlast_active_s  : hcnt_t;
  -- last pixel of front porch
  signal  hlast_pixel_s   : hcnt_t;

  -- Vertical video timing ----------------------------------------------------
  --
  subtype vcnt_t          is signed(6+1 downto 0);
  signal  vcnt_q          : vcnt_t;
  signal  vcnt_pix_q      : unsigned(12 downto 0);
  --
  -- start value for vertical counter
  signal  vstart_s        : vcnt_t;
  -- end of vertical sync
  signal  vsync_end_s     : vcnt_t;
  -- start of active area
  signal  vstart_active_s : vcnt_t;
  -- last display line of active area
  signal  vlast_active_s  : vcnt_t;
  -- last display line of front porch
  signal  vlast_line_s    : vcnt_t;

  signal hsync_n_q,
         vsync_n_q        : std_logic;
  signal active_display_q : boolean;

  signal vblank_en        : std_logic;
  signal hblank_en        : std_logic;

  signal frame_cnt_q      : unsigned(2 downto 0);
  signal frame_sync_q     : boolean;

  signal rgb_r_q          : unsigned(2 downto 0);

begin

  -----------------------------------------------------------------------------
  -- Timing values for NTSC (525/60)
  --
  -- 525 scanlines, 483 visible
  -----------------------------------------------------------------------------
  ntsc: if is_pal_g = 0 generate
    -- start value for horizontal counter:
    --   10.5 us + 20 pixels
    hstart_s        <= to_signed(-58, hcnt_t'length);
    -- end of horizontal sync:
    --    4.7 us after hsync start
    hsync_end_s     <= to_signed(-41, hcnt_t'length);
    -- start of active area
    hstart_active_s <= to_signed(  0, hcnt_t'length);
    -- last pixel of active area
    hlast_active_s  <= to_signed(149, hcnt_t'length);
    -- last pixel of front porch:
    --    1.5 us  + 20 pixels after active area
    hlast_pixel_s   <= to_signed(174, hcnt_t'length);

    -- start value for vertical counter:
    --   60 scanlines before active display
    vstart_s        <= to_signed(-28, vcnt_t'length);
    -- end of vertical sync
    vsync_end_s     <= to_signed(-25, vcnt_t'length);
    -- start of active area
    vstart_active_s <= to_signed(  0, vcnt_t'length);
    -- last display line of active area
    vlast_active_s  <= to_signed( 39, vcnt_t'length);
    -- last display line of front porch:
    --   22 scanlines after active area
    vlast_line_s    <= to_signed( 58, vcnt_t'length);
  end generate;


  -----------------------------------------------------------------------------
  -- Timing values for PAL (625/50)
  --
  -- 625 scanlines, 575 visible
  -----------------------------------------------------------------------------
  pal: if is_pal_g /= 0 generate
    -- start value for horizontal counter:
    --   10.5 us + 20 pixels
    hstart_s        <= to_signed(-58, hcnt_t'length);
    -- end of horizontal sync:
    --    4.7 us after hsync start
    hsync_end_s     <= to_signed(-41, hcnt_t'length);
    -- start of active area
    hstart_active_s <= to_signed(  0, hcnt_t'length);
    -- last pixel of active area
    hlast_active_s  <= to_signed(149, hcnt_t'length);
    -- last pixel of front porch:
    --    1.5 us  + 20 pixels after active area
    hlast_pixel_s   <= to_signed(175, hcnt_t'length);

    -- start value for vertical counter:
    --   96 scanlines before active display
    vstart_s        <= to_signed(-32, vcnt_t'length);
    -- end of vertical sync
    vsync_end_s     <= to_signed(-27, vcnt_t'length);
    -- start of active area
    vstart_active_s <= to_signed(  0, vcnt_t'length);
    -- last display line of active area
    vlast_active_s  <= to_signed( 39, vcnt_t'length);
    -- last display line of front porch:
    --   96 scanlines after active area
    vlast_line_s    <= to_signed( 71, vcnt_t'length);
  end generate;


  -----------------------------------------------------------------------------
  -- Process htiming
  --
  -- Purpose:
  --   Implements the counters for horizontal timing.
  --
  htiming: process (clk_11m_i, por_n_i,
                    hstart_s)
  begin
    if por_n_i = '0' then
      hprescal_q <= hprescal_reload_c;
      hcnt_q     <= hstart_s;
      hsync_n_q  <= '1';

    elsif clk_11m_i'event and clk_11m_i = '1' then
      -- horizontal prescaler
      if hprescal_zero_s then
        hprescal_q <= hprescal_reload_c;
      else
        hprescal_q <= hprescal_q - 1;
      end if;

      if hprescal_zero_s then
        -- horizontal pixel counter
        if hcnt_q = hlast_pixel_s then
          hcnt_q    <= hstart_s;
        else
          hcnt_q    <= hcnt_q + 1;
        end if;

        -- horizontal sync
        if hcnt_q < hsync_end_s then
          hsync_n_q <= '0';
        else
          hsync_n_q <= '1';
        end if;
      end if;

    end if;
  end process htiming;
  --
  hprescal_zero_s <= hprescal_q = 0;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process vtiming
  --
  -- Purpose:
  --   Implements the counters for vertical timing.
  --
  vtiming: process (clk_11m_i, por_n_i,
                    vstart_s)
    variable hcnt_at_start_v  : boolean;
  begin
    if por_n_i = '0' then
      vprescal_q      <= vprescal_reload_c;
      vcnt_q          <= vstart_s;
      vsync_n_q       <= '1';
      hcnt_at_start_q <= false;

    elsif clk_11m_i'event and clk_11m_i = '1' then
      hcnt_at_start_v := hcnt_q = hstart_s;

      hcnt_at_start_q <= hcnt_at_start_v;

      -- horizontal counter just reached hstart_c
      if hcnt_at_start_v and not hcnt_at_start_q then
        -- vertical prescaler
        if vprescal_zero_s then
          vprescal_q <= vprescal_reload_c;
        else
          vprescal_q <= vprescal_q - 1;
        end if;

        if vprescal_zero_s then
          -- vertical line counter
          if vcnt_q = vlast_line_s then
            vcnt_q    <= vstart_s;
          else
            vcnt_q    <= vcnt_q + 1;
          end if;

          -- vertical sync
          if vcnt_q < vsync_end_s then
            vsync_n_q <= '0';
          else
            vsync_n_q <= '1';
          end if;
        end if;

      end if;

    end if;
  end process vtiming;
  --
  vprescal_zero_s <= vprescal_q = 0;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process ctrl
  --
  -- Purpose:
  --   Implements various control registers.
  --
  ctrl: process (clk_11m_i, por_n_i)
    variable r_offset_v : natural;
  begin
    if por_n_i = '0' then
      active_display_q <= false;
      frame_cnt_q      <= (others => '0');
      frame_sync_q     <= false;
      rgb_r_q          <= (others => '0');
      vcnt_pix_q       <= (others => '0');
      vblank_en        <= '0';
      hblank_en        <= '0';

    elsif clk_11m_i'event and clk_11m_i = '1' then
      -- catch framebuffer sync event
      if fb_sync_i = '1' then
        frame_sync_q <= true;
      end if;

      if hprescal_zero_s then
        -- determine active display area
        if vcnt_q >= 0              and
           vcnt_q <= vlast_active_s then
          vblank_en <= '0';
          if    hcnt_q = -1 then
            active_display_q <= true;
            hblank_en <= '0';
          elsif hcnt_q = hlast_active_s then
            active_display_q <= false;
            hblank_en <= '1';
          end if;

        else
          active_display_q   <= false;
          if (vcnt_q >= 49) or (vcnt_q <= -10) then
            vblank_en <= '1';
          else
            vblank_en <= '0';
          end if;
          if hcnt_q = -1 then
            hblank_en <= '0';
          elsif hcnt_q = hlast_active_s then
            hblank_en <= '1';
          end if;
        end if;

        -- frame counter
        if vcnt_q = vlast_line_s  and
           hcnt_q = hlast_pixel_s and
           vprescal_zero_s        then
          if frame_sync_q then
            frame_cnt_q  <= (others => '0');
            frame_sync_q <= false;
          else
            frame_cnt_q  <= frame_cnt_q + 1;
          end if;
        end if;

        -- Red channel intensity calculation
        -- Theorie of operation:
        -- With every new h/v scan, the intensity of the screen decays.
        -- This is implemented by subtracting the frame counter from the
        -- maximum intensity.
        -- The inner scanline is drawn with this intensity, while the
        -- outer scanlines are drawn with reduced intensity.
        --
        if fb_d_i = '1' and active_display_q then
          -- determine intensity upon vertical prescaler
          if fixed_intensity = '1' then
            case vprescal_q is
              when "00" |
                   "01" =>
                r_offset_v := 7;
              when "10" =>
                r_offset_v := 0;
              when others =>
                r_offset_v := 7;
            end case;
            rgb_r_q <= to_unsigned(r_offset_v, 3);
          else
            case vprescal_q is
              when "10" |
                   "00" =>
                r_offset_v := 4;
              when "01" =>
                r_offset_v := 7;
              when others =>
                r_offset_v := 7;
            end case;
            rgb_r_q <= r_offset_v - frame_cnt_q;
          end if;
        else
          rgb_r_q <= (others => '0');
        end if;

        -- vertical pixel/line counter
        if hcnt_q = hlast_active_s and
           vprescal_zero_s        then
          if active_display_q then
            vcnt_pix_q <= vcnt_pix_q + 150;
          else
            -- clear counter if display left active are
            vcnt_pix_q <= (others => '0');
          end if;
        end if;

      end if;
    end if;
  end process ctrl;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Output mapping
  -----------------------------------------------------------------------------
  fb_a_o        <= std_logic_vector(unsigned(hcnt_q(7 downto 0)) + vcnt_pix_q);
  rgb_r_o       <= std_logic_vector(rgb_r_q);
  rgb_hsync_n_o <= hsync_n_q;
  rgb_vsync_n_o <= vsync_n_q;
  rgb_csync_n_o <= hsync_n_q and vsync_n_q;
  hblank        <= hblank_en;
  vblank        <= vblank_en;

end rtl;
