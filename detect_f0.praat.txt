#praat script
script_name$ = "detect_f0.praat"
version$ = "2008:07:06"
date$ = date$()

#author Daniel Hirst
#email daniel.hirst@lpl.univ-aix.fr


#	purpose batch detection of f0 of sound files
#	uses working directory set with script set_working_directory.praat
#	each sound and analysis file in subdirectory of working directory is stored in folder 'name$'
#	default extensions:
#	- sound file : [.wav]
#	- f0 file: [.hz] (one value Hz per line, 0 for unvoiced)
#	date, script and version stored in 'name$'.log
#   parameters saved as 'name$'.pitchStep, ~.min_f0, ~.max_f0

	

form Select subdirectory for treatment
	comment To analyse several subdirectories  
	comment  - click "Apply" for each one except the last  (for which click "OK")
	comment 
	sentence Subdirectory test1
	word Sound_extension .wav
	word Pitch_extension .hz
	boolean automatic_max_and_min 1
	natural Minimum_f0  60
	natural Maximum_f0 750
	real pitch_step 0.01
	comment Overwrite existing pitch files ?
	boolean overwrite no
	comment Print info on analysis
	boolean verbose yes
	comment Write these values of arguments as new standards?
	boolean Write_arguments no
endform

clearinfo

if write_arguments
	call write_arguments
endif

if not(fileReadable("working_directory.txt")) or not(fileReadable("system.txt")) or not(fileReadable("path_separator.txt"))
	exit Please set working directory before running this script
endif

directory$ <working_directory.txt
path_separator$ <path_separator.txt
system$ < system.txt


path$ = directory$+path_separator$+subdirectory$


myFolders = Create Strings as directory list... myList 'path$'
if verbose
	clearinfo
endif
nFolders = Get number of strings
if verbose
	printline 'path$' contains 'nFolders' folders
endif

for iFolder to nFolders
	select myFolders
	name$ = Get string... iFolder
	if name$ != "." and name$ != ".."
		if verbose
			printline ['iFolder'] 'name$'
		endif
		file_path$ = path$+path_separator$+name$+path_separator$+name$
		sound_file$ = file_path$+sound_extension$
		pitch_file$ = file_path$+pitch_extension$
		if fileReadable(sound_file$)
			if not(fileReadable(pitch_file$)) or overwrite
				call treatment
			elsif verbose
				printline file ['pitch_extension$'] already exists for 'name$'
			endif
		else
			printline cannot read 'name$''sound_extension$'
		endif
	endif
endfor

select myFolders
Remove

procedure treatment
	mySound = Read from file... 'sound_file$'
	if automatic_max_and_min
		call calculate_min_max_f0
	else
min_f0 = minimum_f0
max_f0 = maximum_f0
	endif
	if verbose
		printline treating file 'name$' with min = 'min_f0', max = 'max_f0'
	endif
	select mySound
	myPitch = To Pitch... 'pitch_step' 'min_f0' 'max_f0'
	nValues = Get number of frames
	myMatrix = To Matrix
	Transpose
	Write to headerless spreadsheet file... 'pitch_file$'
	plus myMatrix
	plus mySound
	plus myPitch
	Remove
# save parameters and log
	pitch_step$ = "'pitch_step'"
	min_f0$ = "'min_f0'"
	max_f0$ = "'max_f0'"
	pitchStepFile$ = file_path$+".pitch_step"
	minF0File$ = file_path$+".min_f0"
	maxF0File$ = file_path$+".max_f0"
	logfile$ = file_path$+".log"
	pitch_step$ > 'pitchStepFile$'
	min_f0$ > 'minF0File$'
	max_f0$ > 'maxF0File$'
	fileappend "'logfile$'" 'name$''pitch_extension$' created by 'script_name$' version 'version$' on 'date$''newline$'
endproc

procedure calculate_min_max_f0
#  estimate of newMaxF0 as 1.5 * quantile 75
#  and newMinF0 as 0.5 * quantile 25
#  rounded to higher (resp. lower) 10
	To Pitch... 'pitch_step' 'minimum_f0' 'maximum_f0'
	.q75 = Get quantile... 0.0 0.0 0.75 Hertz
	.q25 = Get quantile... 0.0 0.0 0.25 Hertz
	max_f0 = 10*ceiling((1.5*.q75)/10)
	min_f0 = 10*floor((0.75*.q25)/10)
	Remove
endproc

procedure write_arguments
	Read Strings from raw text file... 'script_name$'
	myScript = selected("Strings")
	nStrings = Get number of strings

	call modify sentence Subdirectory 'subdirectory$'
	call modify word Sound_extension 'sound_extension$'
	call modify word Pitch_extension 'pitch_extension$'
	call modify boolean automatic_max_and_min 'automatic_max_and_min'
	call modify natural minimum_f0 'minimum_f0'
	call modify natural maximum_f0 'maximum_f0'
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

#2008:07:06	corrected default parameters
#2007:10:04 	logfile$ quoted to allow spaces in name
#2007:06:17 	subdirectory declared as sentence to allow spaces in name
#		   saving values of arguments as new standards is optional
#		   only removes objects created by the script
#2007:02:24 	script is self-modifying - new values are written as defaults
#2007:01:07 	tidied up
#2007:01:04 	default pitch extension changed (again!) to .hz to avoid confusion with Praat .Pitch files
#2006:12:12 	working directory, system, path separator 
#		defined by script set_working_directory.praat 
#		values read from parameter files stored in plugin
#2006:10:31 	sound and pitch extension put as parameters in form
#2006:06:02 	changed extension of f0 file to .pitch to avoid confusion with
#           	.f0 files in Eurom1 which contain time and f0 couples
#2006:05:27 	corrected format - no time values in .f0 file
#2006:04:19 	first version - adapted from batch.praat version 2006:04:18
