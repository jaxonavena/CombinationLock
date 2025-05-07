library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity ComboLock is
    Port ( BTNL, BTNR, BTNC, BTNU, clk : in STD_LOGIC;
           segments : out STD_LOGIC_VECTOR(6 downto 0);
           AN : out STD_LOGIC_VECTOR(7 downto 0)
           );
end ComboLock;

architecture Behavioral of ComboLock is
    component debounced_btnc
        Port (
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            BTNC      : in  STD_LOGIC;
            btn_event : out STD_LOGIC
        );
    end component;
    
    component debounced_btnl
        Port (
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            BTNL      : in  STD_LOGIC;
            btn_event : out STD_LOGIC
        );
    end component;
    
    component debounced_btnr
        Port (
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            BTNR      : in  STD_LOGIC;
            btn_event : out STD_LOGIC
        );
    end component;

    type sequence is array (0 to 2) of std_logic_vector(3 downto 0);
    constant password : sequence := ("0100", "0010", "0000"); -- 420
    
    -- one digit to the right of the last number in password, starts as 3rd num in pw, add 1 during reset
    signal past_third_num : std_logic_vector(3 downto 0) := password(2);
    
    signal input_seq : sequence;
    signal index : integer := 0;

    
    type lock_state is (LOCKED, UNLOCKED, COMPARING, ERROR);
    signal curr_state, next_state : lock_state;
    signal dial_num: STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- current number while spinning


    signal valid : STD_LOGIC := '1';
    signal skipped_second_num : STD_LOGIC := '0';
    
    signal reset : STD_LOGIC := '0';
    signal submitted : STD_LOGIC := '0';
    
    signal r : STD_LOGIC := '0';
    signal l : STD_LOGIC := '0';

    

    signal btnc_event_sig, btnl_event_sig, btnr_event_sig : STD_LOGIC;

    
begin

btnc_debounce_inst : debounced_btnc
    port map (
        clk       => clk,
        reset     => reset,
        BTNC      => BTNC,
        btn_event => btnc_event_sig
    );


btnl_debounce_inst : debounced_btnl
    port map (
        clk       => clk,
        reset     => reset,
        BTNL      => BTNL,
        btn_event => btnl_event_sig
    );


btnr_debounce_inst : debounced_btnr
    port map (
        clk       => clk,
        reset     => reset,
        BTNR      => BTNR,
        btn_event => btnr_event_sig
    );


state_behavior : process(BTNL, BTNR, BTNC, BTNU, clk)
begin
    AN <= "11111110";
    if (reset = '1') then
        curr_state <= LOCKED;
        next_state <= LOCKED;
        dial_num <= "0000";
        index <= 0;
        valid <= '1';
        submitted <= '0';
        skipped_second_num <= '0';
        past_second_num <= password(1);
        past_third_num <= password(2);
        input_seq <= ("1111", "1111", "1111");
        r <= '0';
        l <= '0';

        -- Find the number one to the left of our second pw digit for later use
        if (past_second_num = "0000") then
           past_second_num <= "1001";
        else
           past_second_num <= std_logic_vector(unsigned(past_second_num) - 1);
        end if;
        
        -- Find the number one to the right of our third pw digit for later use
        if (past_third_num = "1001") then
           past_third_num <= "0000";
        else
           past_third_num <= std_logic_vector(unsigned(past_third_num) + 1);
        end if;
        
        reset <= '0';
        
    elsif rising_edge(clk) then
        curr_state <= next_state;
        
        if (submitted = '0') then
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
                when "1010" => segments <= "1000001"; -- U
                when "1011" => segments <= "0000011"; -- E
                when others => segments <= "1111111"; -- blank
            end case;
        end if;
    
        case curr_state is
            WHEN LOCKED =>
                -- ROTATING ----------------------------------------------------
                if (btnl_event_sig = '1') then -- BTNL, left, decrement 1
                    l <= '1';
                    
                    if (index /= 1) then
                        valid <= '0';
                    end if;
                        
                    if (dial_num = "0000") then -- wrap around to 9
                        dial_num <= "1001";
                    else
                        dial_num <= std_logic_vector(unsigned(dial_num) - 1);
                    end if;
                    
                    if (index = 1) then -- When dialing for 2nd num, must skip it once while turning left
                        if (dial_num = past_second_num) then
                            skipped_second_num <= '1';
                        end if;
                    end if;
     
                elsif (btnr_event_sig = '1') then -- BTNR, right, increment 1
                    r <= '1';
                    
                    if (index = 1) then
                        valid <= '0';
                    end if;
                    
                    if (dial_num = "1001") then -- wrap around to 0
                        dial_num <= "0000";
                    else
                        dial_num <= std_logic_vector(unsigned(dial_num) + 1);
                    end if;
                    
                    if (index = 2) then -- Should not pass our 3rd number while going directly right from our 2nd
                        if (dial_num = past_third_num) then
                            valid <= '0'; -- overshot our third number, invalid entry
                        end if;
                    end if;
                -- END ROTATING ----------------------------------------------------
                
                -- ENTER ----------------------------------------------------
                elsif (btnc_event_sig = '1') then -- BTNC, enter
                    -- DIRECTIONAL checks
                    if (index = 1) then
                        if (skipped_second_num = '0') then
                            valid <= '0';
                        end if;
                    end if;
                    
                    -- AUTO SUBMIT when you've entered 3 numbers
                    if index < 3 then
                        input_seq(index) <= dial_num;
                        index <= index + 1;
                    end if;
                    
                    if (index = 2) then
                        input_seq(index) <= dial_num;
                        next_state <= COMPARING;
                        submitted <= '1';
                    end if;
                end if;
                -- END ENTER ----------------------------------------------------
                
            WHEN COMPARING =>
                if (input_seq = password and valid = '1' and l = '1' and r = '1') then
                    next_state <= UNLOCKED;
                else
                    next_state <= ERROR;
                end if;
                
            WHEN UNLOCKED =>
                dial_num <= "1010";
                segments <= "1000001"; -- triggers U for Unlocked
               
                if (BTNU = '1') then
                    reset<= '1';
                end if;
    
            WHEN ERROR =>
               dial_num <= "1011";
               segments <= "0000011"; -- triggers E for error
               
               if (BTNU = '1') then
                    reset<= '1';
               end if;
        end case;
    end if;
end process;
end Behavioral;
