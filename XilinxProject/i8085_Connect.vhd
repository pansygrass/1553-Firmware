----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:31:17 11/26/2012 
-- Design Name: 
-- Module Name:    i8085_Connect - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i8085_Connect is
    Port ( reset : in  STD_LOGIC;
           fast_clk : in  STD_LOGIC;
			  
			  --Directly from the i8085
           add_i8085 : in  STD_LOGIC_VECTOR (15 downto 0);
           ALE : in  STD_LOGIC;
           nWR : in  STD_LOGIC;
           nRD : in  STD_LOGIC;
			  
			  --Holt data, from Holt_Connect, is given out one at a time to the i8085
           DATA_h_in_0 : in  STD_LOGIC_VECTOR (7 downto 0);
           DATA_h_in_1 : in  STD_LOGIC_VECTOR (7 downto 0);
           DATA_h_vin_0 : in  STD_LOGIC;
           DATA_h_vin_1 : in  STD_LOGIC;
			  
			  --This is enabled by add_i8085(15) for the Holt_Connect
           address_latched : out  STD_LOGIC_VECTOR (15 downto 0);	  
           nWR_out : out  STD_LOGIC;
           nRD_out : out  STD_LOGIC;
           ALE_out : out  STD_LOGIC;
			  
			  --Data, held out for te Holt_Connect
           DATA_i_out_0 : out  STD_LOGIC_VECTOR (7 downto 0);
           DATA_i_out_1 : out  STD_LOGIC_VECTOR (7 downto 0);
           DATA_i_vout_0 : out  STD_LOGIC :=  '0';
           DATA_i_vout_1 : out  STD_LOGIC :=  '0';
			  
			  --From Holt_Connect, confirms write data transfer
			  DATA_i_ack  : in  STD_LOGIC;
			  
			  --To Holt_Connect, confirms read data transfer
			  DATA_h_ack  : out  STD_LOGIC;
			  
			  --Out to i8085
           IDATA_out : out  STD_LOGIC_VECTOR (7 downto 0) := "ZZZZZZZZ";
			  
			  --debugz
			  STATE_o : OUT STD_LOGIC_VECTOR (2 DOWNTO 0)
			  
			  );
end i8085_Connect;

