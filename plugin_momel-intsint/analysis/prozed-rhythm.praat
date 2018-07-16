#praat script
script_name$ = "prozed-rhythm.praat"
date$ = date$()
version$ = "2007:02:24"
#beta version - liable to major modifications

#author: Daniel Hirst
#email: daniel.hirst@lpl.univ-aix.fr

#purpose: code rhythm with scalar values for all files in subfolder
#	uses working directory and system parameters set by script "set_working_directory.praat"

#reference: Hirst & Auran 2005. Interspeech 2005, Sep. Lisbon.

form Select parameters
	word folder /Users/daniel/documents/Corpus/English/Eurom1-EN/files
	word SubDirectory fa
	word Phoneme_table /Users/daniel/Documents/Corpus/English/Eurom1-EN/stats/fa.means
	word Item_tier phoneme
	word Group_tier	syllable
	positive Quant 0.05
	boolean Print_out 1
	boolean Add_tiers 0
	boolean Mbrola 0
endform

call write_arguments

if print_out
	clearinfo
	printline #output from 'script_name$' (version 'version$') on 'date$'
	printline #Item tier = 'item_tier$'; Group tier = 'group_tier$'
	printline #Quant = 'quant'
	printline
endif

if not(fileReadable("working_directory.txt")) or not(fileReadable("system.txt")) or not(fileReadable("path_separator.txt"))
	exit Please set working directory before running this script
endif

directory$ <working_directory.txt
path_separator$ <path_separator.txt
system$ < system.txt

path$ = directory$+path_separator$+subDirectory$

Create Strings as directory list... myList 'path$'
myFolders = selected("Strings")
nFolders = Get number of strings

Read Table from table file... 'phoneme_table$'
myTable = selected("Table")

for iFolder to nFolders
	select myFolders
	name$ = Get string... iFolder
	if name$ != "." and name$ != ".."
		textGrid$ = path$+path_separator$+name$+path_separator$+name$+".TextGrid"
		if fileReadable(textGrid$)
				call treatment
		else
			printline cannot read 'name$'.TextGrid'
		endif
	endif
endfor

select myFolders
plus myTable
Remove


procedure treatment
	Read from file... 'textGrid$'
	myTextGrid = selected("TextGrid")
	printline 'name$'
	nTiers = Get number of tiers
	item_tier = 0
	group_tier = 0
	for iTier to nTiers
		tier_name$ = Get tier name... iTier
		if tier_name$ = item_tier$
			item_tier = iTier
		endif
		if tier_name$ = group_tier$
			group_tier = iTier
		endif
	endfor
	if item_tier = 0
		printline No 'item_tier$' tier for this file
	elsif group_tier = 0
		print line No 'group_tier$' tier for this file
	else
		item_tier$ = Get tier name... item_tier
		group_tier$ = Get tier name... group_tier
		ngroup = Get number of intervals... group_tier
		totalDuration = Get total duration
		ii=1
		endi = 0
		maxDiff = 0
		totalSumMean = 0
		tempo = 1
		delta = quant/2

		for ig  to ngroup+1
			call treatGroup
			while endi < endg
				call treatItem
				ii = ii+1
			endwhile
		endfor

		ig=ig+1
		call treatGroup
		select myTextGrid

!printline
!printline Total duration: 'totalDuration'
!printline Total predicted duration: 'totalSumMean'

		tempo = totalDuration/totalSumMean
		maxDiff = delta

		iter = 0
		repeat
			iter=iter+1
			call updateWeight
		until maxDiff < delta


####output####
		if print_out
			printline #<parameter tempo='tempo:3'>
		endif
####add parameter and rhythm tiers####
		if add_tiers
			select myTextGrid
			ntiers=ntiers+1
			Insert interval tier... ntiers Parameters
			Set interval text... ntier 1 tempo = 'tempo:3'; quant = 'quant'
			weight_tier=group_tier+1
			Duplicate tier... group_tier weight_tier Weight
			for i to ngroup
				qi = q'i'
			endfor
		endif

		for i to ngroup
			label$ = Get label of interval... group_tier i
			qi = q'i'
			if print_out
				print 'label$'
				if qi > 0
					print ['qi']
				endif
			endif
			if add_tiers
				Set interval text... weight_tier 'i' 'qi' 
			endif
		endfor
		if print_out
			printline
		endif
