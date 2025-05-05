library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity ComboLock is
    Port ( BTNL, BTNR, BTNC, clk, reset : in STD_LOGIC);
end ComboLock;

architecture Behavioral of ComboLock is
    type sequence is array (0 to 2) of std_logic_vector(3 downto 0);
    constant password : sequence := ("0100", "0010", "0000"); -- 420
    signal input_seq : sequence;
    signal index : integer := 0;
    type direction is (LEFT, RIGHT, NONE);
    signal curr_dir : direction;
    
    type lock_state is (LOCKED, UNLOCKED, COMPARING, ERROR);
    signal curr_state, next_state : lock_state;
    signal dial_num: STD_LOGIC_VECTOR(3 downto 0); -- current number while spinning
    
    signal directions_have_been_valid : STD_LOGIC := '1';    
begin

    
reset_behavior : process(clk, reset)
begin
    if (reset = '1') then
        curr_state <= LOCKED;
        dial_num <= "0000";
        curr_dir <= NONE;
        index <= 0;
        directions_have_been_valid <= '1';
    elsif (rising_edge(clk)) then
        curr_state <= next_state;
    end if;
end process;

state_behavior : process(BTNL, BTNR, BTNC, curr_state, dial_num)
begin
    case curr_state is
        WHEN LOCKED =>
            if (BTNL = '1') then -- left, decrement 1
                if (dial_num = "0000") then -- wrap around to 9
                    dial_num <= "1001";
                else
                    dial_num <= std_logic_vector(unsigned(dial_num) - 1);
                end if;
                curr_dir <= LEFT;
                
                
            elsif (BTNR = '1') then -- right, increment 1
                if (dial_num = "1001") then -- wrap around to 0
                    dial_num <= "0000";
                else
                    dial_num <= std_logic_vector(unsigned(dial_num) + 1);
                end if;
                curr_dir <= RIGHT;
                
            elsif (BTNC = '1') then -- submit
                -- TODO directional check
                input_seq(index) <= dial_num;
                index <= index + 1;                
            end if;
            
            if (input_seq'length = password'length) then
                next_state <= COMPARING;
                

            
        WHEN UNLOCKED =>
            -- TODO
        WHEN COMPARING =>
            if (input_seq = password) then
                next_state <= UNLOCKED;
            else
                next_state <= ERROR;
            end if;

        WHEN ERROR =>
            -- TODO, Reset
    end case;
end process;
        

end Behavioral;
