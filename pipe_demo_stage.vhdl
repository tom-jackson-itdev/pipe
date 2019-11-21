--------------------------------------------------------------------------------
--! @brief      Example pipe stage
--! @author     Tom Jackson
--! @e-mail     tom.jackson@itdev.co.uk
--! @date       28/10/2019
--!
--! @details    Pipe stage obeying axi protocol.
--!
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipe_demo_stage is
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
end pipe_demo_stage;

architecture rtl of pipe_demo_stage is
begin

    process(clk) is
    begin
        if rising_edge(clk) then

            --accept data if ready is high
            if us_ready = '1' then
                ds_valid    <= us_valid;
                ds_data     <= us_data;
            end if;

        end if;
    end process;

    --ready signal with registered ready or primary data register is not valid
    us_ready <= ds_ready or not ds_valid;

end rtl;
