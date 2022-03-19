-------------------------------------------------------------------------------
--
-- FPGA Adventure Vision
--
-- $Id: av_video.vhd,v 1.4 2006/04/02 18:53:04 arnim Exp $
--
-- Video supplement hierarchy
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

entity av_video is

  generic (
    is_pal_g         : integer := 0
  );
  port (
    -- System Interface -------------------------------------------------------
    clk_11m_i        : in  std_logic;
    por_n_i          : in  std_logic;
    -- Display Interface ------------------------------------------------------
    disp_photo_int_i : in  std_logic;
    led_n_i          : in  std_logic_vector(39 downto 0);
    -- RGB Video Interface ----------------------------------------------------
    rgb_r_o          : out std_logic_vector( 2 downto 0);
    rgb_hsync_n_o    : out std_logic;
    rgb_vsync_n_o    : out std_logic;
    rgb_csync_n_o    : out std_logic;
    vblank           : out std_logic;
    hblank           : out std_logic;
    fixed_intensity  : in  std_logic
  );

end av_video;


use work.av_video_comp_pack.av_frame_buffer;
use work.av_video_comp_pack.av_raster;

architecture struct of av_video is

  signal fb_a_s      : std_logic_vector(12 downto 0);
  signal fb_d_s      : std_logic;
  signal fb_sync_s   : std_logic;

begin

  -----------------------------------------------------------------------------
  -- Framebuffer
  -----------------------------------------------------------------------------
  frame_buf_b : av_frame_buffer
    port map (
      clk_11m_i        => clk_11m_i,
      por_n_i          => por_n_i,
      disp_photo_int_i => disp_photo_int_i,
      led_n_i          => led_n_i,
      fb_a_i           => fb_a_s,
      fb_d_o           => fb_d_s,
      fb_sync_o        => fb_sync_s
    );


  -----------------------------------------------------------------------------
  -- Rasterizer
  -----------------------------------------------------------------------------
  raster_b : av_raster
    generic map (
      is_pal_g      => is_pal_g
    )
    port map (
      clk_11m_i     => clk_11m_i,
      por_n_i       => por_n_i,
      fb_a_o        => fb_a_s,
      fb_d_i        => fb_d_s,
      fb_sync_i     => fb_sync_s,
      rgb_r_o       => rgb_r_o,
      rgb_hsync_n_o => rgb_hsync_n_o,
      rgb_vsync_n_o => rgb_vsync_n_o,
      rgb_csync_n_o => rgb_csync_n_o,
      vblank        => vblank,
      hblank        => hblank,
      fixed_intensity => fixed_intensity
    );

end struct;
