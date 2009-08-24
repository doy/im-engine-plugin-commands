#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

package Foo;
::use_ok('IM::Engine::Plugin::Commands')
    or ::BAIL_OUT("couldn't load IM::Engine::Plugin::Commands");
