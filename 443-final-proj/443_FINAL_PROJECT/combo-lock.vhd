library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity ComboLock is
    Port ( BTNL, BTNR, BTNC, clk : in STD_LOGIC;
           segments : out STD_LOGIC_VECTOR(6 downto 0);
           AN : out STD_LOGIC_VECTOR(7 downto 0)
           );
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
    signal dial_num: STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- current number while spinning


    signal valid : STD_LOGIC := '1';
    signal skipped_second_num : STD_LOGIC := '0';
    
    signal reset : STD_LOGIC := '0';
begin

state_behavior : process(BTNL, BTNR, BTNC, clk)
begin
    if (reset = '1') then
        curr_state <= LOCKED;
        next_state <= LOCKED;
        dial_num <= "0000";
        prev_dir <= NONE;
        index <= 0;
        valid <= '1';
        skipped_second_num <= '0';
        past_third_num <= password(2);
        input_seq <= ("0000", "0000", "0000");
        segments <= "0000000";
        
        -- Find the number one to the right of our third pw digit for later use
        if (past_third_num = "1001") then
           past_third_num <= "0000";
        else
           past_third_num <= std_logic_vector(unsigned(past_third_num) + 1);
        end if;
        
    elsif rising_edge(clk) then
        AN <= "11111110";
        curr_state <= next_state;
   
        case dial_num is
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
                    if index < 3 then
                        input_seq(index) <= dial_num;
                        index <= index + 1;
                    end if;
                    
                    if (index = 2) then
                        next_state <= COMPARING;
                    end if;
                end if;
                -- END ENTER ----------------------------------------------------
                
                
            WHEN UNLOCKED =>
               segments <= "0111111";
               AN <= "11111110";
            WHEN COMPARING =>
                if (input_seq = password and valid = '1') then
                    next_state <= UNLOCKED;
                else
                    next_state <= ERROR;
                end if;
    
            WHEN ERROR =>
               segments <= "0100011";
               AN <= "11111110";
               reset <= '1';
        end case;
    end if;
end process;
end Behavioral;
