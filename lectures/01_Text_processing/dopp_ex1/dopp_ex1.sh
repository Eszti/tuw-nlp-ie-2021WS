#!/bin/bash

# Use UTF-8 for Hungarian characters 
export LC_ALL=en_US.UTF-8

# Get Alica in Wonderland in Hungarian: https://mek.oszk.hu/00300/00348/index.phtml#

# Hungarian character names: https://hu.wikipedia.org/w/index.php?title=Alice_Csodaorsz%C3%A1gban_(mesereg%C3%A9ny)
# 12 characters
# - Alice ✅
# - Kalapos ✅
# - Április Bolondja ✅
# - Fehér Nyúl (Fehér (= white) is used as an adjective)
# - Hernyó ✅
# - Szív Királynő ✅
# - Hercegnő ✅
# - Ál-teknőc ✅
# - Egér ✅
# - Szív Király ✅
# - Griffmadár ✅
# - Vigyori macsek (? - no matches in the data)

# Create alice_hu_tok.txt
# - nltk.word_tokenize seems to handle punctuation better than stanza, so nltk tokens were chosen
# - two tokens were skipped manually:
#   - ''
#   - ``

# Create stopwords_hu.txt
# - "te" (=you) was not included in `stopwords.words('hungarian')`, so it was added manually

# Make sure that the stopwords are sorted correctly
cat stopwords_hu.txt | sort > tmp
mv tmp stopwords_hu.txt

#################################
# Part I. - Redo steps
#################################

echo "Part I. - Redo steps"
echo ""

# Extract capitalized words, count them, reformat, save to file
# Changes:
# - For correct sorting for UTF-8 "-k 1b,1" or "-k 1,1" must be applied
cat alice_hu_tok.txt | grep -E '^[A-Z][a-z]+' | sort | uniq -c | sort -nr | sed 's/^ *\([0-9]*\) \(.*\)$/\2\t\1/' | sort -k 1b,1 > ent_freq.txt

# Reformat to get one sentence per line, keep all but the first words of sentences, reformat again to one word per line, extract capitalized words, count them, keep the top 50, and then only those that are not in the stopwords file, finally match the lines to the lines of the word frequency file and sort by frequency
cat alice_hu_tok.txt | sed 's/^$/@/' | tr '\n' ' '| sed 's/ @ /\n/g' | cut -d' ' -f2- | tr ' ' '\n' | grep -E '^[A-Z][a-z]+' | sort | uniq -c | sort -nr | head -50  | sed 's/^[ 0-9]*//'  | tr [:upper:] [:lower:] | sort | comm -13 stopwords_hu.txt - |  sed 's/^./\u&/' | join - ent_freq.txt | sort -k2 -nr

rm ent_freq.txt

echo ""
echo ""

#################################
# Part II. - Improve solution
#################################

# Improvement Options
# 1. ✅ Find multi-word entites as well, e.g.:
#   - Április Bolondja
#   - Szív Király(nő)
# 2. ✅ Handle Hungarian-specific suffixes with and w/o "-"", e.g.:
#   - Alice-t, Alice-re, Alice-szel... -> Alice
#   - Billt, Billnél -> Bill
#   - connecting vowel (Bindevokal): Ál-Teknőcöt (accustiv) -> Ál-Teknőc (normal accusativ is a single 't', 'ö' is the connecting vowel)
#   - apophony: Április Bolondját (accustiv) -> Április Bolondja (endig 'a' changes to 'á' in accusativ)
# 3. ✅ Remove first words of dialogues starting with a "-" as well, e.g.: 
#   - "- Mit tudsz az esetről ?"
# 4. ✅ Improve sentence segmentation:
#   - Full stop not recognized: 
#      - cat alice_hu_tok.txt | grep ".\."  | wc -l  = 49
#      - cat alice_hu_tok.txt | grep "[a-z]\." | wc -l = 14, e.g.:
#          - élt.
#          - Alice-t.
#          - könnyes-e.
#      - cat alice_hu_tok.txt | grep "\.\." | wc -l = 35, all of which are:
#          - ...
#          - ....
#   - ":"-s should also be recognized as sentence boundaries
#   - remove parenthesis around sentences, e.g.:
#       - "( Ami elég valószínű . )"
# 5. ✅ Cut "chapter XY"
#   - Unfortunately, titles of chapters are not recognized as separate sentneces in the data, e.g.:
#       - "Tizedik fejezet Homár-humor Az Ál-Teknőc nagyot sóhajtott , s egyik talpával megtörülte a szemét ."
#           - "Tizedik fejezet" = chapter 10 -> cut at least these ones(!)
#           - "Homár-humor" = title
#           - "Az Ál-Teknőc nagyot sóhajtott , s egyik talpával megtörülte a szemét ." = the first sentence of chapter 10

echo "Part II. - Improve solution"
echo ""

