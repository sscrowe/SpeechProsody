#praat script
script_name$ = "momel_single_file.praat"
version$ = "2008:07:13"
date$ = date$()

#author: Daniel Hirst
#email: daniel.hirst@lpl.univ-aix.fr

#purpose: single file call to momel

form Momel single file
optionmenu System: 1
	option MacOSX
	option MacOS9
	option Linux
	option Windows
	comment Write this value as new standard?
	boolean Write_arguments yes
	comment Do not change the following unless know what you are doing!
	sentence momel_parameters 30 60 750 1.04 20 5 0.05
endform

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

pitch_extension$ = ".hz"
momel_extension$ =  ".momel"
output_folder$ = "temp"

nPitches = numberOfSelected("Pitch")
if nPitches != 1
	pause Please select one pitch object
endif

myPitch = selected("Pitch")
name$ = selected$("Pitch")
duration = Get total duration

clearinfo
momel$ > momel.txt
system$ > system.txt
file_path$ = output_folder$+path_separator$+name$
pitch_file$ = file_path$+pitch_extension$
momel_file$ = file_path$+momel_extension$
myMatrix = To Matrix
Transpose
Write to headerless spreadsheet file... 'pitch_file$'
plus myMatrix
Remove
	select myPitch
endif

system 'momel$' > "'momel_file$'" 'momel_parameters$' < "'pitch_file$'"
Read Matrix from raw text file... 'momel_file$'
myMatrix = selected()
nRows = Get number of rows
Create PitchTier... 'name$' 0 'duration'
myPitchTier = selected()

for iRow from 1 to nRows
	select myMatrix
	time_ms = Get value in cell... iRow 1
	hz = Get value in cell... iRow 2
	select myPitchTier
	time_s = time_ms/1000
	Add point... time_s hz
endfor

select myMatrix
Remove
filedelete 'momel_file$'
filedelete 'pitch_file$'
select myPitchTier

procedure write_arguments
	Read Strings from raw text file... 'script_name$'
	myScript = selected("Strings")
	nStrings = Get number of strings
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

#2008:07:13	applies to selected Pitch object only now, uses temporary files in "temp"
#			added selection of System and autosave of default parameter
#2007:06:16 	adapted to apply to selected file
#2007:01:04 	working!
