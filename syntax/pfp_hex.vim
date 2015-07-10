
if exists("b:current_syntax")
	finish
endif

syntax match PfpHexHeader '\v0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f'
syntax match PfpHexHeader2 '-----------------------------------------------'
syntax match PfpAddress '\v^[a-fA-F0-9]{4,} '
syntax match PfpPrintable '\v(^.{53})@<=.*$'

highlight default link PfpHexHeader Statement
highlight default link PfpHexHeader2 Comment
highlight default link PfpAddress Statement
highlight default link PfpPrintable Comment


let b:current_syntax = "pfp_hex"
