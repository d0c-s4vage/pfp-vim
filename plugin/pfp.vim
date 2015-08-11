" # PFP - Python Format Parser (vim plugin)
" @d0c_s4vage
"
"

function! DefinePfp()
python <<EOF

import glob
import json
import os
import pfp
import re
import sys

import vim

def _input(message = 'input'):
	vim.command('call inputsave()')
	vim.command("let user_input = input('" + message + ": ')")
	vim.command('call inputrestore()')
	return vim.eval('user_input')

class Colors:
	HEADER = '\033[95m'
	OKBLUE = '\033[94m'
	OKGREEN = '\033[92m'
	WARNING = '\033[93m'
	FAIL = '\033[91m'
	ENDC = '\033[0m'

def buff_exists(name):
	"""
	Return true or false if the buffer named `name` exists
	"""
	return buffwinnr(name) != -1

def buff_clear():
	vim.command("silent %delete _")

def buff_puts(msg, clear=True):
	vim.command("setlocal modifiable")
	if clear:
		buff_clear()
	count = 0
	for line in msg.split("\n"):
		vim.command("let tmp='" + line.replace("'", "' . \"'\" . '") + "'")
		if count == 0 and clear:
			vim.command("silent! 0put=tmp")
		else:
			vim.command("silent! put=tmp")
		count += 1

def _msg(char, msg, pre="[", post="]", color=None):
	if False and color is not None:
		pre = color + pre
		post = post + Colors.ENDC

	for line in msg.split("\n"):
		print("{pre}{char}{post} {line}".format(
			pre=pre,
			char=char,
			post=post,
			line=line
		))

def err(msg):
	_msg("X", msg, color=Colors.FAIL)

def log(msg):
	_msg(" ", msg, color=Colors.OKBLUE)

def info(msg):
	_msg("+", msg, color=Colors.OKBLUE)

def warn(msg):
	_msg("!", msg, color=Colors.WARNING)

def ok(msg):
	_msg("✓", msg, color=Colors.OKGREEN)

def create_scratch(text, fit_to_contents=True, return_to_orig=False, scratch_name="__PFP_DOM__", retnr=-1, set_buftype=True, width=50, wrap=False, modify=False):
	if buff_exists(scratch_name):
		buff_close(scratch_name, delete=True)

	if fit_to_contents:
		max_line_width = max(len(max(text.split("\n"), key=len)) + 4, 30)
	else:
		max_line_width = width
	
	orig_buffnr = winnr()
	orig_range_start = vim.current.range.start
	orig_range_end = vim.current.range.end

	vim.command("silent keepalt botright vertical {width}split {name}".format(
		width=max_line_width,
		name=scratch_name
	))
	count = 0

	buff_puts(text)

	vim.command("let b:pfp_dom_last_line = ''")
	vim.command("let b:retnr = " + str(retnr))

	# these must be done AFTER the text has been set (because of
	# the nomodifiable flag)
	if set_buftype:
		vim.command("setlocal buftype=nofile")

	vim.command("setlocal bufhidden=hide")
	vim.command("setlocal nobuflisted")
	vim.command("setlocal noswapfile")
	vim.command("setlocal noro")
	vim.command("setlocal nolist")
	vim.command("setlocal winfixwidth")
	vim.command("setlocal textwidth=0")
	vim.command("setlocal nospell")
	vim.command("setlocal nonumber")
	if wrap:
		vim.command("setlocal wrap")
	
	if not modify:
		vim.command("setlocal nomodifiable")
	
	if return_to_orig:
		win_goto(orig_buffnr)

def winnr():
	"""
	"""
	return int(vim.eval("winnr()"))

def win_goto(nr):
	vim.command("execute '{nr}wincmd w'".format(nr=nr))

def buffwinnr(name):
	"""
	"""
	return int(vim.eval("bufwinnr('" + name + "')"))

def move_to(line, column):
	vim.eval("setpos('.', [0,{},{}])".format(
		line,
		column
	))

# ---------------------------------------

PFP_CONFIG = {}
def pfp_init(prompt_for_path=False):
	global PFP_CONFIG

	config_file = os.path.expanduser(os.path.join("~", ".pfp"))

	if not os.path.exists(config_file) or prompt_for_path:
		path = _input("Where are your templates at? (a path)")
		PFP_CONFIG.setdefault("template_dirs", []).append(path)
		with open(config_file, "w") as f:
			f.write(json.dumps(PFP_CONFIG))
	else:
		with open(config_file, "r") as f:
			PFP_CONFIG = json.loads(f.read())

def pfp_cursor_moved():
	pass

