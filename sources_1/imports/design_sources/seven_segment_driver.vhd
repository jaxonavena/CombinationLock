library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity BCDto7Seg is
    Port ( bcd     : in  STD_LOGIC_VECTOR(3 downto 0);
           segments : out STD_LOGIC_VECTOR(6 downto 0);  -- a to g
           clk     : in  STD_LOGIC;
           reset   : in  STD_LOGIC);
end BCDto7Seg;

architecture Behavioral of BCDto7Seg is

    signal blink_counter : unsigned(23 downto 0) := (others => '0');  -- 24-bit counter
    signal blink_signal : std_logic := '0';  -- Signal to toggle display
    signal display_on : std_logic := '1';  -- Control whether to display letters or blank

begin
    -- Blinking logic: Toggle every ~0.6s (you can adjust the counter for different blink rates)
    process(clk, reset)
    begin
        if reset = '1' then
            blink_counter <= (others => '0');
            blink_signal <= '0';
            display_on <= '1';
        elsif rising_edge(clk) then
            if blink_counter = "111111111111111111111111" then
                blink_counter <= (others => '0');
                blink_signal <= not blink_signal;  -- Toggle blink signal
            else
                blink_counter <= blink_counter + 1;
            end if;
        end if;
    end process;

    -- Process for selecting the 7-segment display output
    process(bcd, blink_signal)
    begin
        if blink_signal = '1' then  -- When blink signal is high, display the letters
            case bcd is
                when "0000" => segments <= "1000000"; -- 0
                when "0001" => segments <= "1111001"; -- 1
                when "0010" => segments <= "0100100"; -- 2
                when "0011" => segments <= "0110000"; -- 3
                when "0100" => segments <= "0011001"; -- 4
                when "0101" => segments <= "0010010"; -- 5
                when "0110" => segments <= "0000010"; -- 6
                when "0111" => segments <= "1111000"; -- 7
                when "1000" => segments <= "0000000"; -- 8
                when "1001" => segments <= "0010000"; -- 9
                when "1010" => segments <= "0111111"; -- O (for OPEN)
                when "1011" => segments <= "0011000"; -- P (for OPEN)
                when "1100" => segments <= "0100011"; -- E (for OPEN and ERR)
                when "1101" => segments <= "0011011"; -- N (for OPEN)
                when "1110" => segments <= "0100011"; -- E (for ERR)
                when "1111" => segments <= "0011001"; -- R (for ERR)
                when others => segments <= "1111111"; -- blank
            end case;
        else
            segments <= "1111111";  -- Blank display when blink_signal is low
        end if;
    end process;

end Behavioral;