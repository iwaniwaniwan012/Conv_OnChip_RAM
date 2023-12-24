library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.ALL;
use ieee.std_logic_unsigned.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity Conv_OnChip_RAM is
	port (
		Clk 						: in std_logic;
		Reset 					: in std_logic;
		En_In						: in std_logic_vector(3 downto 0);
		Cmd_In					: in std_logic_vector(3 downto 0);
		Addr_In					: in std_logic_vector(31 downto 0);
		Data_In					: in std_logic_vector(31 downto 0);
		Read_Data_Valid_Out	: out std_logic_vector(3 downto 0);
		Read_Data_Out			: out std_logic_vector(31 downto 0);
		Busy_Out					: out std_logic				
	);
end entity;

architecture behavioral of Conv_OnChip_RAM is

type Work_Queue_In_t is 
	record
		En			: std_logic;
		Cmd 		: std_logic;
--		Channel 	: std_logic_vector(1 downto 0);
		Addr		: std_logic_vector(9 downto 0);
		Data		: std_logic_vector(7 downto 0);
	end record;

type Work_Queue_Out_t is 
	record
		Rd				: std_logic_vector(3 downto 0);
		Out_Num		: std_logic_vector(3 downto 0); 
		Data			: std_logic_vector(31 downto 0);
	end record;


type WQ_Array_In_t is array (natural range <>) of Work_Queue_In_t;
type WQ_Array_Out_t is array (natural range <>) of Work_Queue_Out_t;

--signal wire_scfifo_clk 			: std_logic;
--signal wire_scfifo_sclr 		: std_logic := '1';
--signal wire_scfifo_empty		: std_logic := '1';
--signal wire_scfifo_full			: std_logic := '0';
--signal wire_scfifo_usedw		: std_logic_vector(2 downto 0) := (others => '0');
--signal wire_scfifo_data_in		: std_logic_vector(79 downto 0) := (others => '0');
--signal wire_scfifo_data_out	: std_logic_vector(79 downto 0) := (others => '0');
--signal wire_scfifo_rdreq		: std_logic := '0';
--signal wire_scfifo_wrreq		: std_logic := '0';

signal wire_ram_clk				: std_logic;
signal wire_ram_addr_in			: std_logic_vector(19 downto 0) := (others => '0');
signal wire_ram_data_in			: std_logic_vector(15 downto 0) := (others => '0');
signal wire_ram_rdreq			: std_logic_vector(1 downto 0) := (others => '0');
signal wire_ram_wrreq			: std_logic_vector(1 downto 0) := (others => '0');
signal wire_ram_data_out		: std_logic_vector(15 downto 0) := (others => '0');

signal WQ_Busy			: std_logic;

signal WQ_Array_In	: WQ_Array_In_t(3 downto 0);
signal WQ_Array_Work	: WQ_Array_In_t(3 downto 0);
signal WQ_Array_Out	: WQ_Array_Out_t(2 downto 0);

begin

--wire_scfifo_clk 	<= Clk;
--wire_scfifo_sclr	<= Reset;
wire_ram_clk		<= Clk;

Busy_Out <= '1' when En_In = "0111" or En_In = "1011" or En_In = "1101" or En_In = "1110" or En_In = "1111" else '0';

--Busy_Out <= '1' when wire_scfifo_usedw(2 downto 1) = "11" else '0';

	gen_WQ:
	for i in 3 downto 0 generate
		WQ_Array_In(i).En			<= En_In(i);
		WQ_Array_In(i).Cmd 		<= Cmd_In(i);
		WQ_Array_In(i).Addr		<= (conv_std_logic_vector(i,2) & Addr_In(7+i*8 downto 0+i*8));
		WQ_Array_In(i).Data		<= Data_In(7+i*8 downto 0+i*8);
		
		Read_Data_Valid_Out(i) 					<= WQ_Array_Out(0).Rd(i);
		Read_Data_Out(7+i*8 downto 0+i*8) 	<= WQ_Array_Out(0).Data(7+i*8 downto 0+i*8);
		
--		WQ_Array(i).En			<= wire_scfifo_data_out(0+i*18)
--		WQ_Array(i).Cmd 		<= wire_scfifo_data_out(1+i*18);
--		WQ_Array(i).Addr		<= wire_scfifo_data_out(11+i*18 downto 2+i*18);
--		WQ_Array(i).Data		<= wire_scfifo_data_out(19+i*18 downto 12+i*18);
		
--		wire_scfifo_data_in(0+i*18) 						<= En_In(i);
--		wire_scfifo_data_in(1+i*18) 						<= Cmd_In(i);
--		wire_scfifo_data_in(11+i*18 downto 2+i*18) 	<= (conv_std_logic_vector(i,2)) & Addr_In(7+i*8 downto 0+i*8);
--		wire_scfifo_data_in(19+i*18 downto 12+i*18) 	<= Data_In(7+i*8 downto 0+i*8);
	end generate;

