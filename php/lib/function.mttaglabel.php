<?php
# Copyright (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

require_once('function.mttagname.php');
function smarty_function_mttaglabel($args, &$ctx)
{
    return smarty_function_mttagname($args, $ctx);
}
