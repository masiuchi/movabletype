<?php
# Copyright (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

function smarty_function_mtcurrentpage($args, &$ctx)
{
    $limit = $ctx->stash('__pager_limit');
    $offset = $ctx->stash('__pager_offset');
    return $limit ? $offset / $limit + 1 : 1;
}
