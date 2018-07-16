#praat script
script_name$ = "calculate_momel_targets.praat"
version$ = "1.9"
date$ = date$()

#author: Daniel Hirst
#email: daniel.hirst@lpl.univ-aix.fr

#purpose batch treatment of pitch files organised as in the following example 

#			corpus		(working directory)
#			| speaker1	(subdirectory for treatment)
#			|  | recording1	(recording name)
#			|  |  | recording1.hz 	(treatment files)
#			|  |  | recording1.wav 	(	"		"	)
#			|  |  | recording1.momel	(	"		"	)
#			|  |  |  …
#			|  |  recording2
#			|  |   …
#			| speaker2
#			|  …

#this script calculates momel targets (using external C program)
#default extensions: f0 : ".hz"; momel targets: ".momel"

#before running this script, the operating system and the working directory 
#containing the subdirectory should be selected using the script
#		set_working_directory.praat

form Select Subdirectory for treatment
	comment For a list of subdirectories in the current working directory
	comment click the following box then apply
	boolean List_folders no
	sentence Subdirectory test1
	word Pitch_extension .hz
	word Momel_extension .momel
	word Momel_auto_extension .momel_auto
	word PitchTier_extension .PitchTier
	comment overwrite existing target points?
	boolean overwrite no
	comment print info during treatment?
	boolean verbose yes
	comment default values - do not change these unless you know what you are doing!
 	sentence momel_parameters 30 60 750 1.04 20 5 0.05
	natural minimum_f0 60
	natural maximum_f0 700
	positive time_step 0.01
	boolean save_new_values_as_defaults 0
endform

clearinfo
if save_new_values_as_defaults
	call write_arguments
endif

if not(fileReadable("working_directory.txt")) or not(fileReadable("system.txt")) or not(fileReadable("path_separator.txt")) or not(fileReadable("momel.txt"))
	exit Please set working directory before running this script
endif

directory$ <working_directory.txt
path_separator$ <path_separator.txt
system$ < system.txt
momel$ <momel.txt


path$ = directory$+path_separator$+subdirectory$

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

myFolders = Create Strings as directory list... myList 'path$'

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
	fileName$ = path$+path_separator$+name$+path_separator$+name$
	pitch_file$ = fileName$+pitch_extension$
	momel_file$ = fileName$+momel_extension$
	momel_auto_file$ = fileName$+momel_auto_extension$
	pitchTier_file$ = fileName$+pitchTier_extension$
	pitch_step_file$ = fileName$+"pitch_step"
	if fileReadable(momel_file$) and not overwrite
		printline 'name$''momel_extension$' already exists
	else
		if fileReadable(pitch_file$) 
			call treatment
		else
			printline no file 'name$''pitch_extension$'
		endif
	endif
endfor

select myFolders
Remove

procedure treatment
	printline treating file 'name$''pitch_extension$'
	min_f0_file$ = fileName$+".min_f0"
	max_f0_file$ = fileName$+".max_f0"
	log_file$ = fileName$+".log"

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
#call momel
	system 'momel$' > "'momel_file$'" 'momel_parameters$' < "'pitch_file$'"
	Read Matrix from raw text file... 'momel_file$'
	myMomel = selected("Matrix")
	filedelete momel_auto_file$
	Write to headerless spreadsheet file... 'momel_auto_file$'
	select myMomel
	nRows = Get number of rows
	call create_pitch_tier
	Write to text file... 'pitchTier_file$'
	plus myMomel
	Remove
	fileappend "'log_file$'" 'name$': 'momel_extension$' 'momel_auto_extension$' and 'pitchTier_extension$' created by 'script_name$' version 'version$' on 'date$''newline$'
endproc

procedure create_pitch_tier
	Read Matrix from raw text file... 'pitch_file$'
	myPitch = selected("Matrix")
	nPoints = Get number of rows
	duration = (nPoints+1)*time_step
	Remove
	Create PitchTier... momel 0 duration
	myPitchTier = selected("PitchTier")
	for iRow to nRows
		select myMomel
		time_ms = Get value in cell... iRow 1
		time = time_ms/1000
		pitch = Get value in cell... iRow 2
		select myPitchTier
		Add point... time pitch
	endfor ;iRow
endproc ; create_pitch_tier

procedure write_arguments
	Read Strings from raw text file... 'script_name$'
	myScript = selected("Strings")
	nStrings = Get number of strings

	call modify 'subDirectory$' word SubDirectory
	call modify 'pitch_extension$' word Pitch_extension
	call modify 'momel_extension$' word Momel_extension
	call modify 'momel_auto_extension$' word Momel_auto_extension
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


#[2007:10:04] logfile$ quoted to allow spaces in path
#[2007:06:18] subdirectory declared as sentence and filenames quoted in system call to allow names with spaces
#[2007:03:25] saving arguments as defaults is optional, save momel PitchTier
#[2007:02:24] script now self-modifying -  values are written as new defaults
#[2007:02:05] added list subdirectories to form
#[2007:01:31] corrected error which added 'tab$' to momel file name (thanks Sil!)
#[2007:01:04] default pitch extension changed to .hz to avoid confusion with Praat .Pitch files
#[2006:12:12] working directory and system parameters defined by script set_working_directory and read from files in plugin
#[2006:12:06] path_separator and momel version selection by choice of system in form
#[2006:06:02] first plugin version
#1.0 Cyril Auran's Praat implementation
