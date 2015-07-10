
if exists("b:current_syntax")
	finish
endif

syntax match PfpOffset '\v^\s*[a-fA-F0-9]+'
syntax match PfpFieldName '\v[a-zA-Z_][a-zA-Z_0-9]*'
syntax match PfpFieldValue '=.*$'

highlight default link PfpOffset Statement
highlight default link PfpFieldName Identifier
highlight default link PfpFieldName Comment


let b:current_syntax = "pfp_dom"
