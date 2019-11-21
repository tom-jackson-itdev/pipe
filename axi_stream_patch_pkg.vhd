library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
use vunit_lib.check_pkg.all;
use vunit_lib.logger_pkg.all;
use vunit_lib.sync_pkg.all;
use vunit_lib.axi_stream_pkg.all;
use vunit_lib.stream_master_pkg.all;
use vunit_lib.stream_slave_pkg.all;
context vunit_lib.com_context;
context vunit_lib.data_types_context;

package axi_stream_patch_pkg is

    procedure pop_axi_stream(signal net     : inout network_t;
                             axi_stream     : axi_stream_slave_t;
                             variable tdata : out std_logic_vector);

end package;

package body axi_stream_patch_pkg is

    procedure pop_axi_stream(signal net     : inout network_t;
                             axi_stream     : axi_stream_slave_t;
                             variable tdata : out std_logic_vector) is
    begin
        pop_stream(net, as_stream(axi_stream), tdata);
    end procedure;

end package body;
