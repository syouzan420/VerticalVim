vim9script noclear
scriptencoding utf-8
# AUTHOR: yokoP <teruyokoP@gmail.com>
# MAINTAINER: yokoP
# License: This file is placed in the public domain.

if exists('g:loaded_ta')
  finish
endif

g:loaded_ta = 1
command! Ta call TateStart()

# GLOBAL VARIABLES ---------------------------------------------------
var h = winheight(0)  # height of the window 
var w = winwidth(0)   # width of the window (max string display width of the window)
var bls: list<string> # all lines of the original buffer
var nls: list<string> # list which length is limited to (h-2) (max line displayed)
var tls: list<string> # list of each element corresponds to the displayable line
var fls: list<string> # list of each element displayed now in Vertical Mode
var y: number         # the current line which is on the cursor 
var x: number         # character index of the line where the cursor is exist
var cy: number        # cursor position y (Vertical Mode)
var cx: number        # cursor position x (Vertical Mode)
var pl: number        # index of the list (nls) corresponds to the cursor position
var px: number        # index of the element of the list (nls) corresponds to the cursor position
var scrl: number      # not-displayed character length of each element of the list (tls)
var msc: number
var oln: list<number> # list of each number (element) is corresponds to the line number of the original list (bls) (this list's length is the same as the nls list)
var bcr = false     # whether Enter Key is pushed
var iils: list<number> # index number list
var inls: list<string> # index name list
# --------------------------------------------------------------------

# CHANGE TO TATE -----------------------------------------------------
def ChangeToTate(l_w: number, l_h: number, l_x: number, l_y: number, l_scrl: number, l_msc: number, l_bls: list<string>): list<any>
  var l_pl: number
  var l_px: number
  var l_cy: number
  var l_cx: number
  var l_nls: list<string>
  var l_tls: list<string>
  var l_fls: list<string>
  var l_oln: list<number>
  var n_scrl: number
  var n_msc: number
  [l_pl, l_px, l_nls, l_tls, l_oln] = ConvertList(l_w, l_h, l_x, l_y, l_scrl, l_msc, l_bls)
  [n_scrl, n_msc] = SetScroll(l_w, l_pl, l_scrl, l_msc, l_nls)
  [l_cy, l_cx, l_fls] = ShowTate(l_w, l_pl, l_px, n_scrl, n_msc, l_tls)
  return [l_pl, l_px, l_cy, l_cx, n_scrl, n_msc, l_nls, l_tls, l_fls, l_oln]
enddef
# --------------------------------------------------------------------

# CONVERT LIST ------------------------------------------------PURE---
def ConvertList(l_w: number, l_h: number, l_x: number, l_y: number, l_scrl: number, l_msc: number, l_bls: list<string>): list<any>
  var l_pl: number
  var l_px: number
  var l_nls: list<string>
  var l_oln: list<number>
  [l_pl, l_px, l_nls, l_oln] = MakeLimitedStringList(l_h - 2, l_x, l_y, l_bls)
  l_nls = AddSpacesToList(l_h, l_nls)
  var l_tls = ChangeList(l_nls)
  return [l_pl, l_px, l_nls, l_tls, l_oln]
enddef
# --------------------------------------------------------------------  

# MAKE LIMITED STRING LIST ------------------------------------PURE---
def MakeLimitedStringList(hi: number, l_x: number, l_y: number, l_bls: list<string>): list<any>
  var c = 0
  var l_pl = l_y
  const plf = l_pl
  var l_px = l_x
  var l_nls = []
  var l_oln = []              # original line number 
  var m = len(l_bls)
  while c < m
    var el = l_bls[c]
    var l = strchars(el)
    while l > hi
      if c + 1 < plf
        l_pl = l_pl + 1
      elseif (c + 1 == plf) && (l_px > hi)
        l_pl = l_pl + 1
        l_px = l_px - hi
      endif
      var fst = slice(el, 0, hi)
      el = slice(el, hi)
      l_nls = l_nls + [fst]
      l_oln = l_oln + [c + 1]
      l = strchars(el)
    endwhile
    l_nls = l_nls + [el]
    l_oln = l_oln + [c + 1]
    c = c + 1
  endwhile
  return [l_pl, l_px, l_nls, l_oln]
