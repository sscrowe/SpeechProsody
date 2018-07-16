#praat script correct_momel_targets

script_name$ = "correct_momel_targets.praat"
version$ = "2007:06:17"
date$ = date$()

#author: Daniel Hirst
#email: daniel.hirst@lpl.univ-aix.fr

#purpose: treatment of folder 'name$' containing
# Sound file ('name$'.wav) and momel file ('name$'.momel)
# outputs corrected momel targets to 'name$.PitchTier' 
# and to 'name$'.momel overwriting earlier file

form Select Subdirectory and file for treatment
	comment To analyse several files consecutively
	comment  - click "Apply" for each one except the last  
	comment - then click "OK" for the last one 
	word SubDirectory test1
	comment - for a list of folders click the following box then Apply
	boolean List_files 0
	word Name English
	word Sound_extension .wav
	word Momel_extension .momel
	word PitchTier_extension .PitchTier
	comment Default values
	natural minimum_f0 65
	natural maximum_f0 750
	comment save these values as new standards?
	boolean save_values no
endform

clearinfo
if save_values
	call write_arguments
endif

if not(fileReadable("working_directory.txt")) or not(fileReadable("system.txt")) or not(fileReadable("path_separator.txt"))
	exit Please set working directory before running this script
endif

directory$ <working_directory.txt
path_separator$ <path_separator.txt
system$ < system.txt

path$ = directory$+path_separator$+subDirectory$

clearinfo
if list_files
	printline Current folder is 'path$'
	printline
	myStrings = Create Strings as directory list... strings 'path$'
	nStrings = Get number of strings
	for iString to nStrings
		name$ = Get string... iString
		printline 'tab$''name$'
	endfor
	Remove
	exit
endif

file_name$ = path$+path_separator$+name$+path_separator$+name$
sound_file$ = file_name$+sound_extension$
momel_file$ = file_name$+momel_extension$
pitchTier_file$ = file_name$+pitchTier_extension$
if fileReadable(sound_file$)
	printline treating file 'name$'
	Read from file... 'sound_file$'
	mySound = selected("Sound")
	duration = Get total duration
	min_f0_file$ = file_name$+".min_f0"
	max_f0_file$ = file_name$+".max_f0"
	log_file$ = file_name$+".log"

	if fileReadable(min_f0_file$)
		min_f0$ < 'min_f0_file$'
		min_f0 = 'min_f0$'
	else
		min_f0 = minimum_f0
	endif
	if fileReadable(max_f0_file$)
		max_f0$ < 'max_f0_file$'
		max_f0 = 'max_f0$'
	else
		max_f0 = maximum_f0
	endif

	if  fileReadable(pitchTier_file$)
		Read from file... 'pitchTier_file$'
		myPitchTier = selected("PitchTier")
		call treatment
	elsif fileReadable(momel_file$)
		call create_pitchTier
		call treatment
	else
		printline No file 'name$' with ['momel_extension$'] extension
	endif
else
	printline No file 'name$' with ['sound_extension$'] extension
endif

	
procedure create_pitchTier
	Create PitchTier... 'name$' 0 duration
	myPitchTier = selected("PitchTier")
	Read Strings from raw text file... 'momel_file$'
	myStrings = selected ("Strings")
	nStrings = Get number of strings
	for iString from 1 to nStrings
		select myStrings
		string$ = Get string... iString
		ms = extractNumber(string$,"")
		secs = ms/1000
		f0 = extractNumber(string$, " ")
		select myPitchTier
		Add point... secs f0
	endfor
endproc

procedure treatment
	select mySound
	To Manipulation... 0.01 min_f0 max_f0
	myManipulation = selected("Manipulation")
	plus myPitchTier
	Replace pitch tier
	select myManipulation
	Edit
	pause... Correct Momel targets then switch back to linear interpolation
	select myManipulation
	Extract pitch tier
	Write to text file... 'pitchTier_file$'
	nTargets = Get number of points
	filedelete 'momel_file$'
	for iTarget from 1 to nTargets
		time = Get time from index... iTarget
		time_ms = time*1000
		target = Get value at index... iTarget
		line$ = "'time_ms:0''tab$''target:0''newline$'"
		line$ >> 'momel_file$'
	endfor
	fileappend 'log_file$' 'name$''momel_extension$' and 'name$''pitchTier_extension$' created from 'name$''sound_extension$' on 'date$' by 'script_name$' version 'version$''newline$'
endproc

procedure write_arguments
	Read Strings from raw text file... 'script_name$'
	myScript = selected("Strings")
	nStrings = Get number of strings

	call modify 'SubDirectory$' word SubDirectory
	call modify 'name$' word Name
	call modify 'Sound_extension$' word Sound_extension
	call modify 'Momel_extension$' word Momel_extension
	call modify 'PitchTier_extension$' word PitchTier_extension

	Write to raw text file... 'script_name$'
	Remove
endproc

procedure modify value$ parameter$
	select myScript
	iString = 0
	done = 0

	repeat
		iString = iString+1
		string$ = Get string... iString
		if index_regex(string$, parameter$)
			done = 1
		endif
	until done

	old_value$ = extractWord$("'string$'", "'parameter$'")
	printline old 'parameter$' is 'old_value$'
	printline new 'parameter$' is 'value$'
	new_string$ = replace$(string$, old_value$, value$, 1)
	Set string... iString 'new_string$'
endproc


# 2007:06:17  saving new values is optional
# 2007:02:24  script is self-modifying - new values are written as defaults
# 2007:01:31 corrected errors in log file
# 2006:12:20 treat a single file rather than batch
# 2006:12:12 working directory and system parameters defined by script set_working_directory and read from files in plugin
# 2006:11:20 skips "." and ".."
# 2006:10:29 first version
 
