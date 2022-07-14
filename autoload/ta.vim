vim9script noclear
scriptencoding utf-8
# AUTHOR: yokoP <teruyokoP@gmail.com>
# MAINTAINER: yokoP
# License: This file is placed in the public domain.

# CHANGE TO TATE -------------------------------------------------
def ChangeToTate()
  MakeNewList(h - 2)
  ConvertList()
enddef
# --------------------------------------------------------------------------------

# MAKE NEW LIST ------------------------------------------------------------------
# INPUTS
# hi : limit height which is the limit length of the output list (nls)
def MakeNewList(hi: number)
  var c = 0
  pl = y
  var plf = pl
  px = x
  nls = []
  oln = []              # original line number 
  var m = len(bls)
  while c < m
    var el = bls[c]
    var l = strchars(el)
    while l > hi
      if c + 1 < plf
        pl = pl + 1
      elseif (c + 1 == plf) && (px > hi)
        pl = pl + 1
        px = px - hi
      endif
      var fst = slice(el, 0, hi)
      el = slice(el, hi)
      nls = nls + [fst]
      oln = oln + [c + 1]
      l = strchars(el)
    endwhile
    nls = nls + [el]
    oln = oln + [c + 1]
    c = c + 1
  endwhile
enddef
# --------------------------------------------------------------------------------

# CONVERT LIST -------------------------------------------------------------------
def ConvertList()
  AddSpacesToList()
  ChangeList()
  var mxl = len(nls)     # length of the list (max line numbers) 
  var fl = mxl - pl      # number of lines from left to the cursor position
  var lim = w / 2 - 4      # the display character length
  var ex = pl
  if ex > 5
    ex = 4
  endif
  if scrl == 0
    if fl > lim
      scrl = fl - lim + ex 
    else
      scrl = 0
    endif
  endif
  msc = mxl - lim 
  if msc < 0
    msc = 0
  endif
  ShowTate()
enddef
# --------------------------------------------------------------------------------  

# ADD SPACES TO LIST--------------------------------------------------------------
def AddSpacesToList()
  var lst = copy(nls)
  var nlst = mapnew(lst, (_, v) => strchars(v))
  var mxl = h - 2
  map(nls, (_, v) => AddSpaces(v, mxl))
enddef
# --------------------------------------------------------------------------------

# ADD SPACES ---------------------------------------------------------------------
# INPUTS
# str : string (element of the list (nls))
# mxl : max length of the list (nls)
def AddSpaces(str: string, mxl: number): string
  const l = strchars(str)
  const spn = mxl - l
  const sp = repeat(' ', spn)  # space code 32 
  return (str .. sp)
enddef
# OUTPUT
# str . sp : new element of the list which is the same length with mxl
# --------------------------------------------------------------------------------

# CHANGE LIST --------------------------------------------------------------------
def ChangeList()
  var c = 0
  tls = []
  var m = strchars(nls[0])
  while c < m 
    var lst = copy(nls)
    tls = add(tls, join(reverse(map(lst, (_, v) => ChangeChar(strcharpart(v, c, 1)))), ''))
    c = c + 1
  endwhile
enddef
# -------------------------------------------------------------------------------- 

# CHANGE CHAR --------------------------------------------------------------------
# INPUT
# ch : character of the element of the list (tls)
def ChangeChar(ch: string): string
  const dw = strdisplaywidth(ch) # display width of the character
  var cha = ch
  if dw == 1
    cha = cha .. ' '
  endif
  if cha == 'ー'
     cha = '｜'
  elseif cha == '( ' || cha == '（'
     cha = '⏜'              # 23dc (in insert mode Ctrl-v u and input this HEX)
  elseif cha == ') ' || cha == '）'
     cha = '⏝'              # 23dd
  elseif cha == '= '
     cha = '꯫'              # 2225 or a831, abeb, 2016 (using abeb) 
  elseif cha == '。'
     cha = '︒'              # fe12
  elseif cha == '、'
     cha = '︑'              # fe11
  #elseif cha=='：'
  #  cha = '‥ '
  #elseif cha=='「'
  #  cha = '⅂ '
  endif
  return cha 
enddef
# OUTPUT
# cha : new string for the input character
#       character display width = 1              => add space 
#       character is not for vertical expression => change character
# --------------------------------------------------------------------------------

# SHOW TATE ----------------------------------------------------------------------
def ShowTate()
  FitToWindow(w - 4)
  setline(2, fls)
  CursorSet()
enddef
# --------------------------------------------------------------------------------