enddef
# --------------------------------------------------------------------

# SET SCROLL---------------------------------------------------PURE---
def SetScroll(l_w: number, l_pl: number, l_scrl: number, l_msc: number, l_nls: list<string>): list<number>
  var n_scrl = l_scrl 
  var n_msc = l_msc
  var mxl = len(l_nls)     # length of the list (max line numbers) 
  var fl = mxl - l_pl      # number of lines from left to the cursor position
  const lim = l_w / 2 - 4      # the display character length
  var ex = l_pl
  if ex > 5
    ex = 4
  endif
  if n_scrl == 0
    if fl > lim
      n_scrl = fl - lim + ex 
    else
      n_scrl = 0
    endif
  endif
  n_msc = mxl - lim
  if n_msc < 0
    n_msc = 0
  endif
  return [n_scrl, n_msc]
enddef
# --------------------------------------------------------------------

# ADD SPACES TO LIST-------------------------------------------PURE---
def AddSpacesToList(l_h: number, l_nls: list<string>): list<string>
  var lst = copy(l_nls)
  var nlst = mapnew(lst, (_, v) => strchars(v))
  var mxl = l_h - 2
  map(l_nls, (_, v) => AddSpaces(v, mxl))
  return l_nls
enddef
# --------------------------------------------------------------------

# ADD SPACES --------------------------------------------------PURE---
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
# --------------------------------------------------------------------

# CHANGE LIST -------------------------------------------------PURE---
def ChangeList(l_nls: list<string>): list<string>
  var c = 0
  var l_tls = []
  var m = strchars(l_nls[0])
  while c < m 
    var lst = copy(l_nls)
    l_tls = add(l_tls, join(reverse(map(lst, (_, v) => ChangeChar(strcharpart(v, c, 1)))), ''))
    c = c + 1
  endwhile
  return l_tls
enddef
# -------------------------------------------------------------------- 

# CHANGE CHAR -------------------------------------------------PURE---
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
     cha = '⏜'              
  elseif cha == ') ' || cha == '）'
     cha = '⏝'              
  elseif cha == '= '
     cha = 'ǁ'  #strlen:2 ,strdisplaywidth:1
    # cha = '∥'
    # cha = '꯫'               
  elseif cha == '。'
     cha = '๏'       #strlen:3, strdisplaywidth:1       
     #cha = 'ⵙ'               
  elseif cha == '、'
     cha = '︑'  #strlen:3, strdisplaywidth:2             
  elseif cha == ': '
     #cha = '..'
     #cha = '〰'
     #cha = 'ⵆ'
     #cha = '꓆'
     #cha = '¨'
     cha = '⠉' #strlen:3, strdisplaywidth:1
  elseif cha == '：'
    cha = '⚋' #strlen:3, strdisplaywidth:1
  elseif cha == '「'
    cha = '⅂' #strlen:3, strdisplaywidth:1
  elseif cha == '〜'
    cha = '⟅' #strlen:3, strdisplaywidth:1
  elseif cha == '. '
    cha = '⠁' #strlen:3, strdisplaywidth:1
    #cha = '・'
  elseif cha == '{ '
    cha = '⏞' #strlen:3, strdisplaywidth:1
  elseif cha == '} '
    cha = '⏟'
  elseif cha == '＜'
    cha = 'ⴷ' #strlen:3, strdisplaywidth:1
  elseif cha == '＞'
    cha = 'ⴸ'
  endif
  return cha 
enddef
# OUTPUT
# cha : new string for the input character
#       character display width = 1              => add space 
#       character is not for vertical expression => change character
# --------------------------------------------------------------------

