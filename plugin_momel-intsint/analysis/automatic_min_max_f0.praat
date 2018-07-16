#Praat script automatic_min_max_f0.praat
#
#version:	2008:07:11
#author 	Daniel Hirst
#email:	daniel.hirst@lpl-aix.fr

#purpose: calculate F0 using two passes with automatic estimation of optimal max and min
#		min f0 is 0.75 * 1st quartile of F0 distribution
#		max f0 is 1.5  * 3rd quartile of F0 distribution
#		values rounded down/up to nearest 10.

#requires: one Sound file (selected)

clearinfo
nSounds = numberOfSelected("Sound")
if nSounds != 1
	pause Please select one Sound then press 'Continue'
endif

mySound = selected()
To Pitch... 0.01 60 750
q25 = Get quantile... 0 0 0.25 Hertz
q75 = Get quantile... 0 0 0.25 Hertz
Remove
select mySound
min_f0 = floor(q25 * 0.75/10)*10
max_f0 = ceiling(q75 * 1.5/10)*10
printline detecting f0 with minimum pitch 'min_f0:' maximum pitch 'max_f0:'
To Pitch... 0.01 min_f0 max_f0

# [2008:07:11]		