#### output Mbrola file ####
		if mbrola
			call mbrola
		endif
	endif
	select myTextGrid
	Remove
endproc

procedure treatGroup
	if ig>1
		diff = durg - sumMean
		totalSumMean = totalSumMean + sumMean
		if diff > maxDiff
			maxDiff = diff
			imax = ig
			maxDurg = durg
			maxSumMean = sumMean
		endif
		lig = ig-1
		dur'lig' = durg
		sumMean'lig' = sumMean
		q'lig' = 0
!		printline 'lig''tab$''durg:3''tab$''sumMean:3'
	endif
	q'ngroup' = 0
	if ig <= ngroup
		select myTextGrid
		startg = Get starting point... group_tier ig
		endg = Get end point... group_tier ig
		durg = (endg-startg)
		sumDuration = 0
		sumMean = 0
	endif
endproc

procedure treatItem
	select myTextGrid
	item$ = Get label of interval... item_tier ii
	starti = Get starting point... item_tier ii
	endi = Get end point... item_tier ii
	duri = (endi-starti)
	durphon'ii' = duri
	select myTable
	row = Search column... "phoneme" 'item$'
	if row
		meanDurationMs = Get value... 'row' mean
		meanDuration = meanDurationMs/1000
		sumDuration = sumDuration+ duri
		sumMean = sumMean + meanDuration
	else
		printline Item /'item$'/ ['ii'] not in table.
	endif
endproc

procedure updateWeight
	sumPred = 0
	maxDiff = 0
	for ig to ngroup
		qig = q'ig'
		sumMeanig = sumMean'ig'
		pred = (qig*quant + sumMeanig)*tempo
		sumPred = sumPred + pred
		durig = dur'ig'
		diff = durig - pred
		if diff > maxDiff
			maxDiff = diff
			imax = ig
		endif
	endfor
	maxLabel$ = Get label of interval... group_tier imax
	qimax = q'imax'
!	printline ['iter'] maximum difference ['imax': 'maxLabel$'] q: 'qimax', diff: 'maxDiff:3'
	q'imax' = qimax + 1
	tempo = totalDuration/sumPred
endproc

procedure mbrola
		printline ;Mbrola file created from TextGrid file 'name$' 
		printline ; by 'script$', version 'version$' on 'date$'
		printline
		printline ; <parameter tempo='tempo:3'> <parameter quant = 'quant'>
		nphon = Get number of intervals... item_tier
		for iphon to nphon
			select myTextGrid
			item$ = Get label of interval... item_tier iphon
			select myTable
			row = Search column... "phoneme" 'item$'
			meanDurationMs = Get value... 'row' mean
			select myTextGrid
			start = Get starting point... item_tier iphon
			igroup = Get interval at time... group_tier start
			iquant = q'igroup'
			durationMs = (meanDurationMs/1000 + iquant*quant)*tempo*1000
			if item$ = "_"
				printline _'tab$''durationMs:''tab$'5 90 95 135
			else
 				printline 'item$''tab$''durationMs:' 
			endif
		endfor
endproc

exit

procedure write_arguments
	Read Strings from raw text file... 'script_name$'
	myScript = selected("Strings")
	nStrings = Get number of strings

	call modify 'folder$' word folder
	call modify 'subDirectory$' word SubDirectory
	call modify 'phoneme_table$' word Phoneme_table
	call modify 'item_tier$' word Item_tier
	call modify 'group_tier$' word Group_tier
	call modify 'quant' positive Quant

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

# 2007:02:24  script now self-modifying - new values are written as defaults
# 2006:12:17 batch version - uses working directory and system parameters 
#			set by set_working_directory.praat
# 2005:07:27	first version

