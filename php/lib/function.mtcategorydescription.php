<?php
# Copyright (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

function smarty_function_mtcategorydescription($args, &$ctx) {
    $cat = $ctx->stash('category');
    if (!$cat) return '';
    return $cat->category_description;
}
?>