--	m_scfifo : scfifo
--		GENERIC MAP (
--			add_ram_output_register => "OFF",
--			--intended_device_family => "Cyclone IV E",
--			lpm_numwords => 8,
--			lpm_showahead => "ON",
--			lpm_type => "scfifo",
--			lpm_width => 79,
--			lpm_widthu => 3,
--			overflow_checking => "ON",
--			underflow_checking => "ON",
--			use_eab => "OFF"
--		)
--		PORT MAP (
--			clock 		=> wire_scfifo_clk,
--			sclr			=> wire_scfifo_sclr,
--			data 			=> wire_scfifo_data_in,
--			rdreq 		=> wire_scfifo_rdreq,
--			wrreq 		=> wire_scfifo_wrreq,
--			empty 		=> wire_scfifo_empty,
--			full 			=> wire_scfifo_full,
--			q 				=> wire_scfifo_data_out,
--			usedw 		=> wire_scfifo_usedw
--		);
	
	m_altsyncram : altsyncram
		GENERIC MAP (
			address_reg_b => "CLOCK0",
			clock_enable_input_a => "BYPASS",
			clock_enable_input_b => "BYPASS",
			clock_enable_output_a => "BYPASS",
			clock_enable_output_b => "BYPASS",
			indata_reg_b => "CLOCK0",
			intended_device_family => "Cyclone IV GX",
			lpm_type => "altsyncram",
			numwords_a => 1024,
			numwords_b => 1024,
			operation_mode => "BIDIR_DUAL_PORT",
			outdata_aclr_a => "NONE",
			outdata_aclr_b => "NONE",
			outdata_reg_a => "UNREGISTERED",
			outdata_reg_b => "UNREGISTERED",
			power_up_uninitialized => "FALSE",
			read_during_write_mode_mixed_ports => "DONT_CARE",
			read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
			read_during_write_mode_port_b => "NEW_DATA_NO_NBE_READ",
			widthad_a => 10,
			widthad_b => 10,
			width_a => 8,
			width_b => 8,
			width_byteena_a => 1,
			width_byteena_b => 1,
			wrcontrol_wraddress_reg_b => "CLOCK0"
		)
		PORT MAP (
			address_a 	=> wire_ram_addr_in(9 downto 0),
			address_b 	=> wire_ram_addr_in(19 downto 10),
			clock0 		=> wire_ram_clk,
			data_a 		=> wire_ram_data_in(7 downto 0),
			data_b 		=> wire_ram_data_in(15 downto 8),
			rden_a 		=> wire_ram_rdreq(0),
			rden_b 		=> wire_ram_rdreq(1),
			wren_a 		=> wire_ram_wrreq(0),
			wren_b 		=> wire_ram_wrreq(1),
			q_a 			=> wire_ram_data_out(7 downto 0),
			q_b 			=> wire_ram_data_out(15 downto 8)
		);

	gen_in_ram:
	for i in 1 downto 0 generate
		wire_ram_addr_in(9+i*10 downto 0+i*10) <= WQ_Array_Work(i).Addr;
		wire_ram_data_in(7+i*8 downto 0+i*8)	<= WQ_Array_Work(i).Data;
		wire_ram_rdreq(i)								<= ((not WQ_Array_Work(i).Cmd) and WQ_Array_Work(i).En);
		wire_ram_wrreq(i)								<= (WQ_Array_Work(i).Cmd and WQ_Array_Work(i).En);
	end generate;
	