# SHOW TATE -----------------------------------------------------IO---
def ShowTate(l_w: number, l_pl: number, l_px: number, l_scrl: number, l_msc: number, l_tls: list<string>): list<any>
  var l_fls = FitToWindow(l_w - 4, l_scrl, l_tls)
  setline(2, l_fls)
  var l_cy: number
  var l_cx: number
  [l_cy, l_cx] = CursorSet(l_pl, l_px, l_scrl, l_msc, l_fls)
  return [l_cy, l_cx, l_fls]
enddef
# --------------------------------------------------------------------

# FIT TO WINDOW -----------------------------------------------PURE---
def FitToWindow(wi: number, l_scrl: number, l_tls: list<string>): list<string>
  var mcs = DisplayableLength(l_tls[0]) 
  var lst = copy(l_tls)
  map(lst, (_, v) => FitElmToWindow(v, mcs, wi, l_scrl))
  map(lst, (_, v) => '  ' .. v)  # add 2 spaces at the first of each element of the list
  var l_fls = lst + [repeat(' ', (wi - 2))]
  return l_fls
enddef
# --------------------------------------------------------------------

# DISPLAYABLE LENGTH ------------------------------------------PURE---
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
# --------------------------------------------------------------------

# FIT ELM TO WINOW --------------------------------------------PURE---
# INPUTS
# el : element of the list (tls)
# mcs : displayable length
# wi  : displaying line width (string character width)
def FitElmToWindow(el: string, mcs: number, wi: number, l_scrl: number): string
  var nel: string
  var ch: string
  var dw: number
  var sl: number
  if mcs > wi
    nel = '' 
    var c = 0
    var n = 0
    while n < (wi / 2 - 2 + l_scrl)
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
      if n > l_scrl
        nel = nel .. ch
      endif
    endwhile
  else
    nel = '' 
    var c = 0
    const l = strchars(el) 
    while c < l 
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
      nel = nel .. ch
    endwhile
    if mcs < wi
      nel = repeat(' ', (wi - mcs - 4)) .. nel 
    endif
  endif
  return nel 
enddef
# OUTPUT
# nel : new element with length fit to the window column size 
# --------------------------------------------------------------------

# CURSOR SET ----------------------------------------------------IO---
def CursorSet(l_pl: number, l_px: number, l_scrl: number, l_msc: number, l_fls: list<string>): list<number>
  var co = GetGyou(l_pl, l_px, l_scrl, l_msc, l_fls)
  var l_cy = l_px + 1
  cursor(l_cy, 1)
  var l_cx = col('$') - co
  cursor(l_cy, l_cx)
  return [l_cy, l_cx]
enddef
# --------------------------------------------------------------------

# GET GYOU ----------------------------------------------------PURE---
def GetGyou(l_pl: number, l_px: number, l_scrl: number, l_msc: number, l_fls: list<string>): number
  var str = l_fls[l_px - 1]
  var dlp = l_pl - l_msc + l_scrl
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
# --------------------------------------------------------------------

# CREATE FIELD --------------------------------------------------IO---
def CreateField(l_h: number)
  enew! 
  set nonumber
  set nofoldenable
  set scrolloff=0
  const ls = repeat([' '], l_h - 1)
  append(1, ls)
  bp!
enddef
# --------------------------------------------------------------------

# CONV POS ----------------------------------------------------PURE---
def ConvPos(l_h: number, l_pl: number, l_px: number, l_oln: list<number>): list<number>
  const ml = l_h - 2  # max length
  var n_y = l_oln[l_pl - 1]
  var i = 1
  var n_x = l_px  
  while l_oln[l_pl - 1 - i] == n_y && (l_pl - i) > 0 
    n_x = n_x + ml
    i = i + 1
    if (l_pl - 1 - i) < 0
      break
    endif
  endwhile
  return [n_x, n_y]