def pfp_choose_template():
	pfp_init()

	print("Choose the template to parse with (*.bt):")
	template_dirs = PFP_CONFIG.setdefault("template_dirs", []) + [os.getcwd()]

	templates = []
	for template_dir in template_dirs:
		templates += glob.glob(os.path.join(os.path.expanduser(template_dir), "*.bt"))
	
	for idx,template in enumerate(templates):
		print("[{:2d}] {}".format(idx, template))
	
	template_idx = int(_input("template #"))
	if template_idx < 0 or template_idx > len(templates):
		err("Invalid template idx, try again some other time")
		return None
	
	return templates[template_idx]

def pfp_format_hex_line(data):
	# e.g "00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff"
	parts = ["{:02x}".format(ord(data[x:x+1])) for x in range(len(data))]
	if len(parts) != 0x10:
		parts += ["  "] * (0x10 - len(parts))
	return " ".join(parts)

PY3 = sys.version_info[0] == 3
PY2 = sys.version_info[0] == 2
def pfp_data_to_str(data):
	if PY3 and hasattr(data, "decode"):
		return data.decode("utf-8")
	else:
		return data

def pfp_printable_line(data):
	if PY3:
		res = b""
	else:
		res = ""
	for x in range(len(data)):
		char = data[x:x+1]
		val = ord(char)
		if 0x20 <= val <= 0x7e:
			res += char
		else:
			if PY3:
				res += b"."
			else:
				res += "."
	
	if len(res) < 0x10:
		if PY3:
			res += b" " * (0x10 - len(res))
		else:
			res += " " * (0x10 - len(res))

	res = pfp_data_to_str(res)
	
	return res

def pfp_hex_dump_file(filename):
	hex_lines = ["     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f                  "]
	hex_lines.append("     -----------------------------------------------                 ")
	with open(filename, "rb") as f:
		count = 0
		while True:
			data = f.read(0x10)
			formatted = pfp_format_hex_line(data)
			printable = pfp_printable_line(data)
			hex_lines.append("{:04x} {} {}".format(
				count*0x10,
				formatted,
				printable
			))
			count += 1
			if len(data) != 0x10:
				break

	buff_puts("\n".join(hex_lines))

def pfp_parse(): 
	vim.command("silent! set noeol")
	vim.command("silent! set binary")
	curr_file = vim.current.buffer.name
	if curr_file.startswith("__PFP_HEX__"):
		curr_file = vim.eval("b:pfp_orig_file")

	vim.command("tabnew")
	vim.command("setlocal nolist")
	vim.command("setlocal nospell")
	vim.command("setlocal nonumber")
	vim.command("setlocal noswapfile")
	vim.command("setlocal nobuflisted")
	vim.command("setlocal bufhidden=hide")
	vim.command("setlocal buftype=nofile")
	vim.command("let b:pfp_orig_file = '" + curr_file + "'")
	vim.command("set filetype=pfp_hex")
	vim.command("set syntax=pfp_hex")

	count = 0
	count_str = ""
	while True:
		try:
			name = "__PFP_HEX__\\ " + curr_file.replace(" ", "\\ ") + count_str
			vim.command("file " + name)
			break
		except:
			count += 1
			count_str = "\\ " + str(count)

	curr_winnr = vim.current.window.number
	if not os.path.exists(curr_file):
		err("could not locate file {}".format(curr_file))
		return
	
	template_path = pfp_choose_template()
	if template_path is None:
		return
	if not os.path.exists(template_path):
		err("could not locate template {}".format(template_path))
		return
	
	pfp_hex_dump_file(curr_file)

	dom = pfp.parse(data_file=curr_file, template_file=template_path, int3=False)

	total_width = 0
	for window in vim.windows:
		total_width += window.width

	create_scratch(
		dom._pfp__show(include_offset=True),
		width = int(total_width/2), # yes, explicitly make it an int b/c of python3
		fit_to_contents = False,
		scratch_name = name.replace("__PFP_HEX__", "__PFP__DOM__")
	)

	vim.command("set syntax=pfp_dom")
	vim.command("set cursorline")
	vim.command("let b:winnr = {}".format(curr_winnr))
	# go to the top
	vim.command("normal! gg")
	vim.command("set filetype=pfp_dom")
	vim.command("set syntax=pfp_dom")

def pfp_getline(line=None):
	this_buffer = vim.current.buffer.number
	if line is None:
		line,_ = vim.current.window.cursor
	res = vim.eval("getbufline({}, {})".format(this_buffer, line))
	if len(res) == 0:
		return None
	else:
		return res[0]

def pfp_get_space_and_offset(lineno):
	line = pfp_getline(lineno)
	if line is None:
		return None
		
	match = re.match(r'^(\s*)([0-9a-fA-F]{4,}).*', line)

	if match is not None:
		spacing = match.group(1)
		offset = int("0x" + match.group(2), 16)
		return (spacing, offset)
	else:
		return (None, None)

