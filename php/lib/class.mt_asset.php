<?php
# Copyright (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

require_once("class.baseobject.php");

/***
 * Class for mt_asset
 */
class Asset extends BaseObject
{
    public $_table = 'mt_asset';
    protected $_prefix = "asset_";
    protected $_has_meta = true;
}

// Relations
ADODB_Active_Record::ClassHasMany('Asset', 'mt_asset_meta', 'asset_meta_asset_id');
