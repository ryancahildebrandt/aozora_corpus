# The Incomparable 青空文庫 Corpus, **Now Comma Separated**

---

---
[*Open*](https://gitpod.io/#https://github.com/ryancahildebrandt/aozora_corpus) *in gitpod*

## *Purpose*
A compilation of the texts available through [青空文庫](https://www.aozora.gr.jp/) (Aozora Bunko Japanese Literature Corpus) into more friendly csv form, to jumpstart projects looking at written Japanese.

---

## *Introduction*
Aozora Bunko is a collection of public domain Japanese texts, digitized and available in a range of formats. The corpus is currently available in its entirety [*here*](https://github.com/aozorabunko/aozorabunko), and more information is available [*here*](http://en.wikipedia.org/wiki/Aozora_Bunko). The repository contains (or links to) all texts available through 青空文庫, but these files and links are contained in individual directories with varying file types, so the full text of the corpus is a bit scattered. Compiling as many of the full texts as possible into one file while preserving available metainformation will (hopefully!) provide a more accessible dataset for those looking to work with a large corpus of literary Japanese. 

---

## *Data*
The data sources used for the current project are linked above, but will be compiled below for organization:
+ [Aozora Bunko Corpus Japanese Page](https://www.aozora.gr.jp/), the main corpus webpage, especially useful for finding a particular text or discovering a new short story to read
+ [Aozora Bunko Github Repository](https://github.com/aozorabunko/aozorabunko), from which the present corpus is built
+ [Meta Information for All Texts](https://www.aozora.gr.jp/index_pages/person_all.html), for organization, of course

---

## *Approach*
Huge thanks to Dr. Molly DesJardin ([*github*](https://github.com/mollydesjardin)[*website*](https://www.mollydesjardin.com/)) for sharing her previous work with 青空文庫, which were helpful in making sense of the **extensive** Aozora Bunko repository and keeping everything organized. By and large the present corpus is compiled via html and text file scraping, with some additional postprocessing to remove ruby characters included in some texts. Below are some notes about the approach used.
+ *Text Source:* When scraping the texts, html format was preferred as it didn't require additional unpacking of zip archives in order to access the text. In instances where the html was not succesfully scraped, the included text file was used where possible. 
+ *Exclusions:* About 1.5% of the texts were not included via the Aozora Bunko repository's html "cards" or zip archives, and were often hosted on external websites. Many of these links were expired, nonexistent, or did not have any content associated with them, with the remainder taking a range of formats. For simplicity and considering the small proportion of the entire corpus, these were excluded but may be incorporated in later updates of the present project.
+ *Readings and Other Text Notes:* Readings for kanji words are sometimes included in the texts, usually as ruby characters or simply in parentheses next to the relevant word. These have been removed for the present corpus as they often times provide redundant information in the case of automatic annotations of the texts. In the case of texts scraped from text files, some notes were also included in the texts in square brackets. These have also been removed.
+ *Aozora Bunko Repository:* The script to generate the corpus assumes a copy of the Aozora Bunko repository cloned in the working directory. If you want to reproduce or work with the script, you'll need a copy of the repo cloned, which can take a wile as it's around 14gb.

---

## *Outputs*

+ The compiled table with full texts, in [csv](https://github.com/ryancahildebrandt/aozora_corpus/blob/master/aozora_corpus.csv) format 
+ The same [csv](https://github.com/ryancahildebrandt/aozora_corpus/blob/master/aozora_corpus_en.csv) with column names in english, for those interested
