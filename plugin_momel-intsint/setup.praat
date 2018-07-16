#version: 2009:01:13
Add menu command... Objects Help "Momel-Intsint Manual" "" 0 plugin_manual.praat

Add menu command... Objects New "--Momel-Intsint--" "Create sound from Shephard tone..." 0
Add menu command... Objects New "Momel-Intsint" "Momel-Intsint" 0
Add menu command... Objects New "Help" "Momel-Intsint" 1 plugin_manual.praat
Add menu command... Objects New "Set working directory..." "Momel-Intsint" 1 analysis/set_working_directory.praat
Add menu command... Objects New "Create recording directories..." "Momel-Intsint" 1 analysis/create_recording_directories.praat
Add menu command... Objects New "Detect f0..." "Momel-Intsint" 1 analysis/detect_f0.praat
Add menu command... Objects New "Calculate Momel..." "Momel-Intsint" 1 analysis/calculate_momel_targets_extracts.praat
Add menu command... Objects New "Correct Momel..." "Momel-Intsint" 1 analysis/correct_momel_targets.praat
Add menu command... Objects New "Calculate Intsint..." "Momel-Intsint" 1 analysis/calculate_intsint_labels.praat
Add menu command... Objects New "Manipulation..." "Momel-Intsint" 1 analysis/manipulation_momel-intsint.praat

Add action command... Sound 1 "" 0 "" 0 "To Pitch (auto max/min)..." "To Pitch..." 1 analysis/automatic_min_max_f0.praat
Add action command... Sound 1 TextGrid 1 "" 0 "Manipulation" "Clone time domain" 0
Add action command... Sound 1 TextGrid 1 "" 0 "Generate F0 from INTSINT..." "Manipulation" 0 analysis/prozed-tones.praat
Add action command... Pitch 1 "" 0 "" 0 "Detect Momel targets..." "Analyse" 0 analysis/momel_single_file.praat
