-------------------------------------------------------------------------------
--
-- FPGA Adventure Vision
--
-- $Id: av_video_comp_pack-p.vhd,v 1.4 2006/04/02 18:53:04 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package av_video_comp_pack is

  component av_video
    generic (
      is_pal_g         : integer := 0
    );
    port (
      -- System Interface -----------------------------------------------------
      clk_11m_i        : in  std_logic;
      por_n_i          : in  std_logic;
      -- Display Interface ----------------------------------------------------
      disp_photo_int_i : in  std_logic;
      led_n_i          : in  std_logic_vector(39 downto 0);
      -- RGB Video Interface --------------------------------------------------
      rgb_r_o          : out std_logic_vector( 2 downto 0);
      rgb_hsync_n_o    : out std_logic;
      rgb_vsync_n_o    : out std_logic;
      rgb_csync_n_o    : out std_logic;
      vblank           : out std_logic;
      hblank           : out std_logic;
      fixed_intensity  : in  std_logic
    );
  end component;

  component av_frame_buffer
    port (
      -- System Interface -----------------------------------------------------
      clk_11m_i        : in  std_logic;
      por_n_i          : in  std_logic;
      -- Display Interface ----------------------------------------------------
      disp_photo_int_i : in  std_logic;
      led_n_i          : in  std_logic_vector(39 downto 0);
      -- Framebuffer Interface ------------------------------------------------
      fb_a_i           : in  std_logic_vector(12 downto 0);
      fb_d_o           : out std_logic;
      fb_sync_o        : out std_logic
    );
  end component;

  component av_raster
    generic (
      is_pal_g      : integer := 0
    );
    port (
      -- System Interface -----------------------------------------------------
      clk_11m_i     : in  std_logic;
      por_n_i       : in  std_logic;
      -- Framebuffer Interface ------------------------------------------------
      fb_a_o        : out std_logic_vector(12 downto 0);
      fb_d_i        : in  std_logic;
      fb_sync_i     : in  std_logic;
      -- RGB Video Interface --------------------------------------------------
      rgb_r_o       : out std_logic_vector( 2 downto 0);
      rgb_hsync_n_o : out std_logic;
      rgb_vsync_n_o : out std_logic;
      rgb_csync_n_o : out std_logic;
      vblank        : out std_logic;
      hblank        : out std_logic;
      fixed_intensity: in std_logic
    );
  end component;

end av_video_comp_pack;
