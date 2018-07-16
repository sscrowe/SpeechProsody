#praat script
script_name$ = "calculate_momel_targets_extracts.praat"
version$ = "[2008:07:13]"
date$ = date$()

#author: Daniel Hirst
#email: daniel.hirst@lpl.univ-aix.fr

#purpose: batch analysis of pitch files organised as in the following example 

#	the working directory (eg corpus) contains at least one subdirectory (eg speaker01, speaker02…)
#	each subdirectory contains at least one recording directory (eg text01, text02…)
#	each recording directory contains at least one sound file (eg text01.wav) and one pitch file (eg text01.hz)

#this script calculates momel targets <ms, Hz> (calling an external C program)
#default extensions: f0 : ".hz"; momel targets: ".momel"
#before calling momel, the script splits the sound file into pause separated segments
#this improves the target detection before and after pauses (cf Hirst et al. 2007 - Interspeech)

#before running this script, the operating system and the working directory 
#containing the subdirectory should be selected using the script
#		set_working_directory.praat

form Select Subdirectory for treatment
	boolean List_folders no
	word SubDirectory test1
	word Sound_extension .wav
	word Pitch_extension .hz
	word Momel_extension .momel
	word Momel_auto_extension .momel_auto
	word PitchTier_extension .PitchTier
	boolean Overwrite_existing_target_points 0
	boolean Display_info_on_treatment 1
	comment default values : Only change these if you know what you're doing!
	natural left_Pitch_range 60
	natural right_Pitch_range 750
	positive pitch_step 0.01
	sentence momel_parameters 30 60 750 1.04 20 5 0.05
	sentence silence_parameters -25 0.25 0.05 
	word silence_label #
	word sound_label sound
	boolean Save_new_values_as_defaults 0
endform

overwrite = overwrite_existing_target_points
verbose = display_info_on_treatment
clearinfo

if save_new_values_as_defaults
	call write_arguments
endif

silence_tier = 1

if not(fileReadable("working_directory.txt")) or not(fileReadable("system.txt")) 
	...or not(fileReadable("path_separator.txt")) or not(fileReadable("momel.txt"))
	exit You need to set the working directory before running this script
endif

directory$ <working_directory.txt
path_separator$ <path_separator.txt
system$ < system.txt
momel$ <momel.txt

path$ = directory$+path_separator$+subDirectory$

if list_folders
	clearinfo
	printline Working directory: 'directory$'
	printline Subdirectories:
	Create Strings as directory list... folders 'directory$'
	nStrings = Get number of strings
	for iString to nStrings
		subdirectory$ = Get string... iString
		printline 'tab$' - 'subdirectory$'
	endfor ;iString

	printline
	printline To change working directory use the script "Set working directory"
	Remove
	exit
endif ;list_folders


myFolders = Create Strings as directory list... myFolders 'path$'
nFolders = Get number of strings

if verbose
	printline 'path$' contains 'nFolders' folders
endif

for iFolder to nFolders
	select myFolders
	name$ = Get string... iFolder
	if verbose
		printline ['iFolder'] 'name$'
	endif
	file_name$ = path$+path_separator$+name$+path_separator$+name$
	sound_file$ = file_name$+sound_extension$
	pitch_file$ = file_name$ + pitch_extension$
	momel_file$ = file_name$+momel_extension$
	momel_auto_file$ = file_name$+momel_auto_extension$
	pitchTier_file$ = file_name$+pitchTier_extension$
	if fileReadable(momel_file$) and not overwrite
		printline 'name$''momel_extension$' already exists
	else
		if fileReadable(sound_file$)
			if fileReadable(pitch_file$)
				call treat_sound
			else
				printline 'name$''pitch_extension$' is not readable
			endif
		else
			printline 'name$''sound_extension$' is not readable
		endif
	endif
endfor

select myFolders
Remove
exit


procedure treat_sound
	if verbose
		printline treating file 'sound_file$'
	endif
	min_f0_file$ = file_name$+".min_f0"
	max_f0_file$ = file_name$+".max_f0"
	log_file$ = file_name$+".log"

	if fileReadable(min_f0_file$)
		min_f0$ < 'min_f0_file$'
		min_f0 = 'min_f0$'
	else
		min_f0 = left_pitch_range
	endif
	if fileReadable(max_f0_file$)
		max_f0$ < 'max_f0_file$'
		max_f0 = 'max_f0$'
	else
		max_f0 = right_pitch_range
	endif

#create temporary folder in analysis folder of plugin if it doesn't already exist
	system_nocheck mkdir temp
