#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#Created on Tue Oct 10 11:01:58 AM EDT 2023 
#author: Ryan Hildebrandt, github.com/ryancahildebrandt

# imports
require "tiny_segmenter"
require "ruby-progressbar"
require "duckdb"
require "csv"

require_relative "vocab_lists"

class AzbDB
	attr_accessor(
		:tagger,
		:con,
		:progress_bar,
		:meta_df,
		:encoding_key,
		:freq_key,
		:jlpt_key,
		:joyo_key,
		:vocab_key,
		:headers_output, 
		:genres_output, 
		:vocab_output,
		:authors_output,
		:works_output,
		:texts_output,
		:difficulty_output,
		:furigana_output,
		:notes_output,
		:accents_output
	)

	def initialize(db_path)
		self.authors_output = []
		self.works_output = []
		self.texts_output = []
		self.difficulty_output = []
		self.furigana_output = []
		self.notes_output = []
		self.accents_output = []
		self.tagger = TinySegmenter.new
		self.con = DuckDB::Database.open(db_path).connect
		self.progress_bar = ProgressBar.create(:total => 20000, :format => "%t: %p%% %e |%B| %c/~%C")
	end
	
	def load_metadata()
		zipfile = URI.open("https://www.aozora.gr.jp/index_pages/list_person_all_extended_utf8.zip")
		tmp = Tempfile.new
		Zip::ZipFile.open(zipfile) do |zf|
			zf.each do |f|
				f.extract(tmp.path){true}
			end
		end
		self.meta_df = CSV.open(
			tmp.path,
			headers: true,
			#converters: lambda{|v| v || ""},
			#header_converters: lambda{|h| h.gsub("/", "_")}
			header_converters: lambda{|h| h.bytes.pack("c*").force_encoding("UTF-8")}
		)
		self.encoding_key = {"" => "UTF-8", "UTF-8" => "UTF-8", "ShiftJIS" => "Shift_JIS"}
	end

	def prepare_db()
		self.con.query("
			CREATE OR REPLACE TABLE authors
			(
				人物ID VARCHAR,
				姓 VARCHAR,
				名 VARCHAR,
				姓読み VARCHAR,
				名読み VARCHAR,
				姓読みソート用 VARCHAR,
				名読みソート用 VARCHAR,
				姓ローマ字 VARCHAR,
				名ローマ字 VARCHAR,
				生年月日 VARCHAR,
				没年月日 VARCHAR,
				人物著作権フラグ VARCHAR,
				著者 VARCHAR
			);
			CREATE OR REPLACE TABLE works
			(
				作品ID VARCHAR,
				作品名 VARCHAR,
				作品名読み VARCHAR,
				ソート用読み VARCHAR,
				副題 VARCHAR,
				副題読み VARCHAR,
				原題 VARCHAR,
				初出 VARCHAR,
				分類番号 INTEGER,
				分類 VARCHAR,
				文字遣い種別 VARCHAR,
				作品著作権フラグ VARCHAR,
				公開日 VARCHAR,
				最終更新日 VARCHAR,
				人物ID VARCHAR,
				役割フラグ VARCHAR,
				底本名1 VARCHAR,
				底本出版社名1 VARCHAR,
				底本初版発行年1 VARCHAR,
				入力に使用した版1 VARCHAR,
				校正に使用した版1 VARCHAR,
				底本の親本名1 VARCHAR,
				底本の親本出版社名1 VARCHAR,
				底本の親本初版発行年1 VARCHAR,
				底本名2 VARCHAR,
				底本出版社名2 VARCHAR,
				底本初版発行年2 VARCHAR,
				入力に使用した版2 VARCHAR,
				校正に使用した版2 VARCHAR,
				底本の親本名2 VARCHAR,
				底本の親本出版社名2 VARCHAR,
				底本の親本初版発行年2 VARCHAR,
				入力者 VARCHAR,
				校正者 VARCHAR
			);
			CREATE OR REPLACE TABLE texts
			(
				作品ID VARCHAR,
				図書カードURL VARCHAR,
				テキストファイルURL VARCHAR,
				テキストファイル最終更新日 VARCHAR,
				テキストファイル符号化方式 VARCHAR,
				テキストファイル文字集合 VARCHAR,
				テキストファイル修正回数 VARCHAR,
				XHTML_HTMLファイルURL VARCHAR,
				XHTML_HTMLファイル最終更新日 VARCHAR,
				XHTML_HTMLファイル符号化方式 VARCHAR,
				XHTML_HTMLファイル文字集合 VARCHAR,
				XHTML_HTMLファイル修正回数 VARCHAR,
				本文 VARCHAR,
				本文字数 VARCHAR
			);
			CREATE OR REPLACE TABLE genres
			(
				分類番号 INTEGER,
				分類 VARCHAR
			);
			CREATE OR REPLACE TABLE vocab
			(
				単語 VARCHAR,
				常用 INTEGER,
				日本語能力試験 INTEGER,
				出現頻度 NUMERIC
			);
			CREATE OR REPLACE TABLE difficulty
			(
				作品ID VARCHAR,
				常用平均値 NUMERIC,
				常用中央値 NUMERIC,
				常用最小値 NUMERIC,
				常用最大値 NUMERIC,
				常用四分位範囲 NUMERIC,
				日本語能力試験平均値 NUMERIC,
				日本語能力試験中央値 NUMERIC,
				日本語能力試験最小値 NUMERIC,
				日本語能力試験最大値 NUMERIC,
				日本語能力試験四分位範囲 NUMERIC,
				出現頻度平均値 NUMERIC,
				出現頻度中央値 NUMERIC,
				出現頻度最小値 NUMERIC,
				出現頻度最大値 NUMERIC,
				出現頻度四分位範囲 NUMERIC,
				通算難易度平均値 NUMERIC,
				通算難易度中央値 NUMERIC,
				通算難易度最小値 NUMERIC,
				通算難易度最大値 NUMERIC,
				通算難易度四分位範囲 NUMERIC
			);
			CREATE OR REPLACE TABLE furigana
			(
				作品ID VARCHAR,
				本文中の位置 INTEGER,
				前後関係 VARCHAR,
				振り仮名 VARCHAR
			);
			CREATE OR REPLACE TABLE notes
			(
				作品ID VARCHAR,
				本文中の位置 INTEGER,
				前後関係 VARCHAR,
				注釈 VARCHAR
			);
			CREATE OR REPLACE TABLE accents
			(
				作品ID VARCHAR,
				本文中の位置 INTEGER,
				前後関係 VARCHAR,
				高低アクセント VARCHAR
			);
			CREATE OR REPLACE TABLE headers
			(
				英語 VARCHAR,
				日本語 VARCHAR
			)
			")
	end

	def load_static_arrays()
		self.headers_output = [
			["人物ID", "author_id"],
			["姓", "last_name"],
			["名", "first_name"],
			["姓読み", "last_name_reading"],
			["名読み", "first_name_reading"],
			["姓読みソート用", "last_name_reading_sort"],
			["名読みソート用", "first_name_reading_sort"],
			["姓ローマ字", "last_name_romaji"],
			["名ローマ字", "first_name_romaji"],
			["役割フラグ", "role_flag"],
			["生年月日", "date_of_birth"],
			["没年月日", "date_of_death"],
			["人物著作権フラグ", "personal_copyright_flag"],
			["著者", "author"],
			["作品ID", "work_id"],
			["作品名", "work_name"],
			["作品名読み", "work_name_reading"],
			["ソート用読み", "reading_sort"],
			["副題", "subtitle"],
			["副題読み", "subtitle_reading"],
			["原題", "original_title"],
			["初出", "first_appearance"],
			["分類番号", "category_number"],
			["分類", "genre"],
			["文字遣い種別", "character_type"],
			["作品著作権フラグ", "copyright_flag"],
			["公開日", "publication_date"],
			["最終更新日", "last_updated"],
			["底本名1", "original_name_1"],
			["底本出版社名1", "original_publisher_1"],
			["底本初版発行年1", "original_first_edition_publication_year_1"],
			["入力に使用した版1", "input_version_1"],
			["校正に使用した版1", "proofreading_version_1"],
			["底本の親本名1", "source_text_name_1"],
			["底本の親本出版社名1", "source_text_publisher_1"],
			["底本の親本初版発行年1", "first_edition_publication_year_1"],
			["底本名2", "original_name_2"],
			["底本出版社名2", "original_publisher_2"],
			["底本初版発行年2", "original_first_edition_publication_year_2"],
			["入力に使用した版2", "input_version_2"],
			["校正に使用した版2", "proofreading_version_2"],
			["底本の親本名2", "source_text_name_2"],
			["底本の親本出版社名2", "source_text_publisher_2"],
			["底本の親本初版発行年2", "first_edition_publication_year_2"],
			["入力者", "entered_by"],
			["校正者", "proofread_by"],
			["図書カードURL", "card_url"],
			["テキストファイルURL", "text_file_url"],
			["テキストファイル最終更新日", "text_file_last_modified"],
			["テキストファイル符号化方式", "text_file_encoding"],
			["テキストファイル文字集合", "text_file_character_set"],
			["テキストファイル修正回数", "text_file_modification_count"],
			["XHTML_HTMLファイルURL", "xhtml_html_file_url"],
			["XHTML_HTMLファイル最終更新日", "xhtml_html_file_last_modified"],
			["XHTML_HTMLファイル符号化方式", "xhtml_html_file_encoding"],
			["XHTML_HTMLファイル文字集合", "xhtml_html_file_character_set"],
			["XHTML_HTMLファイル修正回数", "xhtml_html_file_modification_count"],
			["本文", "main_text"],
			["本文字数", "text_length"],
			["単語", "term"],
			["常用", "joyo_grade"],
			["日本語能力試験", "jlpt_level"],
			["出現頻度", "frequency"],
			["常用平均値", "joyo_mean"],
			["常用中央値", "joyo_median"],
			["常用最小値", "joyo_min"],
			["常用最大値", "joyo_max"],
			["常用四分位範囲", "joyo_iqr"],
			["日本語能力試験平均値", "jlpt_mean"],
			["日本語能力試験中央値", "jlpt_median"],
			["日本語能力試験最小値", "jlpt_min"],
			["日本語能力試験最大値", "jlpt_max"],
			["日本語能力試験四分位範囲", "jlpt_iqr"],
			["出現頻度平均値", "frequency_mean"],
			["出現頻度中央値", "frequency_median"],
			["出現頻度最小値", "frequency_min"],
			["出現頻度最大値", "frequency_max"],
			["出現頻度四分位範囲", "frequency_iqr"],
			["通算難易度平均値", "aggregate_difficulty_mean"],
			["通算難易度中央値", "aggregate_difficulty_median"],
			["通算難易度最小値", "aggregate_difficulty_min"],
			["通算難易度最大値", "aggregate_difficulty_max"],
			["通算難易度四分位範囲", "aggregate_difficulty_iqr"],
			["本文中の位置", "text_index_start"],
			["前後関係", "context"],
			["振り仮名", "furigana"],
			["注釈", "note"],
			["高低アクセント", "pitch_accent"],
			["英語", "en"],
			["日本語", "jp"]
		]
		self.freq_key, self.jlpt_key, self.joyo_key, self.vocab_key = load_vocab_lists()
		self.genres_output = CSV::read("./data/分類番号.csv")[1 .. -1].to_a
		self.vocab_output = self.vocab_key.to_a.map{|row| row.flatten}
	end
	
	def write_to_table(table, data)
		appender = self.con.appender(table)
		pb = ProgressBar.create(
			:title => "Writing to #{table} table",
			:total => data.length,
			:format => "%t: %c/%C |%B| %p%%"
		)
	
		data.uniq.each do |row|
			appender.begin_row
			row.each{|field| appender.append(field)}
			appender.end_row
			pb.increment
		end
	
		appender.flush
	end
	
	def export_db()
		["authors", "works", "texts", "genres", "vocab", "difficulty", "furigana", "notes", "accents", "headers"].each{|table| write_to_table(table, eval("self.#{table}_output"))}
		self.con.query("EXPORT DATABASE 'outputs/kaggle/db/';")
		self.con.query("COPY (
			SELECT 
				作品ID, 
				本文 
			FROM texts
			) TO 'outputs/kaggle/main_text.csv' (HEADER);")
		self.con.query("COPY (
			SELECT *
			FROM works
			JOIN authors USING(人物ID)
			JOIN texts USING(作品ID)
			) TO 'outputs/kaggle/aozora_corpus.csv' (HEADER);")
		self.con.query("COPY (
			SELECT 
				works.作品ID, 
				works.作品名, 
				works.作品名読み, 
				works.ソート用読み, 
				works.副題, 
				works.副題読み, 
				works.原題, 
				works.初出, 
				works.分類番号, 
				works.文字遣い種別, 
				works.作品著作権フラグ, 
				works.公開日, 
				works.最終更新日, 
				authors.人物ID, 
				authors.姓, 
				authors.名, 
				authors.姓読み, 
				authors.名読み, 
				authors.姓読みソート用, 
				authors.名読みソート用, 
				authors.姓ローマ字, 
				authors.名ローマ字, 
				authors.生年月日, 
				authors.没年月日, 
				authors.人物著作権フラグ, 
				works.役割フラグ, 
				works.底本名1, 
				works.底本出版社名1, 
				works.底本初版発行年1, 
				works.入力に使用した版1, 
				works.校正に使用した版1, 
				works.底本の親本名1, 
				works.底本の親本出版社名1, 
				works.底本の親本初版発行年1, 
				works.底本名2, 
				works.底本出版社名2, 
				works.底本初版発行年2, 
				works.入力に使用した版2, 
				works.校正に使用した版2, 
				works.底本の親本名2, 
				works.底本の親本出版社名2, 
				works.底本の親本初版発行年2, 
				works.入力者, 
				works.校正者, 
				texts.図書カードURL,
				texts.テキストファイルURL, 
				texts.テキストファイル最終更新日, 
				texts.テキストファイル符号化方式, 
				texts.テキストファイル文字集合, 
				texts.テキストファイル修正回数, 
				texts.XHTML_HTMLファイルURL, 
				texts.XHTML_HTMLファイル最終更新日, 
				texts.XHTML_HTMLファイル符号化方式, 
				texts.XHTML_HTMLファイル文字集合, 
				texts.XHTML_HTMLファイル修正回数
			FROM works
			JOIN authors USING(人物ID)
			JOIN texts USING(作品ID)
			) TO 'outputs/kaggle/meta_info.csv' (HEADER);")
	end
end
