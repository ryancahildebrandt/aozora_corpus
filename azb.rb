#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#Created on Mon Sep 18 07:22:07 PM EDT 2023 
#author: Ryan Hildebrandt, github.com/ryancahildebrandt

# imports
require "parallel"

require_relative "azb_utils"
require_relative "db_class"

db = AzbDB.new("outputs/kaggle/aozora_corpus.db")
db.load_metadata()
db.prepare_db()
db.load_static_arrays()

Parallel.map(db.meta_df, in_threads: 3) do |row|
#db.meta_df.each do |row|
  row["作品ID"] = row[0]
  row["XHTML/HTMLファイル符号化方式"] = db.encoding_key[row["XHTML/HTMLファイル符号化方式"]]
  row["テキストファイル符号化方式"] = db.encoding_key[row["テキストファイル符号化方式"]]
  row["本文"] = read_main_text(row["XHTML/HTMLファイルURL"], row["テキストファイルURL"], row["XHTML/HTMLファイル符号化方式"], row["テキストファイル符号化方式"])
  
  if row["本文"].to_s.empty?
    htm_local = File.exist?(row["XHTML/HTMLファイルURL"].gsub("https://www.aozora.gr.jp", "./aozorabunko")) ? row["XHTML/HTMLファイルURL"].gsub("https://www.aozora.gr.jp", "./aozorabunko") : ""
    txt_local = File.exist?(row["テキストファイルURL"].gsub("https://www.aozora.gr.jp", "./aozorabunko")) ? row["テキストファイルURL"].gsub("https://www.aozora.gr.jp", "./aozorabunko") : ""
    htm_remote = try_url(row["XHTML/HTMLファイルURL"]) ? row["XHTML/HTMLファイルURL"] : ""
    txt_remote = try_url(row["テキストファイルURL"]) ? row["テキストファイルURL"] : ""
    open("empties.txt", "a"){|f| f.puts "#{htm_local}, #{txt_local}, #{htm_remote}, #{txt_remote}"}
  end

  row["著者"] = "#{row["名"]}#{row["姓"]}"
  row["分類番号"] = row["分類番号"][/[0-9]{3}/]
  row["分類"] = db.genres_output.to_h[row["分類番号"]]
  
  row["振り仮名"]= extract_furigana(row["作品ID"], row["本文"])
  row["注釈"] = extract_notes(row["作品ID"], row["本文"])
  row["高低アクセント"] = extract_pitch_accents(row["作品ID"], row["本文"])
  row["本文"] = remove_notes(row["本文"])
  row["本文字数"] = row["本文"].length

  tokens = db.tagger.segment(row["本文"])
  row["常用"] = descriptives_from_key(tokens, db.joyo_key)
  row["日本語能力試験"] = descriptives_from_key(tokens, db.jlpt_key)
  row["出現頻度"] = descriptives_from_key(tokens, db.freq_key)
  row["通算難易度"] = aggregate_descriptives(row["常用"], row["日本語能力試験"], row["出現頻度"])

  db.authors_output.append([row["人物ID"], row["姓"], row["名"], row["姓読み"], row["名読み"], row["姓読みソート用"], row["名読みソート用"], row["姓ローマ字"], row["名ローマ字"], row["生年月日"], row["没年月日"], row["人物著作権フラグ"], row["著者"]])
  db.works_output.append([row["作品ID"], row["作品名"], row["作品名読み"], row["ソート用読み"], row["副題"], row["副題読み"], row["原題"], row["初出"], row["分類番号"], row["分類"], row["文字遣い種別"], row["作品著作権フラグ"], row["公開日"], row["最終更新日"], row["人物ID"], row["役割フラグ"], row["底本名1"], row["底本出版社名1"], row["底本初版発行年1"], row["入力に使用した版1"], row["校正に使用した版1"], row["底本の親本名1"], row["底本の親本出版社名1"], row["底本の親本初版発行年1"], row["底本名2"], row["底本出版社名2"], row["底本初版発行年2"], row["入力に使用した版2"], row["校正に使用した版2"], row["底本の親本名2"], row["底本の親本出版社名2"], row["底本の親本初版発行年2"], row["入力者"], row["校正者"]])
  db.texts_output.append([row["作品ID"], row["図書カードURL"], row["テキストファイルURL"], row["テキストファイル最終更新日"], row["テキストファイル符号化方式"], row["テキストファイル文字集合"], row["テキストファイル修正回数"], row["XHTML_HTMLファイルURL"], row["XHTML_HTMLファイル最終更新日"], row["XHTML_HTMLファイル符号化方式"], row["XHTML_HTMLファイル文字集合"], row["XHTML_HTMLファイル修正回数"], row["本文"], row["本文字数"]])
  db.difficulty_output.append([row["作品ID"], row["常用"], row["日本語能力試験"], row["出現頻度"], row["通算難易度"]].flatten)
  row["振り仮名"].each{|entry| db.furigana_output.append(entry)}
  row["注釈"].each{|entry| db.notes_output.append(entry)}
  row["高低アクセント"].each{|entry| db.accents_output.append(entry)}

  db.progress_bar.increment
end

db.export_db()