# FIT TO WINDOW ------------------------------------------------------------------
# INPUTS
# wi  : displaying line width (string character width)
def FitToWindow(wi: number)
  var mcs = DisplayableLength(tls[0]) 
  var lst = copy(tls)
  map(lst, (_, v) => FitElmToWindow(v, mcs, wi))
  map(lst, (_, v) => '  ' .. v)  # add 2 spaces at the first of each element of the list
  fls = lst + [repeat(' ', (wi - 2))]
enddef
# --------------------------------------------------------------------------------

# DISPLAYABLE LENGTH -------------------------------------------------------------
# INPUT
# str : string
def DisplayableLength(str: string): number
  var i = 0
  var l = 0
  var ch: string
  var dw: number
  const mc = strchars(str) 
  while i < mc 
    ch = slice(str, i, i + 1)
    dw = strdisplaywidth(ch)
    l = l + dw
    i += 1
  endwhile
  return l
enddef
# OUTPUT
# l : sum of the display width
# --------------------------------------------------------------------------------

# FIT ELM TO WINOW ---------------------------------------------------------------
# INPUTS
# el : element of the list (tls)
# mcs : displayable length
# wi  : displaying line width (string character width)
def FitElmToWindow(el: string, mcs: number, wi: number): string
  var nel: string
  var ch: string
  var dw: number
  var sl: number
  if mcs > wi
    nel = '' 
    var c = 0
    var n = 0
    while n < (wi / 2 - 2 + scrl)
      ch = el[c]
      sl = strlen(ch)
      if sl == 1                      # if string byte length is 1
        ch = el[c : c + 1]            # there is a space just right to the character 
        c = c + 2                     # so these two characters should be in
      else
        dw = strdisplaywidth(ch)       
         if dw == 1                   # if string display width is 1 and byte length isn't 1
           ch = ch .. ' '             # a space should be add and change display width to 2 
           c = c + 1
         else
          c = c + 1
         endif
      endif
      n = n + 1
      if n > scrl
        nel = nel .. ch
      endif
    endwhile
  elseif mcs < wi
    nel = repeat(' ', (wi - mcs - 4)) .. el 
  else 
    nel = el
  endif
  return nel 
enddef
# OUTPUT
# nel : new element with length fit to the window column size 
# --------------------------------------------------------------------------------

# CURSOR SET ---------------------------------------------------------------------
def CursorSet()
  var co = GetGyou()
  cy = px + 1
  cursor(cy, 1)
  cx = col('$') - co
  cursor(cy, cx)
enddef
# --------------------------------------------------------------------------------

# GET GYOU
def GetGyou(): number
  var str = fls[px - 1]
  var dlp = pl - msc + scrl
  var sl = strchars(str)
  var co = 0
  var n = 0
  var ch: string
  var tch: string
  while n < dlp
    ch = slice(str, sl - 1, sl)
    n = n + 1
    if ch == ' '
      tch = slice(str, sl - 2, sl - 1)  # character in front of the space 
      co = co + 1 + len(tch)        # add character bytes and the byte of the space 
      sl = sl - 2
    else
      co = co + 3       # add 3 bytes when displaywidth is 2 
      sl = sl - 1
    endif
  endwhile
  return co
enddef
# OUTPUT
# co : column length from the right limit to the cursor position  
# --------------------------------------------------------------------------------

# CREATE FIELD ------------------------------------------------------------------
def CreateField()
  enew!
  set nonumber
  set nofoldenable
  set scrolloff=0
  const ls = repeat([' '], h - 1)
  append(1, ls)
  bp!
enddef
# --------------------------------------------------------------------------------

# CONV POS -----------------------------------------------------------------------
def ConvPos()
  const ml = h - 2  # max length
  y = oln[pl - 1]
  var i = 1
  x = px  
  while oln[pl - 1 - i] == y && (pl - i) > 0 
    x = x + ml
    i = i + 1
    if (pl - 1 - i) < 0
      break
    endif
  endwhile
enddef
# --------------------------------------------------------------------------------

