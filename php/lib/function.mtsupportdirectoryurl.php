<?php
# Copyright (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

function smarty_function_mtsupportdirectoryurl($args, &$ctx)
{
    require_once "MTUtil.php";
    $url = support_directory_url();
    return $url;
}
