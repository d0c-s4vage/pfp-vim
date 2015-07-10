# pfp-vim

A vim hex-editor plugin that uses [010 templates](http://www.sweetscape.com/010editor/templates/) to parse binary data using [pfp](https://github.com/d0c-s4vage/pfp)

## Install

Clone this repo into `~/.vim/bundle`:

    git clone https://github.com/d0c-s4vage/pfp-vim.git ~/.vim/bundle/pfp-vim

Use your vim plugin manager (pathogen, etc) to load the plugin (you probably
already have this setup in your `~/.vimrc` or something:

	call pathogen#infect()

## Usage

With a binary file loaded in the current window, the `PfpParse` command
will parse the file.

You may be asked to specify a directory that contains your 010 templates
(looks for `*.bt` files).

You will also be asked which template should be used to parse the binary
file.

After choosing a template to use, a hex-view of the binary file will
be displayed in a new tab on the left, with the parsed-out fields
displayed on the right.

Navigating the data structure on the right will highlight the relevant
bytes in the hex-view on the left

## Notes

A `PfpInit` command also exists. This can be used to add additional
directories within which 010 templates will be searched for.

## TODO

* Editing
* Saving
* Packed/Nested fields