architecture Behavioral of i8085_Connect is

	signal addr_temp : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000";
	SIGNAL wrorrd_event : STD_LOGIC;
	signal data_temp : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
	signal DATA_i_vout_0_temp : STD_LOGIC := '0';
	signal DATA_i_vout_1_temp : STD_LOGIC := '0';
   signal DATA_i_out_0_temp : STD_LOGIC_VECTOR(7 downto 0);
   signal DATA_i_out_1_temp : STD_LOGIC_VECTOR(7 downto 0);
	
	COMPONENT Latch16Bit IS
	PORT(
		data    : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		enable : IN STD_LOGIC;
		clk	: IN STD_LOGIC;
		q   : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT;


begin



	--Latching the 8085 address for Holt_Connect, High Z otherwise
	wrorrd_event <= NOT(nWR AND nRD);
	addr_L : Latch16Bit port map (data=>add_i8085, enable => ALE, clk => wrorrd_event,q => addr_temp);
	address_latched <= addr_temp WHEN add_i8085(15) = '1' ELSE "ZZZZZZZZZZZZZZZZ";
	--High Z for data out when no need
	IDATA_out <= data_temp WHEN add_i8085(15) = '1' ELSE "ZZZZZZZZ";
	
	--Other Temps
	DATA_i_vout_0 <= DATA_i_vout_0_temp WHEN add_i8085(15) = '1' ELSE '0';
	DATA_i_vout_1 <= DATA_i_vout_1_temp WHEN add_i8085(15) = '1' ELSE '0';
	DATA_i_out_0 <= DATA_i_out_0_temp WHEN add_i8085(15) = '1' ELSE x"00";
	DATA_i_out_1 <= DATA_i_out_1_temp WHEN add_i8085(15) = '1' ELSE x"00";
	
	
	--Enable Holt_Connect outputs by add_i8085(15)
	nWR_out <= nWR WHEN add_i8085(15) = '1' ELSE '1';
	nRD_out <= nRD WHEN add_i8085(15) = '1' ELSE '1';
	ALE_out <= ALE WHEN add_i8085(15) = '1' ELSE '0';
	
	
	--Obtain and validate data from the i8085 for Holt_Connect
	write_p : PROCESS(nWR, reset, DATA_i_ack, add_i8085(15),fast_clk)
		variable STATE : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
	BEGIN
	
		--debugz
		STATE_o <= STATE;
		
		--Reset Non add_i8085(15) enabled stuff
		IF(reset = '1') THEN
			STATE := "000";
			DATA_i_vout_0_temp <= '0';
			DATA_i_vout_1_temp <= '0';
		END IF;
			--As soon as read is ready take it and wait for the next, setting valid bit as it is sent out
		if(fast_clk'EVENT and fast_clk = '1') then 
			
			if(add_i8085 = X"0000") then
				STATE := "000";
			end if;
		
			CASE STATE IS
				WHEN "000" => --Reset state -> Place first 8bits and valid flag when good data in
					IF(add_i8085(15) = '0' or add_i8085 = X"0000") THEN --Reset validity
						DATA_i_vout_0_temp <= '0';
						DATA_i_vout_1_temp <= '0';
--					ELSIF( (nWR = '1') and (nWR'event)) THEN
					ELSIF( (nWR = '1') ) THEN
						DATA_i_out_0_temp <= add_i8085(7 downto 0);
						STATE := "001";
						DATA_i_vout_0_temp <= '1';
					END IF;
				WHEN "001" => --wait for nwr to fall
					IF( (nWR = '0') ) THEN
						STATE := "010";
					END IF;
				WHEN "010" => --Place second 8bits and valid flag
	--				IF( add_i8085(15) = '0' ) THEN --Reset on bad add_i8085(15)
	--					STATE := "00";
	--					DATA_i_vout_0_temp <= '0';
	--					DATA_i_vout_1_temp <= '0';
	--				ELSIF( (nWR = '1') and (nWR'event) ) THEN
					IF( (nWR = '1') and add_i8085(15) = '1') THEN
						DATA_i_out_1_temp <= add_i8085(7 downto 0);
						STATE := "011";
						DATA_i_vout_1_temp <= '1';
					END IF;
					
				WHEN "011" => --wait for nwr to fall
					IF( (nWR = '0')) THEN
						STATE := "100";
					END IF;
				WHEN "100" => --When acknowledged, turn off validy and reset
	--				IF( add_i8085(15) = '0' ) THEN --Reset on bad add_i8085(15)
	--					STATE := "00";
	--					DATA_i_vout_0_temp <= '0';
	--					DATA_i_vout_1_temp <= '0';
	--				ELSIF( (DATA_i_ack = '1') and (DATA_i_ack'event) ) THEN
					IF( (DATA_i_ack = '1')) THEN
						STATE := "000";
						DATA_i_vout_0_temp <= '0';
						DATA_i_vout_1_temp <= '0';
					END IF;
				WHEN OTHERS =>
					STATE := "000";
					DATA_i_vout_0_temp <= '0';
					DATA_i_vout_1_temp <= '0';
						
			END CASE;
		end if;
	
	END PROCESS write_p;
	
	
	--Take Data from the Holt_Connect and set it up for the i8085
	read_p : PROCESS(nRD, reset, add_i8085(15), DATA_h_vin_0, DATA_h_vin_1 )
		variable STATE : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
	BEGIN
		
		--Reset Non add_i8085(15) enabled stuff
		IF(reset = '1') THEN
			STATE := "00";
		END IF;
			--Waits for a valid signal, puts the data out then waits for the processer to stop reading, 
				--then it puts out the second data, and waits for the processor to stop reading
		CASE STATE IS
			WHEN "00" => --On first 8bit valid flag, show data
				IF(add_i8085(15) = '0') THEN
					data_temp <= "ZZZZZZZZ";
				ELSIF( (DATA_h_vin_0 = '1') AND (DATA_h_vin_0'event) ) THEN
					data_temp <= DATA_h_in_0;
					STATE := "01";
				END IF;
			WHEN "01" => --Hold the data until the i8085 stops reading
				IF( add_i8085(15) = '0' ) THEN --Reset on bad add_i8085(15)
					STATE := "00";
					data_temp <= "ZZZZZZZZ";
				ELSIF( (nRD = '1') and (nRD'event) ) THEN
					data_temp <= "ZZZZZZZZ";
					STATE := "10";
				END IF;
			WHEN "10" =>
				IF( add_i8085(15) = '0' ) THEN --Reset on bad add_i8085(15)
					STATE := "00";
					data_temp <= "ZZZZZZZZ";
				ELSIF( (DATA_h_vin_1 = '1') AND (DATA_h_vin_1'event) ) THEN
					data_temp <= DATA_h_in_1;
					STATE := "11";
				END IF;
			WHEN "11" => --Hold the data until the i8085 stops reading, then wait for flag reset for safety
				IF( add_i8085(15) = '0' ) THEN --Reset on bad add_i8085(15)
					STATE := "00";
					data_temp <= "ZZZZZZZZ";
				ELSIF( (DATA_h_vin_0 = '0') AND (DATA_h_vin_1 = '0')) THEN
					STATE := "00";
					DATA_h_ack <= '0';
				ELSIF( (nRD = '1') and (nRD'event) ) THEN
					data_temp <= "ZZZZZZZZ";
					DATA_h_ack <= '1';
				END IF;
			WHEN OTHERS =>
				STATE := "00";
					
		END CASE;
	
	END PROCESS read_p;

end Behavioral;

