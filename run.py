#!/usr/bin/env python2.7
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2018, Lars Asplund lars.anders.asplund@gmail.com

from os.path import join, dirname, isdir
from os import makedirs
from vunit import VUnitCLI, VUnit
from subprocess import call
import re
from shutil import copyfile

cli = VUnitCLI()
args = cli.parse_args()

ui = VUnit.from_args(args=args)
ui.add_osvvm()
ui.add_verification_components()
ui.enable_check_preprocessing()

if not isdir("vunit_out/modelsim/libraries/"):
    makedirs("./vunit_out/modelsim/libraries/")

call("vlib vunit_out/modelsim/libraries/blog_lib".split())

fds_lib = ui.add_library("blog_lib")

fds_lib.add_source_files("axi_stream_patch_pkg.vhd")
fds_lib.add_source_files("*.vhdl")

fds_lib.set_sim_option('disable_ieee_warnings', True)

# Built in Vsim command to include the Altera MF library for items such as altsyncram
vsim_flags = ['-L altera_mf'];

ui.set_sim_option('modelsim.vsim_flags', vsim_flags);

ui.main()
