#praat script
 
script_name$ = "manipulate_momel_intsint.praat"
date$ = date$()
version$ = "2007:03:31"
#author: Daniel Hirst
#email: daniel.hirst@lpl.univ-aix.fr

#purpose: Create modification file with PitchTier derived from Insint coding
#requires: One Sound file and one TextGrid with same name (given in Form)
#		   TextGrid should have Momel, Intsint and IntsintMomel tiers



!Read from file... Warning.man
!exit

form Define parameters
	word Subdirectory test1
	word Filename English
	comment Click box then Apply for list of folders in subdirectory
	boolean subdirectory_list 0
	word Sound_extension .wav
	word TextGrid_extension .TextGrid
	comment Tier names:
	word Momel_tier Momel
	word Intsint_tier Intsint
	word IntsintMomel_tier IntsintMomel
	comment Save new arguments as default?
	boolean save_arguments 0
endform

if save_arguments
	call write_arguments
endif


if not(fileReadable("working_directory.txt")) or not(fileReadable("system.txt")) or not(fileReadable("path_separator.txt"))
	exit Please set working directory before running this script
endif

directory$ <working_directory.txt
path_separator$ <path_separator.txt
system$ < system.txt

if subdirectory_list
	Create Strings as directory list... folders 'directory$''path_separator$''subdirectory$'
	myStrings = selected()
	nStrings = Get number of strings
	clearinfo
	for iString to nStrings
		string$ = Get string... iString
		printline 'string$'
	endfor
	Remove
	exit
endif


minimum_f0 = 60
maximum_f0 = 700
time_step = 0.01
clearinfo

path$ = directory$+path_separator$+subdirectory$+path_separator$+filename$
sound_file$ = path$+path_separator$+filename$+sound_extension$
textGrid_file$ = path$+path_separator$+filename$+textGrid_extension$
Read from file... 'sound_file$'
mySound = selected("Sound")
Read from file... 'textGrid_file$'
myTextGrid = selected("TextGrid")
select myTextGrid
duration = Get total duration
nTiers = Get number of tiers

for iTier from 1 to nTiers
	tier$ = Get tier name... iTier
	if tier$ = momel_tier$
		momel_tier = iTier
	elsif tier$ = intsint_tier$
		intsint_tier = iTier
	elsif tier$ = intsintMomel_tier$
		intsintMomel_tier = iTier
	endif
endfor

printline Momel = tier 'momel_tier'; Intsint = tier 'intsint_tier'; IntsintMomel = tier 'intsintMomel_tier'
nTargets = Get number of points... momel_tier
Create PitchTier... "Momel" 0 duration
myMomel = selected("PitchTier")
Create PitchTier... "IntsintMomel" 0 duration
myIntsintMomel = selected("PitchTier")
select myTextGrid
for iTarget from 1 to nTargets
	select myTextGrid
	time = Get time of point... momel_tier iTarget
	momel$ = Get label of point... momel_tier iTarget
	momel = 'momel$'
	intsintMomel$ = Get label of point... intsintMomel_tier iTarget
	intsintMomel = 'intsintMomel$'
	select myMomel
	Add point... time momel
	select myIntsintMomel
	Add point... time intsintMomel
endfor

select mySound
call calculate_min_max
select mySound
To Manipulation... 'time_step' 'min_f0' 'max_f0'
momel_manipulation = selected("Manipulation")
Rename... Momel
Copy... IntsintMomel
intsint_manipulation = selected("Manipulation")
Edit
plus myIntsintMomel
Replace pitch tier
select momel_manipulation
Edit
plus myMomel
Replace pitch tier

procedure calculate_min_max
	To Pitch... 'time_step' 'minimum_f0' 'maximum_f0'
	q75 = Get quantile... 0.0 0.0 0.75 Hertz
	q25 = Get quantile... 0.0 0.0 0.25 Hertz
	max_f0 = 10*ceiling((1.5*q75)/10)
	min_f0 = 10*floor((0.75*q25)/10)
	Remove
endproc

procedure write_arguments
	Read Strings from raw text file... 'script_name$'
	myScript = selected("Strings")
	nStrings = Get number of strings

	call modify 'subdirectory$' word Subdirectory
	call modify 'filename$' word Filename
	call modify 'sound_extension$' word Sound_extension
	call modify 'textGrid_extension$' word TextGrid_extension
	call modify 'momel_tier$' word Momel_tier
	call modify 'intsint_tier$' word Intsint_tier
	call modify 'intsintMomel_tier$' word IntsintMomel_tier

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


# 2007:03:31  saving arguments as default now optional
# 2007:02:24  script now self-modifying - new values are written as defaults
# 2006:12:12 working directory and system parameters defined by script set_working_directory and read from files in plugin
# 2006:11:01 First version
