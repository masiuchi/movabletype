<?php
# Copyright (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

require_once("class.baseobject.php");

/***
 * Class for mt_touch
 */
class Touch extends BaseObject
{
    public $_table = 'mt_touch';
    protected $_prefix = "touch_";
}
?>
