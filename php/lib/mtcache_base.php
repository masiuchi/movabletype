<?php
# Copyright (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

class MTCacheBase
{
    public $_ttl = 0;

    public function __construct($ttl = 0)
    {
        $this->ttl = $ttl;
    }

    public function get($key, $ttl = null)
    {
    }

    public function get_multi($keys, $ttl = null)
    {
    }

    public function delete($key)
    {
    }

    public function add($key, $val, $ttl = null)
    {
    }

    public function replace($key, $val, $ttl = null)
    {
    }

    public function set($key, $val, $ttl = null)
    {
    }

    public function flush_all()
    {
    }
}
