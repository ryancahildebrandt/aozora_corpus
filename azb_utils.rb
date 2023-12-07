#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#Created on Mon Sep 18 07:27:20 PM EDT 2023 
#author: Ryan Hildebrandt, github.com/ryancahildebrandt

# imports
require "open-uri"
require "zip/zip"
require "nokogiri"

require_relative "db_class"

def try_url(url)
	begin
		URI.open(url)
		out = true
	rescue => e
		#puts e
		out = false
	end
	return out
end

def select_valid_file(html_url, zip_url)
	html_path = html_url.gsub("https://www.aozora.gr.jp", "./aozorabunko")
	zip_path = zip_url.gsub("https://www.aozora.gr.jp", "./aozorabunko")
	if html_url.empty? && zip_url.empty?
		out = ""
	elsif File.exist?(html_path)
		out = html_path
	elsif try_url(html_url)
		out = html_url
	elsif File.exist?(zip_path)
		out = zip_path
	elsif try_url(html_url)
		out = zip_url
	else
		out = ""
	end
	return out
end

def read_html(file, encoding)
	out = file.match("http") ? URI.open(file, "r:#{encoding}:UTF-8") : File.open(file, "r:#{encoding}").read
	return out
end

def parse_html(html_str)
	doc = Nokogiri::HTML.parse(html_str)
	begin
		out = doc.at("body").at_css("div.main_text").content
	rescue
		out = doc.at("body").content
	rescue => e
		out = ""
		puts e
	end
	return out
end

def read_txt(file, encoding)
	zipfile = file.match?(/http.*zip/) ? URI.open(file, "r:#{encoding}:UTF-8").read : File.open(file, "r:#{encoding}")
	begin
		zipfile do |zf|
			zf.each do |f|
				tmp = Tempfile.new
				f.extract(tmp.path){true}
			end
		end
	rescue => e
		out = ""
		puts e
	end
	out = tmp.path
	puts out
	return out
end

def parse_txt(tmp_path)
	out = File.open(tmp.path, "r:#{encoding}:UTF-8").read
	return out
end

def clean_main_text(in_text)
	out = in_text.gsub(/底本[：・「:].*/, "")
	out = out.gsub(/入力(者)?[：・「:].*/, "")
	out = out.gsub(/[\n\r\t\u{3000}]/, "")
	out = out.gsub(/---.*---/, "")
	return out
end

def read_main_text(html_url, zip_url, html_encoding, zip_encoding)
	file = select_valid_file(html_url, zip_url)
	if file.match?(/\.htm/)
		#azb html
		html_str = read_html(file, html_encoding)
		out = parse_html(html_str)
	elsif file.match?(/\.zip/)
		#txt
		tmp_path = read_txt(file, zip_encoding)
		out = parse_txt(tmp_path)
	elsif file.match?(/http/)
		#non azb html
		html_str = read_html(file, html_encoding)
		out = parse_html(html_str)
	else
		out = ""
	end
	
	out = clean_main_text(out)
	return out
end

def get_note_info(text_id, note, text)
	note_ind = text.index(note)
	context_start = [note_ind - note.length, 0].max
	context_stop = [note_ind + note.length, text.length].min
	out = [text_id, note_ind, text[context_start..context_stop], note]
	return out
end

def extract_furigana(text_id, in_text)
	res = in_text.scan(/[（《][ぁ-んァ-ンヽゞゝ／″＼]*?[》）]/)
	out = res.map{|note| get_note_info(text_id, note, in_text)}
	return out
end

def extract_notes(text_id, in_text)
	res = in_text.scan(/[［（《][^ぁ-んァ-ンヽゞゝ／″＼［（《》）］]*[》）］]/)
	out = res.map{|note| get_note_info(text_id, note, in_text)}
	return out
end

def extract_pitch_accents(text_id, in_text)
	res = in_text.scan(/[／″＼]+/)
	out = res.map{|note| get_note_info(text_id, note, in_text)}
	return out
end

def remove_notes(in_text)
	out = in_text
	out.gsub!(/[［（《].*?[》）］]/, "")
	out.gsub!(/[／″＼]+/, "")
	return out
end
