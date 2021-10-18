#!/bin/bash

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
# - Vigyori macsek

# Create alice_hu_tok.txt
# - nltk.word_tokenize seems to handle punctuation better than stanze, so I chose to use the nltk tokens

export LC_ALL=C

# Part I. - Redo steps

echo "Part I. - Redo steps"
echo ""

# Extract capitalized words, count them, reformat, save to file
cat alice_hu_tok.txt | grep -E '^[A-Z][a-z]+' | sort | uniq -c | sort -nr | sed 's/^ *\([0-9]*\) \(.*\)$/\2\t\1/' | sort  > ent_freq.txt

# Reformat to get one sentence per line, keep all but the first words of sentences, reformat again to one word per line, extract capitalized words, count them, keep the top 50, and then only those that are not in the stopwords file, finally match the lines to the lines of the word frequency file and sort by frequency
cat alice_hu_tok.txt | sed 's/^$/@/' | tr '\n' ' '| sed 's/ @ /\n/g' | cut -d' ' -f2- | tr ' ' '\n' | grep -E '^[A-Z][a-z]+' | sort | uniq -c | sort -nr | head -50  | sed 's/^[ 0-9]*//'  | sed 's/^[A-Z]/\l&/' | sort | comm -13 stopwords_hu.txt - |  sed 's/^./\u&/' | join - ent_freq.txt | sort -k2 -nr

rm ent_freq.txt

echo ""
echo ""

# Part II. - Improve solution

# Improvement options
# - Alice-t, Alice-re...
# - Adának, Billt, Billnél
# - Remove first words of dialogues as well: "- Mit tudsz az esetről ?"
# - Find multi-word entites as well
#   - Április Bolondja
#   - Fehér Nyúl
#   - Szív Király(nő)
#   - Vigyori macsek

echo "Part II. - Improve solution"
echo ""