def UpdateText(bli: bool)                     # bli : leave insert mode or not
  var icr = px != (line('.') - 1)             # whether <CR> is entered or not
  var tl: string
  var tnl: string
  var heads: string
  var tail: string
  ConvPos()
  if icr 
    bcr = true
    setline(len(fls) + 2, " ")
    tl = bls[y - 1]
    heads = slice(tl, 0, x - 1)
    tail = slice(tl, x - 1) 
    if y == 1
      bls = [heads, tail] + bls[y :]
    else
      bls = bls[0 : y - 2] + [heads, tail] + bls[y :]
    endif
    x = 1
    y = y + 1
  else
    if !bli
      var ol = fls[px - 1]
      var nl = getline('.')
      var df = strchars(nl) - strchars(ol)  # character length of the input
      var ibs = df < 0                    # whether <BS> is entered or not 
      if ibs && !bcr
        tl = bls[y - 1]
        if x == 1
          if y == 1
            bls = [" "]
          else
            bls = bls[0 : y - 2] + bls[y :]
            x = strchars(bls[y - 2]) + 1 
            y = y - 1
          endif
       else
          heads = slice(tl, 0, x - 2)
          tail = slice(tl, x - 1) 
          tnl = heads .. tail
          if y == 1
            if x == 2
              bls = [" "] + bls[y :]
            else
              bls = [tnl] + bls[y :]
            endif
          else
            bls = bls[0 : y - 2] + [tnl] + bls[y :]
          endif
          x = x - 1 
        endif
      else
        var str = ""
        var i = 0
        if ol != nl
          while slice(ol, i, i + 1) == slice(nl, i, i + 1)
            i += 1  
          endwhile
          str = slice(nl, i, i + df)      # input string 
        endif
        tl = bls[y - 1]
        heads = slice(tl, 0, x - 1)
        var lnl = strchars(tl)
        if lnl < x
          str = repeat(' ', x - lnl - 1) .. str
        endif
        tail = slice(tl, x - 1) 
        tnl = heads .. str .. tail      # new vertical line 
        if y == 1
          bls = [tnl] + bls[y :]
        else
          bls = bls[0 : y - 2] + [tnl] + bls[y :]
        endif
        x = x + df
      endif
    endif
    bcr = false
  endif
  ChangeToTate()
  var status = "pl=" .. pl .. " px=" .. px .. " cy=" .. cy .. " cx=" .. cx .. " s=" .. scrl .. " m=" .. msc
  setline(1, status)
enddef

def MoveCursor()
  var cpos = getcurpos()
  const ncy = cpos[1]
  const ncx = cpos[2]
  if cy > ncy                   # cursor move up
    px = px - 1
    if ncy == 1
      px = 1
    endif
    CursorSet()
  elseif cy < ncy               # cursor move down
    px = px + 1
    if ncy == h
      px = px - 1
    endif
    CursorSet() 
  elseif cx > ncx               # cursor move left
    if ncx > 2
      pl = pl + 1
    endif
    if scrl > 0 && ncx < 10
      scrl = scrl - 1
      ShowTate()
    else
      if pl > len(nls)
        pl = pl - 1
      endif
      CursorSet()
    endif
  elseif cx < ncx             # cursor move right
    pl = pl - 1
    if msc > scrl && ncx > (col('$') - 10)
      scrl = scrl + 1
      ShowTate()
    else
      if pl == 0
        pl = pl + 1
        cx = cx + 1
      endif
      CursorSet()
    endif
  endif
  var status = "pl=" .. pl .. " px=" .. px .. " cy=" .. cy .. " cx=" .. cx .. " s=" .. scrl .. " m=" .. msc
  setline(1, status)
enddef

def ta#TateStart()
  bls = getline(1, line("$"))  # set all lines of the original buffer to a list 
  #map(bls, (_, v) => v .. ' ')   # add space to all elements of the list 
  command! Tateq call TateEnd()
  command! Tatec call TateChange()
  command! Tatei call TateIndexStart()
  command! Tatea call TateIndexAdd()
  command! Tater call TateRubiStart()
  command! Taten call NewLine()
  command! Tated call DelLetter()
  y = line('.')       # the current line which is on the cursor 
  x = charcol('.')    # character index of the line where the cursor is exist 
  pl = 0
  px = 0
  scrl = 0
  # create new buffer, make empty lines and return to the original buffer 
  CreateField() 
  bn!                               # move to the buffer created for vertical input
  nnoremap <buffer> q :Tateq
  nnoremap <buffer> w :Tatec
  nnoremap <buffer> [ :Tatei
  nnoremap <buffer> ] :Tatea
  nnoremap <buffer> o :Taten<CR>
  nnoremap <buffer> x :Tated<CR> 
  vnoremap <buffer> <expr> r feedkeys('y:Tater<CR>') 
  ChangeToTate()
  augroup Tate 
    autocmd!
    autocmd InsertLeave * UpdateText(true)
    autocmd TextChangedI * UpdateText(false)
    autocmd CursorMoved * MoveCursor()
  augroup END
enddef

def NewLine()
  TateChange()
  feedkeys("o\<Esc>")
  feedkeys(":Ta\<CR>i")
enddef

def DelLetter()
  feedkeys("hji\<BS>")
  UpdateText(false)
enddef

