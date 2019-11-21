--------------------------------------------------------------------------------
--! @brief      Example pipe stage with registered ready signal
--! @author     Tom Jackson
--! @e-mail     tom.jackson@itdev.co.uk
--! @date       28/10/2019
--!
--! @details    Pipe stage obeying axi protocol with a registered ready signal
--!             and parallel 'expansion' register for buffering data.
--!
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipe_demo_stage_reg_ready is
port(
    clk      : in std_logic;

    -- upstream interface
    us_valid : in std_logic;
    us_data  : in std_logic_vector(7 downto 0);
    us_ready : out std_logic;

    -- downstream interface
    ds_valid : out std_logic := '0';
    ds_data  : out std_logic_vector(7 downto 0);
    ds_ready : in  std_logic
  );
end pipe_demo_stage_reg_ready;

architecture rtl of pipe_demo_stage_reg_ready is

    -- expansion registers
    signal expansion_data_reg    : std_logic_vector(7 downto 0);
    signal expansion_valid_reg   : std_logic := '0';

    -- standard registers
    signal primary_data_reg      : std_logic_vector(7 downto 0);
    signal primary_valid_reg     : std_logic := '0';

begin

    process(clk) is
    begin
        if rising_edge(clk) then

            --accept data if ready is high
            if us_ready = '1' then
                primary_valid_reg    <= us_valid;
                primary_data_reg     <= us_data;
                -- when ds is not ready, accept data into expansion reg until it is valid
                if ds_ready = '0' then
                    expansion_valid_reg  <= primary_valid_reg;
                    expansion_data_reg   <= primary_data_reg;
                end if;
            end if;

            -- when ds becomes ready the expansion reg data is accepted and we must clear the valid register
            if ds_ready = '1' then
                expansion_valid_reg  <= '0';
            end if;

        end if;
    end process;

    --ready as long as there is nothing in the expansion register
    us_ready <= not expansion_valid_reg;

    --selecting the expansion register if it has valid data
    ds_valid <= expansion_valid_reg or primary_valid_reg;
    ds_data  <= expansion_data_reg when expansion_valid_reg else primary_data_reg;

end rtl;