# Create one sentence per line intermediate file
#   - get one sentence per line
#   - improve sentence segmentation (see Improvement Options #3 & #4)
#   - remove chapter titles (see  Improvement Options #5)
cat alice_hu_tok.txt | sed 's/^$/@/' | tr '\n' ' '| sed 's/ @ /\n/g' | sed 's/^\- //' | sed 's/ \?\- /\n/g' | sed 's/ : /\n/g' | sed 's/\.\s\+\([A-Z].*\)/ \.\n\1/' | sed 's/( //' | sed 's/ )//' | sed 's/\w\+ fejezet //' > alice_hu_sen.txt

# Get tokens without first words of a sentence
#   - keep all but first word of sentence
#   - reformat to one word per line
#   - save to intermediate file for readability
cat alice_hu_sen.txt | cut -d' ' -s -f2- | tr ' ' '\n' > tok_2.txt

# Get unique named (multi-word) entities
#   - find capitalized words and the word following them
#   - substitute lower case words by a placeholder
#   - make the whole text one line
#   - substitute placeholders by new line, so that all non-empty lines contain a sequence of capitalized words (one-word entites are still included!)
#   - remove whitespeces from the beginning of lines and punctuation at the end
#   - remove trailing whitespaces
#   - remove stopwords
#   - remove Hungarian-specific suffixes (see improvement options #2)
#   - get uniqe (multi-word) entities
cat tok_2.txt | grep -E '^[A-Z][a-z][a-z\-]+' -A 1 | sed 's/\(^[a-z\-]\+\)/@/' | tr "\n" " " | sed 's/@/\n/g' | sed 's/\s*\([A-Za-z\ \-]\+\)\?\(.*\)/\1/' | grep "\S" | sed 's/\s*$//' | sort | uniq | sed 's/^[A-Z]/\l&/' | comm -13 stopwords_hu.txt - | sed 's/^[a-z]/\u&/' | sed 's/\(\-\?\(ért\|nket\|ö\?t\|nak\|nek\|ba\|be\|ban\|ben\|ra\|re\|hez\|hoz\|höz\|től\|tól\|ék\|szel\|val\|vel\|gel\|ral\|ról\|ről\|nél\|jal\)\)\?$//' | sed 's/á$/a/' | sed 's/é$/e/' | sort -t$'\t' -k 1,1 | uniq > uniq_multi_ent.txt

# Get frequencies for all sequences of capitalized words
#   - reformat to one word per line
#   - find capitalized words and the word following them
#   - substitute lower case words by a placeholder
#   - make the whole text one line
#   - substitute placeholders by new line, so that all non-empty lines contain a sequence of capitalized words (one-word entites are still included!)
#   - keep non-empty lines
#   - remove trailing whitespaces
#   - remove Hungarian-specific suffixes (see improvement options #2)
#   - get frequencies
#   - save
cat alice_hu_sen.txt | tr ' ' '\n' | grep -E '^[A-Z][a-z][a-z\-]+' -A 1 | sed 's/\(^[a-z\-]\+\)/@/' | tr "\n" " " | sed 's/@/\n/g' | sed 's/\s*\([A-Za-z\ \-]\+\)\?\(.*\)/\1/' | grep "\S" | sed 's/\s*$//' | sed 's/\(\-\?\(ért\|nket\|ö\?t\|nak\|nek\|ba\|be\|ban\|ben\|ra\|re\|hez\|hoz\|höz\|től\|tól\|ék\|szel\|val\|vel\|gel\|ral\|ról\|ről\|nél\|jal\)\)\?$//' | sed 's/á$/a/' | sed 's/é$/e/' | sort | uniq -c | sed 's/^ *\([0-9]*\) \(.*\)$/\2\t\1/' | sort -t$'\t' -k 1,1 > ent_freq.txt

# Join frequencies to uniqe (multi-word) entities
join -t$'\t' uniq_multi_ent.txt ent_freq.txt | sed 's/\ \([0-9]\+\)/\t\1/' | sort -t$'\t' -k2 -nr

rm alice_hu_sen.txt tok_2.txt uniq_multi_ent.txt ent_freq.txt

# Open Issues
# - Title of chapters are not separated from the first sentence of the chapter (see Improvement Options #5). 
#   This means that the first word of the first sentence of each chapter will be recognized as an entity, e.g.: 
#   - Harmadik fejezet Körbecsukó meg az egér hosszú tarka farka Mondhatom , furcsán festett ez a társaság a parton . -> Mondhatom (= I can say)
#   - Hetedik fejezet Bolondok uzsonnája Künn a ház előtt , a fa árnyékában terített asztal . -> Künn (= outside)
# - "Pa" should be "Pat", but the ending "t" is removed as a false positive for accusativ.
# - If two capitalized words follow each other for whatever reason, they will be recognized as one entity, e.g.:
#   - "kínálgatta a Kalapos Alice-t" (= Kalapos offered to Alice) -> Kalapos Alice
#   - "dörmögte a Hercegnő Alice felé" (= Hercegnő moaned towards Alice) -> Hercegnő Alice
#   - Solving this issue would require a proper syntactic analysis of the sentences, which goes beyond the scope of this exercise, therefore left out.
