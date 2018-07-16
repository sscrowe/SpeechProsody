#Praat script       ProZed-tones.praat
#author Daniel Hirst  <daniel.hirst@lpl-aix.fr>

#version 2009:01:13

#purpose   Prosody Editor
#requires: one Sound and one TextGrid (both selected)
#		The TextGrid should have one "range" tier and one "tonal" tier.
#		key (Hz) and span (octave) are coded in the range tier in the format eg key=120 span=1.0
#		tones are coded in the TU tier using INTSINT (T, S, B, H, U, S, D, L)
#		tones are aligned with the tonal units using the code (preceding the tone): 
#			"[" beginning; "+" fixed offset; "<" 25%; "=" 50%; ">" 75%; "-" fixed negative offset; "]" end

form ProZed
	natural range_tier 2
	natural tonal_tier 3
	positive offset 0.05
	comment Add pitch targets to TextGrid ?
	boolean Add_targets no
endform

offset = 0.05
epsilon = 0.001
last_pitch = 135
early = 0.25
mid = 0.5
late = 0.75

clearinfo
if numberOfSelected("TextGrid") != 1 or numberOfSelected("Sound") != 1
	pause please select one TextGrid and one Sound
endif

mySound = selected("Sound")
myTextGrid = selected("TextGrid")

select myTextGrid
name$ = selected$("TextGrid")
nTiers = Get number of tiers

if add_targets 
	nTiers = nTiers+1
	Insert point tier... nTiers targets
endif

duration = Get total duration
myPitchTier = Create PitchTier... 'name$' 0 duration


span = undefined
key = undefined
select myTextGrid
nRanges = Get number of intervals... range_tier
for iRange to nRanges
	select myTextGrid
	range$ = Get label of interval... range_tier iRange
	span = extractNumber(range$, "span=")
	key = extractNumber(range$, "key=")
	if span != undefined and key != undefined
		start = Get starting point... range_tier iRange
		end = Get end point... range_tier iRange
		iStart_TU = Get interval at time... tonal_tier start
		iEnd_TU = Get interval at time... tonal_tier end-epsilon
		top = key*sqrt(2^span)
		bottom = key/sqrt(2^span)
printline range 'iRange' key is 'key'; span is 'span' TUs from 'iStart_TU' to 'iEnd_TU'

		for iTU from iStart_TU to iEnd_TU
			select myTextGrid
			start_TU = Get starting point... tonal_tier iTU
			end_TU = Get end point... tonal_tier iTU
			tu$ = Get label of interval... tonal_tier iTU

			while length(tu$) > 1
				align$ = left$(tu$, 1)
				call calculate_alignment
				tone$ = mid$(tu$, 2, 1)
				call calculate_pitch
				last_pitch = pitch
				tu$ = right$(tu$, length(tu$)-3)
				if add_targets
					select myTextGrid
					pitch$ = "'pitch:0'"
					Insert point... nTiers time 'pitch$'
				endif
				select myPitchTier
				Add point... time pitch
			endwhile
		endfor
	endif
endfor

select myPitchTier
Interpolate quadratically... 4 semitones
select mySound
To Manipulation... 0.01 bottom top
plus myPitchTier
Replace pitch tier
minus myPitchTier
Edit
select mySound
plus myTextGrid

procedure calculate_alignment
	if align$ = "["
		time = start_TU+epsilon
	elsif align$ = "+"
		time = start_TU + offset
	elsif align$ = "<"
		time = start_TU + early*(end_TU-start_TU)
	elsif align$ = "="
		time = start_TU + mid*(end_TU-start_TU)
	elsif align$ = ">"
		time = start_TU + late*(end_TU-start_TU)
	elsif align$ = "-"
		time = end_TU - offset
	elsif align$ = "]"
		time = end_TU - epsilon
	endif
endproc

procedure calculate_pitch
	if tone$ = "T"
		pitch = top
	elsif tone$ = "H"
		pitch = sqrt(last_pitch*top)
	elsif tone$ = "U"
		pitch = sqrt(last_pitch* sqrt(last_pitch*top))
	elsif tone$ = "S"
		pitch = last_pitch
	elsif tone$ = "M"
		pitch = key
	elsif tone$ = "D"
		pitch = sqrt(last_pitch* sqrt(last_pitch*bottom))
	elsif tone$ = "L"
		pitch = sqrt(last_pitch*bottom)
	elsif tone$ = "B"
		pitch = bottom
	endif
endproc

#version history
#2009:01:13 first version - seems to be working