#remove any existing files in this folder
	myOld_files = Create Strings as file list... Old_files temp/*
	nOld_files = Get number of strings

	for iOld_file to nOld_files
		old_file$ = Get string... iOld_file
		filedelete temp/'old_file$'
	endfor

#Read Sound and create Pitch, Matrix, TextGrid and PitchTier
	Read from file... 'sound_file$'
	mySound = selected("Sound")
	duration = Get total duration
	myPitch = To Pitch... pitch_step min_f0 max_f0
	myMatrix = To Matrix
	select mySound
	myTextGrid = To TextGrid (silences)... 'min_f0' 'pitch_step' 'silence_parameters$' 'silence_label$' 'sound_label$'
	nIntervals = Get number of intervals... silence_tier
	myPitchTier = Create PitchTier... 'name$' 0 duration

#treat non-silent extracts of sound
	nExtracts = 0
	for iInterval from 1 to nIntervals
		select myTextGrid
		label$ = Get label of interval... silence_tier iInterval
		if label$ = sound_label$
			nExtracts = nExtracts+1
			call treat_extract
		endif
	endfor
	select myPitchTier
	call write_to_momel
	fileappend "'log_file$'" 'name$''momel_extension$' and 'name$''momel_auto_extension$' 
	...created by 'script_name$' version 'version$' on 'date$''newline$'
	plus myOld_files
	plus myPitch
	plus mySound
	plus myMatrix
	plus myTextGrid
	Remove
endproc

procedure treat_extract
	extract$ = "extract_"+"'nExtracts'"
	pitch_extract$ = "temp/"+extract$+pitch_extension$
	momel_extract$ = "temp/"+extract$+momel_extension$
	if verbose
		printline Treating  'extract$'
	endif
	start = Get starting point...  silence_tier iInterval
	iStart = ceiling(start / pitch_step)
	if iStart <1
		iStart = 1
	endif
	end = Get end point... silence_tier iInterval
	iEnd = floor(end / pitch_step)
	if verbose
		printline Extract 'nExtracts' (interval 'iInterval'): ['iStart':'iEnd']
	endif
#write values of pitch to temporary pitch file
	select myMatrix
	nColumns = Get number of columns
	if iEnd > nColumns
		iEnd = nColumns
	endif	
	for iPitch from iStart to iEnd
		pitch = Get value in cell... 1 iPitch
		fileappend "'pitch_extract$'" 'pitch''newline$'
	endfor
#call momel
	system 'momel$' >'momel_extract$' 'momel_parameters$' <'pitch_extract$'
#Add targets from extract to PitchTier
	myStrings = Read Strings from raw text file... 'momel_extract$'
	nStrings = Get number of strings

	for iString from 1 to nStrings
		select myStrings
		string$ = Get string... iString
		ms = extractNumber(string$,"")
		if ms = undefined
			printline String ['iString'] ('string$') doesn't contain a number
		else
			secs = ms/1000
			f0 = extractNumber(string$, " ")
			if f0 > max_f0
				f0 = max_f0
			elsif f0 < min_f0
				f0 = min_f0
			endif
			time = secs+start
			if time <0
				time = 0
			elsif time > duration
				time = duration
			endif	
			select myPitchTier
			Add point... time f0
		endif
	endfor ; iString

	select myStrings
	Remove
endproc

procedure write_to_momel
	filedelete "'momel_file$'"
	filedelete "'momel_auto_file$'"
	filedelete "'pitchTier_file$'"
	select myPitchTier
	Write to text file... 'pitchTier_file$'
	nTargets = Get number of points

	for iTarget from 1 to nTargets
		time = Get time from index...  iTarget
		time_ms = time*1000
		target = Get value at index... iTarget
		fileappend "'momel_file$'" 'time_ms:' 'target:''newline$'
		fileappend "'momel_auto_file$'" 'time_ms:' 'target:''newline$'
	endfor ; iTarget

endproc

procedure write_arguments
	Read Strings from raw text file... 'script_name$'
	myScript = selected("Strings")
	nStrings = Get number of strings
	call modify 'directory$' word Directory
	call modify 'system' optionmenu System:
	call modify 'subDirectory$' word SubDirectory
	call modify 'sound_extension$' word Sound_extension
	call modify 'pitch_extension$' word Pitch_extension
	call modify 'momel_extension$' word Momel_extension
	call modify 'momel_auto_extension$' word Momel_auto_extension
	call modify 'pitchTier_extension$' word PitchTier_extension

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


#[2008:07:13]	corrected 'bug' which assumed Windows understood the system command 'rm -r'
#				replaced this with Praat function filedelete in loop
#				modified numbering of extracts
#				now only removes objects created by script
#[2007:09:29]  tidied up form to make it smaller
#[2007:03:07]  saving arguments as defaults is now optional
#[2007:02:24]  script now self-modifying - new arguments are written as defaults
#[2007:02:05]  added list subdirectories to form
#[2007:01:22]  Renumbered versions of script
#				Remove intermediate files during treatment to avoid Praat error from too many objects 
#				Added constraint on targets: cannot be >max_f0 or <min_f0
#				Corrected indexing error when first interval contains sound
#[2007:01:07] Momel targets calculated on pause separated portions of signal
#[2007:01:04] default pitch extension changed to .hz to avoid confusion with Praat .Pitch files
#[2006:12:12] working directory and system parameters defined by script set_working_directory and read from files in plugin
#[2006:12:06] path_separator and momel version selection from choice of system in form
#[2006:06:02] plugin version
#[2004:11:17] Cyril Auran's Praat implementation
