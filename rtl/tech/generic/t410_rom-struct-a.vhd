-------------------------------------------------------------------------------
-- $Id: t410_rom-struct-a.vhd,v 1.1 2006/05/07 23:53:30 arnim Exp $
-------------------------------------------------------------------------------

architecture struct of t410_rom is

  component rom_t41x
    port(
      Clk : in  std_logic;
      A   : in  std_logic_vector(8 downto 0);
      D   : out std_logic_vector(7 downto 0)
    );
  end component;

begin

  rom_b : rom_t41x
    port map (
      Clk => ck_i,
      A   => addr_i,
      D   => data_o
    );

end struct;
