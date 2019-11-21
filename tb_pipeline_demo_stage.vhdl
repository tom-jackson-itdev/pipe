--------------------------------------------------------------------------------
--! @brief      Self-checking VUnit testbench for verifying both pipe stages
--! @author     Tom Jackson
--! @e-mail     tom.jackson@itdev.co.uk
--! @date       28/10/2019
--!
--! @details    Both modules are instanced and joined together. Input stream passes through
--!             pipe_demo_stage and then pipe_demo_stage_reg_ready blocks and is verified
--!             at the output.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library osvvm;
use osvvm.RandomPkg.all;
use work.axi_stream_patch_pkg.all;

entity tb_pipe_demo is
        generic (
            runner_cfg                : string);
end entity;

architecture tb of tb_pipe_demo is

    -- pushes data onto the input interface of the device under test
    constant us_drv  : axi_stream_master_t    := new_axi_stream_master (data_length => 8,
                                                                             logger      => get_logger("us_drv"),
                                                                             actor       => new_actor ("us_drv"));

    -- pops data off the output interface of the device under test
    constant ds_drv   : axi_stream_slave_t   := new_axi_stream_slave(data_length => 8,
                                                                             logger      => get_logger("ds_drv"),
                                                                             actor       => new_actor ("ds_drv"));

    --100MHZ test clock
    constant half_clock_period      :  time := 5 ns;
    signal clk                      : std_logic := '0';

    -- testbench input interface
    signal in_valid                 : std_logic;
    signal in_ready                 : std_logic;
    signal in_data                  : std_logic_vector(7 downto 0);

    -- signals joining the two modules under test
    signal out_valid_tb             : std_logic;
    signal out_ready_tb             : std_logic;
    signal out_data_tb              : std_logic_vector(7 downto 0);

    -- testbench output interface
    signal out_valid                : std_logic;
    signal out_ready                : std_logic;
    signal out_data                 : std_logic_vector(7 downto 0);

    begin

        clk  <= not clk after half_clock_period;

        main : process

            -- pushing data to the upstream driver
            procedure push_axi(signal net : inout network_t;
                                          stream : axi_stream_master_t;
                                            data : std_logic_vector) is
            begin
                push_axi_stream(net, stream, data);
            end procedure;

            variable rnd                : RandomPType;
            variable data_out           : std_logic_vector(7 downto 0);
            variable data_exp           : std_logic_vector(7 downto 0);

        begin

            wait for 20 ns;
            wait until rising_edge(clk);

            rnd.InitSeed(rnd'instance_name & runner_cfg);
            test_runner_setup(runner, runner_cfg);

            -- this test drives a single byte and checks for the correct byte on the output interface
            if run("byte_test") then

                --drive data to design
                push_axi(net, us_drv, x"AB");

                --pop data from output
                pop_axi_stream(net, ds_drv, data_out);

                -- validate the output data
                data_exp :=  x"AB";
                check_equal(data_out, data_exp, "mismatch");

            -- this test drives a byte at a time from an incrementing counter, and checks for the correct byte on the output
            elsif run("ramp_test") then

                --drive data to design
                for word in 0 to 100 loop
                    push_axi(net, us_drv, std_logic_vector(to_unsigned(word,8)));
                end loop;

                --pop data from output and validate
                for word in 0 to 100 loop
                    pop_axi_stream(net, ds_drv, data_out);
                    data_exp := std_logic_vector(to_unsigned(word,8));
                    check_equal(data_out, data_exp, "mismatch");
                end loop;

            -- this test drives an counter value onto the input bus, each valid input is followed by a random
            -- stoppage lasting between 0 and 3 clock cycles.
            -- checks for the correct byte on the output
            elsif run("stall_input") then

                --drive data to design
                for word in 0 to 100 loop
                    push_axi(net, us_drv, std_logic_vector(to_unsigned(word,8)));
                    wait_for_time(net, as_sync(us_drv), half_clock_period * 2 * rnd.RandInt(0, 3));
                end loop;

                --pop data from output and validate
                for word in 0 to 100 loop
                    pop_axi_stream(net, ds_drv, data_out);
                    data_exp := std_logic_vector(to_unsigned(word,8));
                    check_equal(data_out, data_exp, "mismatch");
                end loop;

            -- this test drives an incrementing counter onto the input bus. Each byte is popped from the outpus bus
            -- abd validated, followed by 'backpressure' (de-asserted ready signal) for between 0 and 10 clock cycles
            elsif run("stall_output") then

                --drive data to design
                for word in 0 to 100 loop
                    push_axi(net, us_drv, std_logic_vector(to_unsigned(word,8)));
                end loop;

                --pop data from output and validate
                for word in 0 to 100 loop
                    pop_axi_stream(net, ds_drv, data_out);
                    data_exp := std_logic_vector(to_unsigned(word,8));
                    check_equal(data_out, data_exp, "mismatch");
                    wait_for_time(net, as_sync(ds_drv), half_clock_period * 2 * rnd.RandInt(0, 10));
                end loop;

            -- this test drives an incrementing counter onto the input bus, each byte is followed by a random
            -- stoppage lasting between 0 and 3 clock cycles.
            -- Each byte is popped from the outpus bus followed by 'backpressure' (de-asserted ready signal)
            -- for between 0 and 10 clock cycles
            elsif run("stall_both") then

                --drive data to design
                for word in 0 to 100 loop
                    push_axi(net, us_drv, std_logic_vector(to_unsigned(word,8)));
                    wait_for_time(net, as_sync(us_drv), half_clock_period * 2 * rnd.RandInt(0, 7));
                end loop;

                --pop data from output and validate
                for word in 0 to 100 loop
                    pop_axi_stream(net, ds_drv, data_out);
                        wait_for_time(net, as_sync(ds_drv), half_clock_period * 2 * rnd.RandInt(0, 10));
                    data_exp := std_logic_vector(to_unsigned(word,8));
                    check_equal(data_out, data_exp, "mismatch");
                end loop;

            end if;

        test_runner_cleanup(runner);

        end process;

        test_runner_watchdog(runner, 50 us);

        dut : entity work.pipe_demo_stage
        port map(
            clk      => clk,

            -- upstream interface
            us_valid => in_valid,
            us_ready => in_ready,
            us_data  => in_data,

            -- downstream interface
            ds_valid => out_valid_tb,
            ds_ready => out_ready_tb,
            ds_data  => out_data_tb
        );

        dut2 : entity work.pipe_demo_stage_reg_ready
        port map(
            clk      => clk,

            -- upstream interface
            us_valid => out_valid_tb,
            us_data  => out_data_tb,
            us_ready => out_ready_tb,

            -- downstream interface
            ds_valid => out_valid,
            ds_data  => out_data,
            ds_ready => out_ready
          );

        -- pushes data onto the input interface of the device under test
        us_driver : entity vunit_lib.axi_stream_master
        generic map
        (
            master  => us_drv
        )
        port map
        (
            aclk    => clk,
            tvalid  => in_valid,
            tready  => in_ready,
            tdata   => in_data,
            tlast   => open
        );

        -- pops data off the output interface of the device under test
        ds_driver : entity vunit_lib.axi_stream_slave
        generic map
        (
            slave   => ds_drv
        )
        port map
        (
            aclk    => clk,
            tvalid  => out_valid,
            tready  => out_ready,
            tdata   => out_data,
            tlast   => '0'
        );

end tb;