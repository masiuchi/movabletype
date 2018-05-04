<?php
# Copyright (C) 2001-2013 Six Apart, Ltd.
# Copyright (C) 2018 Masahiro IUCHI
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

function smarty_function_mtsmartypantsversion($args, &$ctx) {
    require_once('smartypants.php');
    global $SmartyPantsSyntaxVersion;
    return $SmartyPantsSyntaxVersion;
}
?>