enddef
# --------------------------------------------------------------------

# UPDATE TEXT ----------------------------------------CHANGE GLOBAL---
# INPUT
# bli : leave insert mode or not 
def UpdateText(bli: bool)                     
  var icr = px != (line('.') - 1)             # whether <CR> is entered or not
  var tl: string
  var tnl: string
  var heads: string
  var tail: string
  [x, y] = ConvPos(h, pl, px, oln)
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
  [pl, px, cy, cx, scrl, msc, nls, tls, fls, oln] = ChangeToTate(w, h, x, y, scrl, msc, bls)
  var status = "pl=" .. pl .. " px=" .. px .. " cy=" .. cy .. " cx=" .. cx .. " s=" .. scrl .. " m=" .. msc
  setline(1, status)
enddef
# --------------------------------------------------------------------

# MOVE CURSOR ----------------------------------------CHANGE GLOBAL---
def MoveCursor()
  var cpos = getcurpos()
  const ncy = cpos[1]
  const ncx = cpos[2]
  if cy > ncy                   # cursor move up
    px = px - 1
    if ncy == 1
      px = 1
    endif
    [cy, cx] = CursorSet(pl, px, scrl, msc, fls)
  elseif cy < ncy               # cursor move down
    px = px + 1
    if ncy == h
      px = px - 1
    endif
    [cy, cx] = CursorSet(pl, px, scrl, msc, fls) 
  elseif cx > ncx               # cursor move left
    if ncx > 2
      pl = pl + 1
    endif
    if scrl > 0 && ncx < 10
      scrl = scrl - 1
      [cy, cx, fls] = ShowTate(w, pl, px, scrl, msc, tls)
    else
      if pl > len(nls)
        pl = pl - 1
      endif
      [cy, cx] = CursorSet(pl, px, scrl, msc, fls)
    endif
  elseif cx < ncx             # cursor move right
    pl = pl - 1
    if msc > scrl && ncx > (col('$') - 10)
      scrl = scrl + 1
      [cy, cx, fls] = ShowTate(w, pl, px, scrl, msc, tls)
    else
      if pl == 0
        pl = pl + 1
        cx = cx + 1
      endif
      [cy, cx] = CursorSet(pl, px, scrl, msc, fls)
    endif
  endif
  var status = "pl=" .. pl .. " px=" .. px .. " cy=" .. cy .. " cx=" .. cx .. " s=" .. scrl .. " m=" .. msc
  setline(1, status)
enddef
# --------------------------------------------------------------------

# TATE START --------------------------------------------------MAIN---
def TateStart()
  bls = getline(1, line("$"))  # set all lines of the original buffer to a list 
  y = line('.')       # the current line which is on the cursor 
  x = charcol('.')    # character index of the line where the cursor is exist 
  CreateField(h)    # create new buffer, make empty lines and return to the original buffer 
  bn!               # move to the buffer created for vertical input
  command! Tateq call TateEnd()
  command! Tatec call TateChange()
  command! Tatei call TateIndexStart()
  command! Tatea call TateIndexAdd()
  command! Tater call TateRubiStart()
  command! Taten call NewLine()
  command! Tated call DelLetter()
  nnoremap <buffer> q :Tateq
  nnoremap <buffer> w :Tatec
  nnoremap <buffer> [ :Tatei
  nnoremap <buffer> ] :Tatea
  nnoremap <buffer> o :Taten<CR>
  nnoremap <buffer> x :Tated<CR> 
  nnoremap <buffer> v <C-v>
  vnoremap <buffer> <expr> r feedkeys('y:Tater<CR>') 
  augroup Tate 
    autocmd!
    autocmd InsertLeave * UpdateText(true)
    autocmd TextChangedI * UpdateText(false)
    autocmd CursorMoved * MoveCursor()
  augroup END
  pl = 0
  px = 0
  scrl = 0
  [pl, px, cy, cx, scrl, msc, nls, tls, fls, oln] = ChangeToTate(w, h, x, y, scrl, msc, bls)
