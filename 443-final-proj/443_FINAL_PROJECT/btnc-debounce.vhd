library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounced_btnc is
    Port (
        clk       : in  STD_LOGIC;     -- 100MHz clock
        reset     : in  STD_LOGIC;
        BTNC      : in  STD_LOGIC;
        btn_event : out STD_LOGIC      -- One-pulse output on clean rising edge
    );
end debounced_btnc;

architecture Behavioral of debounced_btnc is
    -- Parameters for debounce timing
    constant DEBOUNCE_TIME : integer := 500000; -- 5ms @ 100MHz
    signal debounce_cnt    : integer range 0 to DEBOUNCE_TIME := 0;
    signal stable_btn      : STD_LOGIC := '0';
    signal btn_sync        : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal btn_prev        : STD_LOGIC := '0';
    signal btn_pulse       : STD_LOGIC := '0';
begin

    -- Synchronize BTNC to clk domain
    process(clk)
    begin
        if rising_edge(clk) then
            btn_sync(0) <= BTNC;
            btn_sync(1) <= btn_sync(0);
        end if;
    end process;

    -- Debounce logic
    process(clk, reset)
    begin
        if reset = '1' then
            debounce_cnt <= 0;
            stable_btn <= '0';
        elsif rising_edge(clk) then
            if btn_sync(1) /= stable_btn then
                debounce_cnt <= debounce_cnt + 1;
                if debounce_cnt >= DEBOUNCE_TIME then
                    stable_btn <= btn_sync(1);
                    debounce_cnt <= 0;
                end if;
            else
                debounce_cnt <= 0; -- reset count if input is stable
            end if;
        end if;
    end process;

    -- Rising edge detector
    process(clk, reset)
    begin
        if reset = '1' then
            btn_prev <= '0';
            btn_pulse <= '0';
        elsif rising_edge(clk) then
            btn_pulse <= stable_btn and not btn_prev;
            btn_prev <= stable_btn;
        end if;
    end process;

    btn_event <= btn_pulse;

end Behavioral;