def pfp_highlight(start_line, end_line, start_col, end_col):
	vim.eval("matchadd('pfp_hex_selection', '\\%>{start_line}l\\%<{end_line}l\\%>{start_col}c\\%<{end_col}c')".format(
		start_line=start_line-1,
		end_line=end_line+1,
		start_col=start_col,
		end_col=end_col+3
		)
	)

def pfp_hex_allign_x(address):
	start_offset = max(4, len(hex(address)) - 2) + 1
	return (address % 0x10) * 3 + start_offset

def pfp_hex_allign_y(address):
	return address // 0x10 + 3

def pfp_hex_match_range(s_offset, e_offset):
	"""
	match the area in the hex buffer between s_offset and e_offset 

	"""
	if s_offset % 0x10 != 0:
		if pfp_hex_allign_y(s_offset) == pfp_hex_allign_y(e_offset): #start and end on the same line
			pfp_highlight(
				pfp_hex_allign_y(s_offset),
				pfp_hex_allign_y(e_offset),
				pfp_hex_allign_x(s_offset),
				pfp_hex_allign_x(e_offset)
			)
			return
		else: #start and end on different lines
			pfp_highlight(
				pfp_hex_allign_y(s_offset),
				pfp_hex_allign_y(s_offset),
				pfp_hex_allign_x(s_offset),
				pfp_hex_allign_x(s_offset|0xf)
			)
			pfp_hex_match_range((s_offset|0xf) + 1, e_offset) #calls itself to procede drawing further than first line
			return

	if (e_offset + 1) % 0x10 != 0: # is the end offset alligned?
		pfp_highlight(
			pfp_hex_allign_y(e_offset),
			pfp_hex_allign_y(e_offset),
			pfp_hex_allign_x((e_offset|0xf) - 0xf),
			pfp_hex_allign_x(e_offset)
		)
		pfp_hex_match_range(s_offset, (e_offset|0xf) - 0x10) # calss itself to match the rest of the area
		return

	# is start offset in hex the same length as end offset? if not split in two and draw separately
	if max(4, len(hex(s_offset)) - 2) != max(4, len(hex(e_offset)) - 2):
		next_block = 1 << (4 * max(4, len(hex(s_offset)) - 2))
		pfp_hex_match_range(s_offset, next_block - 1)
		pfp_hex_match_range(next_block, e_offset)
		return
	else:
		pfp_highlight(
			pfp_hex_allign_y(s_offset),
			pfp_hex_allign_y(e_offset),
			pfp_hex_allign_x(s_offset),
			pfp_hex_allign_x(e_offset)
		)
		return

def pfp_dom_cursor_moved():
	line,_ = vim.current.window.cursor
	spacing,offset = pfp_get_space_and_offset(line)

	if spacing is None:
		return

	end_offset = 0xffff
	while True:
		line += 1

		line_info = pfp_get_space_and_offset(line)
		if line_info is None:
			break

		next_spacing, next_offset = line_info
		if next_spacing is None:
			continue

		# we've reached the next one at the same level
		if len(next_spacing) <= len(spacing) and next_offset >= offset:
			end_offset = next_offset
			# bitfields?
			if end_offset == offset:
				end_offset += 1
			break
	
	winnr = int(vim.eval("b:winnr"))
	curr_winnr = vim.current.window.number

	win_goto(winnr)
        start_line, start_col = pfp_hex_allign_y(offset), pfp_hex_allign_x(offset)
	vim.eval("clearmatches()")
	move_to(start_line, start_col)
	vim.command("silent! normal! zz")

        if offset < end_offset:
            pfp_hex_match_range(offset, end_offset-1)
        else: # sometimes this happens
            pfp_hex_match_range(offset, offset)

	win_goto(curr_winnr)

EOF
endfunction

call DefinePfp()

function! PfpHandleCursorMoved()
	if &ft ==# 'pfp_dom'
		if b:pfp_dom_last_line != line('.')
			py pfp_dom_cursor_moved()
			let b:pfp_dom_last_line = line('.')
		endif
	elseif &ft ==# 'pfp_hex'
		echo "hex"
	endif
endfunction

function! DefinePfpAutoCommands()
	augroup Pfp!
		autocmd!
		autocmd CursorMoved * call PfpHandleCursorMoved()
	augroup END
endfunction

call DefinePfpAutoCommands()

highlight pfp_hex_selection ctermfg=red ctermbg=black

" -------------------
" -------------------

" load/init ~/.pfp
command! -nargs=0 PfpInit py pfp_init(True)

" parse the current file
command! -nargs=0 PfpParse py pfp_parse()
