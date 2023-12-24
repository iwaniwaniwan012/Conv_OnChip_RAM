library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;

entity TB_Conv_OnChip_RAM is
end entity;

architecture behavioral of TB_Conv_OnChip_RAM is

constant T_Clk	: time := 8 ns;

signal Clk		: std_logic := '0';
signal Reset	: std_logic := '1';

signal Counter	: std_logic_vector(8 downto 0) := (others => '0');

signal wire_En_In						: std_logic_vector(3 downto 0);
signal wire_Cmd_In					: std_logic_vector(3 downto 0) := (others => '0');
signal wire_Addr_In					: std_logic_vector(31 downto 0);
signal wire_Data_In					: std_logic_vector(31 downto 0);
signal wire_Read_Data_Valid_Out	: std_logic_vector(3 downto 0);
signal wire_Read_Data_Out			: std_logic_vector(31 downto 0);
signal wire_Busy_Out					: std_logic;

begin

Clk 	<= not Clk after T_Clk;
Reset <= '1', '0' after 10*T_Clk;

	m_Conv_OnChip_RAM: entity work.Conv_OnChip_RAM
		port map(
			Clk 						=> Clk,								--: in std_logic;
			Reset 					=> Reset,							--: in std_logic;
			En_In						=> wire_En_In,						--: in std_logic_vector(3 downto 0);
			Cmd_In					=> wire_Cmd_In,					--: in std_logic_vector(3 downto 0);
			Addr_In					=> wire_Addr_In,					--: in std_logic_vector(31 downto 0);
			Data_In					=> wire_Data_In,					--: in std_logic_vector(31 downto 0);
			Read_Data_Valid_Out	=> wire_Read_Data_Valid_Out,	--: out std_logic_vector(3 downto 0);
			Read_Data_Out			=> wire_Read_Data_Out,			--: out std_logic_vector(31 downto 0);
			Busy_Out					=> wire_Busy_Out					--: out std_logic				
		);
	
	gen_Test:
	for i in 3 downto 0 generate	
		process(Clk)
			begin
				if Rising_Edge(Clk) then
					if Reset = '1' then
						wire_En_In(i) <= '0';
						Counter <= (others => '0');
					else
						if wire_Busy_Out = '0' then
							Counter <= Counter + '1'; 
							wire_En_In(i) 							<= '1';
							wire_Cmd_In(i) 						<= Counter(8);--not wire_Cmd_In(i);
							wire_Addr_In(7+i*8 downto 0+i*8) <= Counter(7 downto 0);
							wire_Data_In(7+i*8 downto 0+i*8) <= (Counter(7 downto 0) + '1');
						else
							wire_En_In(i) <= '0';
						end if;
					end if;
				end if;
		end process;
	end generate;
	
end behavioral;