# The Incomparable 青空文庫 Corpus, **Now Comma Separated**

---

[![Open in gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/ryancahildebrandt/aozora_corpus)
[![This project contains 0% LLM-generated content](https://brainmade.org/88x31-dark.png)](https://brainmade.org/)

## _Purpose_

A compilation of the texts available through [青空文庫](https://www.aozora.gr.jp/) (Aozora Bunko Japanese Literature Corpus) into more friendly csv form, to jumpstart projects looking at written Japanese.

---

## _Introduction_

Aozora Bunko is a collection of public domain Japanese texts, digitized and available in a range of formats. The corpus is currently available in its entirety [_here_](https://github.com/aozorabunko/aozorabunko), and more information is available [_here_](http://en.wikipedia.org/wiki/Aozora_Bunko). The repository contains (or links to) all texts available through 青空文庫, but these files and links are contained in individual directories with varying file types, so the full text of the corpus is a bit scattered. Compiling as many of the full texts as possible into one file while preserving available metainformation will (hopefully!) provide a more accessible dataset for those looking to work with a large corpus of literary Japanese.

---

## _Data_

The data sources used for the current project are linked above, but will be compiled below for organization:

- [Aozora Bunko Corpus Japanese Page](https://www.aozora.gr.jp/), the main corpus webpage, especially useful for finding a particular text or discovering a new short story to read
- [Aozora Bunko Github Repository](https://github.com/aozorabunko/aozorabunko), from which the present corpus is built
- [Meta Information for All Texts](https://www.aozora.gr.jp/index_pages/person_all.html), for organization, of course

---

## _Approach_

Huge thanks to Dr. Molly DesJardin ([_github_](https://github.com/mollydesjardin) | [_website_](https://www.mollydesjardin.com/)) for sharing her previous work with 青空文庫, which as helpful in making sense of the **extensive** Aozora Bunko repository and keeping everything organized. By and large the present corpus is compiled via html and text file scraping, with some additional postprocessing to remove ruby characters included in some texts. Below are some notes about the approach used.

- _Text Source:_ When scraping the texts, html format was preferred as it didn't require additional unpacking of zip archives in order to access the text. In instances where the html was not succesfully scraped, the included text file was used where possible.
- _Exclusions:_ About 1.5% of the texts were not included via the Aozora Bunko repository's html "cards" or zip archives, and were often hosted on external websites. Many of these links were expired, nonexistent, or did not have any content associated with them. For simplicity and considering the small proportion of the entire corpus, these were excluded but may be incorporated in later updates.
- _Readings and Other Text Notes:_ Readings for kanji words are sometimes included in the texts, as are notes on different aspects of the text. These have been included in the present corpus via the furigana, notes, and accents tables of the database.
- _Aozora Bunko Repository:_ The script to generate the corpus assumes a copy of the Aozora Bunko repository cloned in the working directory. If you want to reproduce or work with the script, you'll need a copy of the repo cloned, which can take a wile as it's around 14gb.

---

## _Outputs_

- The compiled table with full texts, hosted on [Kaggle](https://www.kaggle.com/ryancahildebrandt/azbcorpus) in csv and DuckDB database formats