--	for i in 3 downto 0 generate
--		Read_Data_Valid_Out(i) <= WQ_Array_Out(0).Rd(i);
--		Read_Data_Out(7+i*8 downto 0+i*8) <= WQ_Array_Out(0).Data(7+i*8 downto 0+i*8);
--	end generate;
	
	process(Clk) 
		variable vEn_In : std_logic_vector(3 downto 0) := (others => '0');
		begin
		if Rising_Edge(Clk) then
			if Reset = '1' then
				WQ_Busy <= '1';
				for i in 3 downto 0 loop
					WQ_Array_Work(i).En <= '0';
				end loop;
			else
				vEn_In := WQ_Array_In(3).En & WQ_Array_In(2).En & WQ_Array_In(1).En & WQ_Array_In(0).En;
				if vEn_In /= "0000" then
					case vEn_In is
						when "0001" =>
							WQ_Array_Work(0) <= WQ_Array_In(0);
							WQ_Array_Work(1).En <= '0';
							WQ_Array_Work(2).En <= '0';
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '0';
						when "0010" =>
							WQ_Array_Work(0) <= WQ_Array_In(1);
							WQ_Array_Work(1).En <= '0';
							WQ_Array_Work(2).En <= '0';
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '0';
						when "0011" =>
							WQ_Array_Work(0) <= WQ_Array_In(0);
							WQ_Array_Work(1) <= WQ_Array_In(1);
							WQ_Array_Work(2).En <= '0';
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '0';
						when "0100" =>
							WQ_Array_Work(0) <= WQ_Array_In(2);
							WQ_Array_Work(1).En <= '0'; 
							WQ_Array_Work(2).En <= '0';
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '0';
						when "0101" =>
							WQ_Array_Work(0) <= WQ_Array_In(0);
							WQ_Array_Work(1) <= WQ_Array_In(2);
							WQ_Array_Work(2).En <= '0';
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '0';
						when "0110" =>
							WQ_Array_Work(0) <= WQ_Array_In(1);
							WQ_Array_Work(1) <= WQ_Array_In(2);
							WQ_Array_Work(2).En <= '0';
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '0';
						when "0111" =>
							WQ_Array_Work(0) <= WQ_Array_In(0);
							WQ_Array_Work(1) <= WQ_Array_In(1);
							WQ_Array_Work(2) <= WQ_Array_In(2);
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '1';
						when "1000" =>
							WQ_Array_Work(0) <= WQ_Array_In(3);
							WQ_Array_Work(1).En <= '0'; 
							WQ_Array_Work(2).En <= '0';
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '0';
						when "1001" =>
							WQ_Array_Work(0) <= WQ_Array_In(0);
							WQ_Array_Work(1) <= WQ_Array_In(3);
							WQ_Array_Work(2).En <= '0';
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '0';
						when "1010" =>
							WQ_Array_Work(0) <= WQ_Array_In(1);
							WQ_Array_Work(1) <= WQ_Array_In(3);
							WQ_Array_Work(2).En <= '0';
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '0';
						when "1011" =>
							WQ_Array_Work(0) <= WQ_Array_In(0);
							WQ_Array_Work(1) <= WQ_Array_In(1);
							WQ_Array_Work(2) <= WQ_Array_In(3);
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '1';
						when "1100" =>
							WQ_Array_Work(0) <= WQ_Array_In(2);
							WQ_Array_Work(1) <= WQ_Array_In(3);
							WQ_Array_Work(2).En <= '0';
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '0';
						when "1101" =>
							WQ_Array_Work(0) <= WQ_Array_In(0);
							WQ_Array_Work(1) <= WQ_Array_In(2);
							WQ_Array_Work(2) <= WQ_Array_In(3);
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '1';
						when "1110" =>
							WQ_Array_Work(0) <= WQ_Array_In(1);
							WQ_Array_Work(1) <= WQ_Array_In(2);
							WQ_Array_Work(2) <= WQ_Array_In(3);
							WQ_Array_Work(3).En <= '0';
							WQ_Busy <= '1';
						when "1111" =>
							WQ_Array_Work(0) <= WQ_Array_In(0);
							WQ_Array_Work(1) <= WQ_Array_In(1);
							WQ_Array_Work(2) <= WQ_Array_In(2);
							WQ_Array_Work(3) <= WQ_Array_In(3);
							WQ_Busy <= '1';
						when others =>
							NULL;
					end case;
				else
					WQ_Busy <= '0';
					if WQ_Busy = '1' then
						WQ_Array_Work(1 downto 0) <= WQ_Array_Work(3 downto 2);
					else
						for i in 3 downto 0 loop
							WQ_Array_Work(i).En <= '0';
						end loop;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process(Clk) begin
		if Rising_Edge(Clk) then
			if Reset = '1' then
				for i in 3 downto 0 loop
					WQ_Array_Out(0).Rd(i) <= '0';
					WQ_Array_Out(1).Rd(i) <= '0';
				end loop;
			else
				WQ_Array_Out(1) <= WQ_Array_Out(2);
				WQ_Array_Out(0) <= WQ_Array_Out(1);
				for i in 3 downto 0 loop
					if WQ_Array_Work(0).En = '1' and WQ_Array_Work(0).Cmd = '0' and (WQ_Array_Work(0).Addr(9 downto 8) = conv_std_logic_vector(i,2)) then
						WQ_Array_Out(2).Rd(i) 		<= '1';
						WQ_Array_Out(2).Out_Num(i) <= '0';
					elsif WQ_Array_Work(1).En = '1' and WQ_Array_Work(1).Cmd = '0' and (WQ_Array_Work(1).Addr(9 downto 8) = conv_std_logic_vector(i,2)) then
						WQ_Array_Out(2).Rd(i) 		<= '1';
						WQ_Array_Out(2).Out_Num(i) <= '1';
					else
						WQ_Array_Out(2).Rd(i) <= '0';
					end if;
					
					if WQ_Array_Out(1).Rd(i) = '1' then
						if WQ_Array_Out(0).Out_Num(i) = '0' then
							WQ_Array_Out(0).Data(7+i*8 downto 0+i*8) <= wire_ram_data_out(7 downto 0);
						else
							WQ_Array_Out(0).Data(7+i*8 downto 0+i*8) <= wire_ram_data_out(15 downto 8);
						end if;
					else
						WQ_Array_Out(0).Data(7+i*8 downto 0+i*8) <= (others => '0');
					end if;
					
				end loop;
			end if;
		end if;
	end process;
	
end behavioral;