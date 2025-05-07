library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity ComboLock is
    Port ( BTNL, BTNR, BTNC, clk, reset : in STD_LOGIC;
           SEG : out STD_LOGIC_VECTOR(6 downto 0);
           AN : out STD_LOGIC_VECTOR(7 downto 0));
end ComboLock;

architecture Behavioral of ComboLock is
    type sequence is array (0 to 2) of std_logic_vector(3 downto 0);
    constant password : sequence := ("0100", "0010", "0000"); -- 420
    
    -- one digit to the right of the last number in password, starts as 3rd num in pw, add 1 during reset
    signal past_third_num : std_logic_vector(3 downto 0) := password(2);
    
    signal input_seq : sequence;
    signal index : integer := 0;
    type direction is (LEFT, RIGHT, NONE);
    signal prev_dir : direction;
    
    type lock_state is (LOCKED, UNLOCKED, COMPARING, ERROR);
    signal curr_state, next_state : lock_state;
    signal dial_num: STD_LOGIC_VECTOR(3 downto 0); -- current number while spinning
    signal visual_output: STD_LOGIC_VECTOR(3 downto 0); -- current number while spinning

    
    signal valid : STD_LOGIC := '1';
    signal skipped_second_num : STD_LOGIC := '0';
    
    signal char_index : integer range 0 to 3 := 0;
    signal letter_counter : unsigned(22 downto 0) := (others => '0');
    
    signal reset_from_code : STD_LOGIC := '0';
begin

reset_behavior : process(clk, reset)
begin
    if (reset = '1' or reset_from_code = '1') then
        curr_state <= LOCKED;
        next_state <= LOCKED;
        dial_num <= "0000";
        prev_dir <= NONE;
        index <= 0;
        valid <= '1';
        skipped_second_num <= '0';
        past_third_num <= password(2);
        input_seq <= ("0000", "0000", "0000");
        visual_output <= "0000";
        char_index <= 0;
        letter_counter <= (others => '0');
        
        -- Find the number one to the right of our third pw digit for later use
        if (past_third_num = "1001") then
           past_third_num <= "0000";
        else
           past_third_num <= std_logic_vector(unsigned(past_third_num) + 1);
        end if;
        
    elsif (rising_edge(clk)) then
        curr_state <= next_state;
    end if;
end process;

state_behavior : process(BTNL, BTNR, BTNC, curr_state, dial_num, clk, reset)
begin
    if rising_edge(clk) then
        letter_counter <= letter_counter + 1;
        
        case curr_state is
            WHEN LOCKED =>
                -- ROTATING ----------------------------------------------------
                if (BTNL = '1') then -- left, decrement 1
                    if (index /= 1) then
                        valid <= '0';
                    end if;
                        
                    if (dial_num = "0000") then -- wrap around to 9
                        dial_num <= "1001";
                    else
                        dial_num <= std_logic_vector(unsigned(dial_num) - 1);
                    end if;
                    prev_dir <= LEFT;
                    
                    if (index = 1) then -- When dialing for 2nd num, must skip it once while turning left
                        if (dial_num = password(1)) then
                            skipped_second_num <= '1';
                        end if;
                    end if;
     
                elsif (BTNR = '1') then -- right, increment 1
                    if (index = 1) then
                        valid <= '0';
                    end if;
                    
                    if (dial_num = "1001") then -- wrap around to 0
                        dial_num <= "0000";
                    else
                        dial_num <= std_logic_vector(unsigned(dial_num) + 1);
                    end if;
                    prev_dir <= RIGHT;
                    
                    if (index = 2) then -- Should not pass our 3rd number while going directly right from our 2nd
                        if (dial_num = past_third_num) then
                            valid <= '1'; -- overshot our third number, invalid entry
                        end if;
                    end if;
                -- END ROTATING ----------------------------------------------------
                
                -- ENTER ----------------------------------------------------
                elsif (BTNC = '1') then -- enter
                    -- DIRECTIONAL checks
                    if (index = 1) then
                        if (skipped_second_num = '0') then
                            valid <= '0';
                        end if;
                    end if;
                    
                    -- Actually submit to input_seq
                    input_seq(index) <= dial_num;
                    index <= index + 1;
                    
                    -- AUTO SUBMIT when you've entered 3 numbers
                    if (index + 1 = password'length) then
                        next_state <= COMPARING;
                    end if;
                end if;
                -- END ENTER ----------------------------------------------------
                
                
            WHEN UNLOCKED =>
                case char_index is
                    when 0 => visual_output <= "1010";  -- O
                    when 1 => visual_output <= "1011";  -- P
                    when 2 => visual_output <= "1100";  -- E
                    when 3 => visual_output <= "1101";  -- N
                    when others => visual_output <= "0000";
                end case;
    
                if char_index = 3 then
                    char_index <= 0;
                else
                    char_index <= char_index + 1;
                end if;
            WHEN COMPARING =>
                if (input_seq = password and valid = '1') then
                    next_state <= UNLOCKED;
                else
                    next_state <= ERROR;
                end if;
    
            WHEN ERROR =>
                case char_index is
                    when 0 => visual_output <= "1110";  -- E
                    when 1 => visual_output <= "1111";  -- R
                    when 2 => visual_output <= "1111";  -- R again
                    when others => visual_output <= "0000";
                end case;
    
                if char_index = 2 then
                    char_index <= 0;
                else
                    char_index <= char_index + 1;
                end if;
                
                if char_index = 2 then  -- after showing "ERR"
                    reset_from_code <= '1';
                end if;
        end case;
    end if;
end process;
end Behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity BCDto7Seg is
    Port ( bcd     : in  STD_LOGIC_VECTOR(3 downto 0);
           segments : out STD_LOGIC_VECTOR(6 downto 0);  -- a to g
           clk     : in  STD_LOGIC;
           reset   : in  STD_LOGIC);
end BCDto7Seg;

architecture BehavioralSeg of BCDto7Seg is

signal blink_counter : unsigned(23 downto 0) := (others => '0');  -- 24-bit counter
signal blink_signal : std_logic := '0';  -- Signal to toggle display
signal display_on : std_logic := '1';  -- Control whether to display letters or blank

begin
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

end BehavioralSeg;
