#!/usr/bin/env Rscript
# -*- coding: utf-8 -*-

#Created on Sun 05 Sep 2021 01:31:23 PM EDT
#author: Ryan Hildebrandt, github.com/ryancahildebrandt

# Doc Setup----
{


  library(DBI)
  library(duckdb)
  library(rvest)
  library(tidyverse)
  library(magrittr)
}

# Functions ----
get_text_html <- function(html_path, enc){
  out <- tryCatch(
    expr = {
      read_html(html_path, encoding = enc) %>%
        html_elements(., "body") %>%
        html_nodes(., "div.main_text") %>%
        html_text(.) %>%
        str_remove_all(., "\\n|\\r|\\s|[（《][ぁ-んァ-ンヽゞゝ／″＼]*[》）]")
    },
    error = function(e){
      message("Error:")
      print(e)
    }
  )
  out
}

get_text_zip <- function(zip, txt){
  unz(zip, txt) %>%
    read_lines(., locale = locale(encoding = "SHIFT-JIS")) %>%
    paste0(., collapse = "") %>%
    str_remove_all(., "\\n|\\r|\\s|[（《][ぁ-んァ-ンヽゞゝ／″＼｜]*[》）]|［＃.*?］|『.*?』")
}

main_text_clean <- function(txt){
  txt %>%
    str_remove_all(., "(---.*---)") %>%
    str_remove_all(., "底本[：・「:].*") %>%
    str_remove_all(., "入力(者)?[：・「:].*")
}

genres <- read_csv("./outputs/分類番号.csv")
genre_list <- deframe(genres)

# Readin ----
temp <- tempfile()
download.file("https://www.aozora.gr.jp/index_pages/list_person_all_extended_utf8.zip", temp)
azb_meta <- read_csv(unz(temp, "list_person_all_extended_utf8.csv"))
unlink(temp)

meta_df_raw <- azb_meta %>%
  rowwise(.) %>%
  mutate(.,
         html_path = str_replace(`XHTML/HTMLファイルURL`, "https://www.aozora.gr.jp", "./aozorabunko"),
         zip_path = str_replace(`テキストファイルURL`, "https://www.aozora.gr.jp", "./aozorabunko")) %>%
  filter(.,
         grepl("\\./aozorabunko", html_path),
         grepl("\\./aozorabunko", zip_path),
         file.exists(html_path),
         file.exists(zip_path)
  ) %>%
  mutate(.,
         main_text = list(get_text_html(html_path, `XHTML/HTMLファイル符号化方式`)),
         text_file = NA,
         text_length = length(main_text)
         )

html_success_df <- meta_df_raw %>%
  filter(., text_length == 1) %>%
  mutate(., main_text = unlist(main_text))

byte_error_df <- meta_df_raw %>%
  filter(., text_length > 1) %>%
  mutate(., text_file = list(unzip(zip_path, list = TRUE)$Name)) %>%
  mutate(., text_file = list(text_file[!is.na(str_extract(text_file, ".*\\.txt"))])) %>%
  mutate(., main_text = get_text_zip(zip_path, text_file))

zero_length_df <- meta_df_raw %>%
  filter(., text_length == 0) %>%
  mutate(., text_file = list(unzip(zip_path, list = TRUE)$Name)) %>%
  mutate(., main_text = get_text_zip(zip_path, text_file))

# Main dataframe compilation----
meta_df <- bind_rows(
  html_success_df,
  byte_error_df,
  zero_length_df)  %>%
  mutate(.,
         main_text = main_text_clean(main_text),
         分類番号 = gsub("[NDCK ]", "", 分類番号) %>% substr(., 1, 3),
         著者 = glue::glue(replace_na(名, ""), replace_na(姓, ""))) %>%
  mutate(.,
         n_char = nchar(main_text),
         分類 = purrr::map_chr(分類番号, ~genre_list[.x]),
         text_file = toString(text_file)
         ) %>%
  rowid_to_column(., "db_id")

