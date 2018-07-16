#praat script
script_name$ = "set_working_directory.praat"
version$ = "2008:07:08"
date$ = date$()

#author Daniel Hirst
#email daniel.hirst@lpl.univ-aix.fr

#purpose set path of working directory and system in plugin

form set working directory
sentence Directory /Users/daniel/Desktop
optionmenu System: 1
	option MacOSX
	option MacOS9
	option Linux
	option Windows
	comment Write these values of arguments as new standards?
	boolean Write_arguments yes
endform

clearinfo


if write_arguments
	call write_arguments
endif

path_separator$ = "/"
if system$ = "MacOSX"
	momel$ = "./momel_osX"
elsif system$ = "MacOS9"
	path_separator$ = ":"
	momel$ = "momel_os9"
elsif system$ = "Linux"
	momel$ = "momel_linux"
elsif system$ = "Windows"
	path_separator$ = "\"
	momel$ = "momel_win"
endif
path_separator$ > path_separator.txt
system$ > system.txt
momel$ >momel.txt

directory$ >working_directory.txt


working_directory$ < working_directory.txt
printline The working directory is 'working_directory$'
printline
printline This contains the following subdirectories:

Create Strings as directory list... directory 'working_directory$'
nStrings = Get number of strings
for iString to nStrings
	string$ = Get string... iString
	if string$ != "." and string$ != ".."
		printline 'tab$''string$'
	endif
endfor
Remove
exit

procedure write_arguments
	Read Strings from raw text file... 'script_name$'
	myScript = selected("Strings")
	nStrings = Get number of strings
	call modify sentence Directory 'directory$'
	call modify optionmenu System: 'system'
	Write to raw text file... 'script_name$'
	Remove
endproc

procedure modify type$ parameter$ value$
	select myScript
	iString = 0
	done = 0
	repeat
		iString = iString+1
		string$ = Get string... iString
		if iString = nStrings or index_regex(string$, parameter$)
			done = 1
		endif
	until done
	old_value$ = extractWord$("'string$'", "'parameter$'")
	printline old 'parameter$' is 'old_value$'
	printline new 'parameter$' is 'value$'
	new_string$ = replace$(string$, old_value$, value$, 1)
	Set string... iString 'new_string$'
endproc


#2008:07:08	corrected default parameters
#2007:06:17	subfolder declared as sentence to allow spaces in name
#2007:05:27	self modifying parameters are optional
#2007:02:24	script is self-modifying - new values are written as defaults
#2006:12:12	first version
