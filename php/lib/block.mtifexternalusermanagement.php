<?php
# Copyright (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

function smarty_block_mtifexternalusermanagement($args, $content, &$ctx, &$repeat)
{
    return $ctx->_hdlr_if($args, $content, $ctx, $repeat, $ctx->mt->config('ExternalUserManagement'));
}
