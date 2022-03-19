-------------------------------------------------------------------------------
--
-- FPGA Adventure Vision
--
-- $Id: tech_comp_pack-p.vhd,v 1.5 2006/04/02 18:48:29 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package tech_comp_pack is

  component av_por
    generic (
      delay_g     : integer := 4;
      cnt_width_g : integer := 2
    );
    port (
      clk_i   : in  std_logic;
      por_n_o : out std_logic
    );
  end component;

  component generic_ram
    generic (
      addr_width_g : integer := 10;
      data_width_g : integer := 8
    );
    port (
      clk_i : in  std_logic;
      a_i   : in  std_logic_vector(addr_width_g-1 downto 0);
      we_i  : in  std_logic;
      d_i   : in  std_logic_vector(data_width_g-1 downto 0);
      d_o   : out std_logic_vector(data_width_g-1 downto 0)
    );
  end component;

  component dpram
    generic (
      addr_width_g : integer := 8;
      data_width_g : integer := 8
    );
    port (
      clk_a_i  : in  std_logic;
      we_i     : in  std_logic;
      addr_a_i : in  std_logic_vector(addr_width_g-1 downto 0);
      data_a_i : in  std_logic_vector(data_width_g-1 downto 0);
      data_a_o : out std_logic_vector(data_width_g-1 downto 0);
      clk_b_i  : in  std_logic;
      addr_b_i : in  std_logic_vector(addr_width_g-1 downto 0);
      data_b_o : out std_logic_vector(data_width_g-1 downto 0)
    );
  end component;

  component syn_ram
    generic (
      address_width_g : positive := 8
    );
    port (
      clk_i      : in  std_logic;
      res_i      : in  std_logic;
      ram_addr_i : in  std_logic_vector(address_width_g-1 downto 0);
      ram_data_i : in  std_logic_vector(7 downto 0);
      ram_we_i   : in  std_logic;
      ram_data_o : out std_logic_vector(7 downto 0)
    );
  end component;

  component syn_rom
    generic (
      address_width_g : positive := 9
    );
    port (
      clk_i      : in  std_logic;
      rom_addr_i : in  std_logic_vector(address_width_g-1 downto 0);
      rom_data_o : out std_logic_vector(7 downto 0)
    );
  end component;

end tech_comp_pack;
