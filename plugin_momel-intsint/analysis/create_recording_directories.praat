#praat script 

script_name$ = "create_recording_directories.praat"
version$ = "[2007:11:06]"
date$ = date$()

#author: Daniel Hirst
#email: daniel.hirst@lpl.univ-aix.fr

#purpose: Convert directory of sound files into subdirectories of recording folders
# 		one for each sound with same name

#before running this script, the operating system and the working directory 
#	should be selected using the script:
#		set_working_directory.praat

form Select directory for treatment
	comment For a list of subdirectories in the current directory
	comment click the following box then apply
	boolean List_folders no
	comment Folder of sound files to convert to subdirectory of recording folders
	sentence Folder test1
	word Sound_extension .wav
endform

if not(fileReadable("working_directory.txt")) or not(fileReadable("system.txt")) or not(fileReadable("path_separator.txt")) or not(fileReadable("momel.txt"))
	exit Please set working directory before running this script
endif

directory$ <working_directory.txt
path_separator$ <path_separator.txt
system$ < system.txt

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

clearinfo
subdirectory$ = directory$+path_separator$+folder$
Create Strings as file list... sounds 'subdirectory$'/*'sound_extension$'
mySounds = selected("Strings")
nSounds = Get number of strings

for iSound to nSounds
	select mySounds
	sound$ = Get string... iSound
	if not(startsWith(sound$, "."))
		sound_file$ = subdirectory$+path_separator$+sound$
		recording$ = sound_file$-sound_extension$
		printline ['iSound'] 'recording$'
		Read from file... 'sound_file$'
		filedelete 'sound_file$'
		system mkdir "'recording$'"
		Write to WAV file... 'recording$''path_separator$''sound$'
		Remove
	endif
endfor
	
select mySounds
Remove


#version history
#[2007:11:06]	added check to avoid treating backup files beginning with "."
#[2007:10:29]
#[2007:09:28]
#[2007:05:27]
#[2007:05:09]