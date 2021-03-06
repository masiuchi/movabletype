<?php
# Copyright (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

function smarty_modifier_sanitize($text, $spec = '1')
{
    if (! $spec) {
        return $text;
    } elseif ($spec == '1') {
        $mt = MT::get_instance();
        $ctx =& $mt->context();
        $blog = $ctx->stash('blog');
        $spec = $blog->blog_sanitize_spec;
        $spec or $spec = $mt->config('GlobalSanitizeSpec');
    }
    require_once("sanitize_lib.php");
    return sanitize($text, $spec);
}
