vim9script noclear
scriptencoding utf-8
# AUTHOR: yokoP <teruyokoP@gmail.com>
# MAINTAINER: yokoP
# License: This file is placed in the public domain.

import "../autoload/ta.vim"

if exists('g:loaded_ta')
  finish
endif

g:loaded_ta = 1
command! Ta call ta.TateStart()