en_cols <- c("db_id", "work_id", "work_name", "work_name_reading", "reading_sort", "subtitle", "subtitle_reading", "original_title", "first_appearance", "category_number", "character_type", "copyright_flag", "publication_date","last_updated", "card_url", "author_id","last_name", "first_name", "last_name_reading","first_name_reading", "last_name_reading_sort", "first_name_reading_sort","last_name_romaji", "first_name_romaji", "role_flag", "date_of_birth", "date_of_death", "personal_copyright_flag", "original_name_1", "original_publisher_1", "original_first_edition_publication_year_1", "input_version_1", "proofreading_version_1", "source_text_name_1", "source_text_publisher_1", "first_edition_publication_year_1", "original_name_2", "original_publisher_2", "original_first_edition_publication_year_2", "input_version_2", "proofreading_version_2", "source_text_name_2", "source_text_publisher_2", "first_edition_publication_year_2", "entered_by", "proofread_by", "text_file_url", "text_file_last_modified", "text_file_encoding", "text_file_character_set", "text_file_modification_count", "xhtml_html_file_url", "last_updated_xhtml_html_file", "xhtml_html_file_encoding", "xhtml_html_file_character_set", "xhtml_html_modification_count", "html_path", "zip_path", "main_text", "text_file", "text_length", "author", "n_char", "genre")
meta_df_en <- meta_df %>% set_names(., en_cols)

omitted_df <- azb_meta %>%
  filter(., !作品ID %in% meta_df_en$work_id) %>%
  rowwise(.) %>%
  mutate(.,
         html_path = str_replace(`XHTML/HTMLファイルURL`, "https://www.aozora.gr.jp", "./aozorabunko"),
         zip_path = str_replace(`テキストファイルURL`, "https://www.aozora.gr.jp", "./aozorabunko")
  )

# Export----
db_con <- dbConnect(
  duckdb(),
  dbdir = "./outputs/kaggle/aozora_corpus.db",
  )

authors_df <- meta_df_en %>%
  select(., author_id, author, last_name, first_name, last_name_reading, first_name_reading, last_name_reading_sort, first_name_reading_sort, last_name_romaji, first_name_romaji, date_of_birth, date_of_death, personal_copyright_flag) %>%
  unique(.)

works_df <- meta_df_en %>%
  select(., work_id, work_name, work_name_reading, reading_sort, subtitle, subtitle_reading, original_title, first_appearance, category_number, genre, character_type, copyright_flag, publication_date, last_updated, author_id, role_flag, original_name_1, original_publisher_1, original_first_edition_publication_year_1, input_version_1, proofreading_version_1, source_text_name_1, source_text_publisher_1, first_edition_publication_year_1, original_name_2, original_publisher_2, original_first_edition_publication_year_2, input_version_2, proofreading_version_2, source_text_name_2, source_text_publisher_2, first_edition_publication_year_2, entered_by, proofread_by) %>%
  unique(.)

texts_df <- meta_df_en %>%
  select(., work_id, text_file_url, text_file_last_modified, text_file_encoding, text_file_character_set, text_file_modification_count, xhtml_html_file_url, last_updated_xhtml_html_file, xhtml_html_file_encoding, xhtml_html_file_character_set, xhtml_html_modification_count, html_path, zip_path, main_text, text_file, text_length, n_char) %>%
  unique(.)

dbWriteTable(db_con, "works", works_df, overwrite = TRUE)
dbWriteTable(db_con, "authors", authors_df, overwrite = TRUE)
dbWriteTable(db_con, "texts", texts_df, overwrite = TRUE)
dbExecute(db_con, "EXPORT DATABASE 'db';")
dbDisconnect(db_con, shutdown = TRUE)

write_csv(meta_df, file = "./outputs/kaggle/aozora_corpus.csv")
write_csv(meta_df_en, file = "./outputs/kaggle/aozora_corpus_en.csv")

write_csv(meta_df[c("db_id", "main_text")], file = "./outputs/kaggle/main_text.csv")
write_csv(meta_df %>% select(., -"main_text"), file = "./outputs/kaggle/meta_info.csv")
write_csv(meta_df_en %>% select(., -"main_text"), file = "./outputs/kaggle/meta_info_en.csv")

save(meta_df, file = "./outputs/meta_df.RData")
save(meta_df_en, file = "./outputs/meta_df_en.RData")

#load("./outputs/meta_df.RData")
#load("./outputs/meta_df_en.RData")
