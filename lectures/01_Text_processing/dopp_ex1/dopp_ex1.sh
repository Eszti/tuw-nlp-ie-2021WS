#!/bin/bash

# Use UTF-8 for Hungarian characters 
export LC_ALL=en_US.UTF-8

# Get Alica in Wonderland in Hungarian: https://mek.oszk.hu/00300/00348/index.phtml#

# Hungarian character names: https://hu.wikipedia.org/w/index.php?title=Alice_Csodaorsz%C3%A1gban_(mesereg%C3%A9ny)
# 12 characters
# - Alice
# - Kalapos
# - Április Bolondja
# - Fehér Nyúl
# - Hernyó
# - Szív Királynő
# - Hercegnő
# - Ál-teknőc
# - Egér
# - Szív Király
# - Griffmadár
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
# - For correct sorting "-k 1b,1" or "-k 1,1" must be applied
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
#   - Fehér Nyúl
#   - Szív Király(nő)
#   - Vigyori macsek
# 2. ✅ Handle suffixes with and w/o "-"", e.g.:
#   - Alice-t, Alice-re, Alice-szel... -> Alice
#   - Adának -> Ada
#   - Billt, Billnél -> Bill
#   - connecting vowel (Bindevokal): Ál-Teknőcöt (akk) -> Ál-Teknőc (normal akkusativ is a single 't', 'ö' is the connecting vowel)
#   - apophony: Április Bolondját (akk) -> Április Bolondja (endig 'a' changes to 'á' in akkusativ)
# 3. ✅ Remove first words of dialogues starting with a "-" as well, e.g.: 
#   - "- Mit tudsz az esetről ?"
# 4. ✅ Improve sentence segmentation:
#   - cat alice_hu_tok.txt | grep ".\."  | wc -l  = 49
#   - cat alice_hu_tok.txt | grep "[a-z]\." | wc -l = 14, e.g.:
#       - élt.
#       - Alice-t.
#       - könnyes-e.
#   - cat alice_hu_tok.txt | grep "\.\." | wc -l = 35, all of which are:
#       - ...
#       - ....
#   - ":"-s should also be recognized as sentence boundaries

echo "Part II. - Improve solution"
echo ""

# Create one sentence per line file
#   - get one sentence per line
#   - improve sentence segmentation (see Improvement Options #3 & #4)
cat alice_hu_tok.txt | sed 's/^$/@/' | tr '\n' ' '| sed 's/ @ /\n/g' | sed 's/^\- //' | sed 's/ \?\- /\n/g' | sed 's/ : /\n/g' | sed 's/\.\s\+\([A-Z].*\)/ \.\n\1/' > alice_hu_sen.txt

# Get tokens without first words of a sentence
#   - keep all but first word of sentence
#   - reformat to one word per line
#   - temporary save for readability
cat alice_hu_sen.txt | cut -d' ' -s -f2- | tr ' ' '\n' > tok_2.txt

# Get unique named entities
#   - find capitalized words and the word following them
#   - substitute lower case words by a placeholder
#   - make the whole text one line
#   - substitute placeholders by new line, so that all non-empty lines contain a sequence of capitalized words (one-word entites are still included!)
#   - keep non-empty lines
#   - remove trailing whitespaces
#   - remove stopwords
#   - remove Hungarian-specific suffixes (see improvement options #2)
#   - get uniqe (multi-word) entities
cat tok_2.txt | grep -E '^[A-Z][a-z]+' -A 1 | sed 's/\(^[a-z\-]\+\)/@/' | tr "\n" " " | sed 's/@/\n/g' | sed 's/\s*\([A-Za-z\ \-]\+\)\?\(.*\)/\1/' | grep "\S" | sed 's/\s*$//' | sort | uniq | sed 's/^[A-Z]/\l&/' | comm -13 stopwords_hu.txt - | sed 's/^[a-z]/\u&/' | sed 's/\(\-\?\(ö\?t\|nak\|nek\|ba\|be\|ban\|ben\|ra\|re\|hez\|hoz\|höz\|től\|tól\|ék\|szel\|val\|vel\|gel\|ral\|ról\|ről\|nél\|jal\)\)\?$//' | sed 's/á$/a/' | sed 's/é$/e/' | sort -t$'\t' -k 1,1 | uniq > uniq_multi_ent.txt

# Get frequencies for all sequences of capitalized words
#   - reformat to one word per line
#   - find capitalized words and the word following them
#   - substitute lower case words by a placeholder
#   - make the whole text one line
#   - substitute placeholders by new line, so that all non-empty lines contain a sequence of capitalized words (one-word entites are still included!)
#   - keep non-empty lines
#   - remove trailing whitespaces
#   - sort
#   - remove Hungarian-specific suffixes (see improvement options #2)
#   - get frequencies
#   - save
cat alice_hu_sen.txt | tr ' ' '\n' | grep -E '^[A-Z][a-z]+' -A 1 | sed 's/\(^[a-z\-]\+\)/@/' | tr "\n" " " | sed 's/@/\n/g' | sed 's/\s*\([A-Za-z\ \-]\+\)\?\(.*\)/\1/' | grep "\S" | sed 's/\s*$//' | sort | sed 's/\(\-\?\(ö\?t\|nak\|nek\|ba\|be\|ban\|ben\|ra\|re\|hez\|hoz\|höz\|től\|tól\|ék\|szel\|val\|vel\|gel\|ral\|ról\|ről\|nél\|jal\)\)\?$//' | sed 's/á$/a/' | sed 's/é$/e/' | sort | uniq -c | sed 's/^ *\([0-9]*\) \(.*\)$/\2\t\1/' | sort -t$'\t' -k 1,1 > ent_freq.txt

# Join frequencies to uniqe (multi-word) entities
join -t$'\t' uniq_multi_ent.txt ent_freq.txt | sed 's/\ \([0-9]\+\)/\t\1/' | sort -t$'\t' -k2 -nr

rm alice_hu_sen.txt tok_2.txt uniq_multi_ent.txt ent_freq.txt

# TODO
# - Ha
# - Idő
# - Az Ál-Teknőc
# - Pa
# - Mondhatom
# - Künn
# - Lenn
# - Kalapos Alice, Hercegnő Alice, Egeret Alice, Egér Alice
# - Angolna

# Open problems
# - Title of chapters are not separated. Unfortunately, the data does not handle them as a sentence. This lead to problems like: 
#   - "Homár-humor Az Ál-Teknőc" is recognized as one entity, where "Homár-humor" is just the title of a chapter.
#   - Lenn
# - I do not handle possesives (they are also expressed as suffixes in Hungarian), e.g.: 
#   - Királynőnket (= our queen (Akkusativ): Királynő(queen)nk(our)e(connecting vowel)t(akkusativ) ) should be recognized as Királynő