enddef

# NEW LINE -----------------------------------------------------COM---
def NewLine()
  TateChange()
  feedkeys("o\<Esc>")
  feedkeys(":Ta\<CR>i")
enddef
# --------------------------------------------------------------------

# DEL LETTER ---------------------------------------------------COM---
def DelLetter()
  var l = len(bls)
  var n = len(nls)
  [x, y] = ConvPos(h, pl, px, oln)
  var initL = slice(bls, 0, y - 1)
  var tgt = bls[y - 1]
  var tailL = slice(bls, y)
  var initT = slice(tgt, 0, x - 1)
  var tailT = slice(tgt, x)
  var ntgt = initT .. tailT
  bls = initL + [ntgt] + tailL
  [pl, px, cy, cx, scrl, msc, nls, tls, fls, oln] = ChangeToTate(w, h, x, y, scrl, msc, bls)
  var n2 = len(nls)
  if y > 1
    feedkeys("h")
  endif
  if n != n2
    scrl = scrl - 1
  endif
enddef
# --------------------------------------------------------------------

# APPEND RUBI --------------------------------------------------------
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
# --------------------------------------------------------------------

# TATE RUBI START ----------------------------------------------COM---
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
  command! -nargs=1 Rubia call AppendRubi(<args>)
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
# --------------------------------------------------------------------

# INDEX LINE --------------------------------------------------PURE---
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
      rsl = slice(tstr, 0, -1)
    else
      n = 0
    endif
  endwhile
  return [rin, rsl] 
enddef
# --------------------------------------------------------------------

# INDEX TEXT --------------------------------------------------PURE---
def IndexText(ls: list<string>): list<any>
  var i = 1
  var rl = []
  for val in ls
    rl = IndexLine(i, val)
    if rl[1] != ""
      add(iils, i)
      add(inls, rl[1])
    endif
    i += 1
  endfor
  return [iils, inls]
enddef
# --------------------------------------------------------------------

# LINE TYPE ---------------------------------------------------PURE---
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
# --------------------------------------------------------------------

# TATE INDEX SHOW ----------------------------------------------------
def TateIndexShow()
  iils = []
  inls = []
  bls = getline(1, line("$"))
  enew!
  [iils, inls] = IndexText(bls)
  append(0, inls)
  cursor(1, 1)
enddef
# --------------------------------------------------------------------

# TATE INDEX START ---------------------------------------------COM---
def TateIndexStart()
  TateChange()
  TateIndexShow()
  TateStart()
  command! Tatej call TateIndexJump()
  nnoremap <buffer> [ :Tatej
enddef
# --------------------------------------------------------------------

# TATE INDEX ADD -----------------------------------------------COM---
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
  TateStart()
enddef
# --------------------------------------------------------------------

# TATE INDEX JUMP ----------------------------------------------COM---
def TateIndexJump()
  TateEnd()
  TateIndexShow() 
  cursor(pl, 1)
  var l = line('.')
  bd!
  cursor(iils[l - 1], 1)
  delcommand Tatej
  TateStart()
enddef
# --------------------------------------------------------------------

# TATE CHANGE --------------------------------------------------COM---
def TateChange()
  augroup Tate 
    autocmd!
  augroup END
  [x, y] = ConvPos(h, pl, px, oln)
  bd!                     # return the original buffer
  # clear the buffer
  normal 1G
  normal dG 
  append(0, bls)     # append new data
  normal G
  normal dd
  setcursorcharpos(y, x)
  delcommand Tateq
  delcommand Tatec
  mapclear
enddef
# --------------------------------------------------------------------

# TATE END -----------------------------------------------------COM---
def TateEnd()
  augroup Tate 
    autocmd!
  augroup END
  bd!
  delcommand Tateq
  delcommand Tatec
  mapclear
enddef
# --------------------------------------------------------------------

