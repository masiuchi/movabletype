<?php
# Copyright (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

function smarty_function_mtarchivetype($args, &$ctx) {
    $at = $ctx->stash('current_archive_type');
    return $at;
}
?>
