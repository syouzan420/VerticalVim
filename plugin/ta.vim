vim9script noclear
# AUTHOR: yokoP
# MAINTAINER: yokoP
# License: This file is placed in the public domain.

if exists('g:loaded_ta')
  finish
endif

g:loaded_ta = 1

command! Ta call ta#TateStart()