def AppendRubi(moji: string)
  var l = strchars(moji)
  var rb = input(moji .. ':')
  if rb == ' '
    rb = ''
  endif
  var rblist = split(rb, ' ')
  var lr = len(rblist)
  var str = ''
  var i = 0
  var irb = ''
  while l > 0
    if lr > i
      irb = '：' .. rblist[i] .. '：'
    else
      irb = ''
    endif
    str = str .. strcharpart(moji, i, 1) .. irb 
    i = i + 1
    l = l - 1
  endwhile
  @" = str
  feedkeys('P') 
  echo ".. :push enter"
enddef

def TateRubiStart()
  var rg = @"
  var rgl = split(rg, '\n')
  map(rgl, (_, v) => slice(v, -1))
  rg = join(rgl, '')
  var chlen = strchars(rg)
  var lmov = 0
  if chlen > 2
    lmov = chlen - 2
  endif
  if chlen == 1
    pl = pl - 1
  endif
  TateChange()
  command! -nargs=1 Rubia call s:AppendRubi(<args>)
  vnoremap <buffer> r d<Esc>:Rubia '<C-R>"'<CR> 
  if chlen == 1
    feedkeys('vr')
  elseif chlen == 2
    feedkeys('vlr')
  else
    feedkeys(lmov .. 'hv' .. (chlen - 1) .. 'lr')
  endif
  nnoremap <buffer> <CR> :Ta<CR>
enddef

def IndexLine(ind: number, str: string): list<any>
  var n = strchars(str)
  var rin = 0
  var rsl = ""
  var tstr = str
  var lch = ""
  while n > 0
    n = n - 1
    lch = slice(tstr, -1)
    if lch == ' '
      tstr = slice(tstr, 0, n)
    elseif lch == ':'
      rin = ind
      rsl = tstr
    else
      n = 0
    endif
  endwhile
  return [rin, rsl] 
enddef

def IndexText(ls: list<string>): list<any>
  var i = 1
  var rl = []
  for val in ls
    rl = IndexLine(i, val)
    if rl[1] != ""
      add(iils, i)
      add(inls, val)
    endif
    i += 1
  endfor
  return [iils, inls]
enddef

def LineType(str: string): string 
  var n = strchars(str)
  var tstr = str
  var lch = ""
  while n > 0
    lch = slice(tstr, -1)
    if lch == ' '
      tstr = slice(tstr, 0, n)
      n = n - 1
    elseif lch == ':'
      n = -2
    else
      n = -1 
    endif
  endwhile
  if n == 0
    tstr = ' '
  elseif n == -1
    tstr = ''
  endif
  return tstr
enddef

def TateIndexShow()
  iils = []
  inls = []
  bls = getline(1, line("$"))
  enew!
  var result = IndexText(bls)
  iils = result[0]
  inls = result[1]
  append(0, inls)
  cursor(1, 1)
enddef

def TateIndexStart()
  TateChange()
  TateIndexShow()
  ta#TateStart()
  command! Tatej call TateIndexJump()
  nnoremap <buffer> [ :Tatej
enddef

def TateIndexAdd()
  TateChange()
  var ind = input('Index Name = ')
  var lnum = line('.')
  var li = getline(lnum)
  var tstr = LineType(li) 
  while tstr == '' 
    lnum -= 1
    if lnum == 0
      tstr = ' '
    else
      li = getline(lnum)
      tstr = LineType(li)
    endif
  endwhile
  if tstr == ' '
    append(lnum, (ind .. ':'))
  else
    setline(lnum, (ind .. ':'))
  endif
  ta#TateStart()
enddef

def TateIndexJump()
  TateEnd()
  TateIndexShow() 
  cursor(pl, 1)
  var l = line('.')
  bd!
  cursor(iils[l - 1], 1)
  delcommand Tatej
  ta#TateStart()
enddef

def TateChange()
  augroup Tate 
    autocmd!
  augroup END
  ConvPos()
  bd!                     # return the original buffer
  # clear the buffer
  normal 1G
  normal dG 
  append(0, bls)     # append new data
  normal G
  normal dd          # delete the last line
  setcursorcharpos(y, x)
  delcommand Tateq
  delcommand Tatec
  mapclear
enddef

def TateEnd()
  augroup Tate 
    autocmd!
  augroup END
  bd!
  delcommand Tateq
  delcommand Tatec
  mapclear
enddef

var h = winheight(0)  # height of the window 
var w = winwidth(0)   # width of the window 
var bls: list<string>
var nls: list<string>
var tls: list<string>
var fls: list<string>
var y: number
var x: number
var cy: number
var cx: number
var pl: number
var px: number
var scrl: number
var msc: number
var oln: list<number>
var bcr = false     # whether Enter Key is pushed
var iils: list<number>
var inls: list<string>
