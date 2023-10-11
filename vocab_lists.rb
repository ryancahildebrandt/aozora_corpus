#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#Created on Mon Sep 18 08:02:02 PM EDT 2023 
#author: Ryan Hildebrandt, github.com/ryancahildebrandt

# imports
require "nokogiri"
require "open-uri"
require "descriptive-statistics"

def get_list_from_wikipedia(url)
	out = {}
	doc = Nokogiri::HTML(URI.open(url))
	doc.search('tr').each do |row|
		arr = []
		row.search('td').each{|val| arr << val.text}
		term = arr[2]
		freq = arr[1].to_f/1000000
		out[term] = freq
	end
	return out
end

def get_list_from_tangorin(url, label)
	doc = Nokogiri::HTML(URI.open(url))
	out = doc.search("li").map{|row| [row.text.gsub(/[【《a-zA-Z0-9].*/, "").strip, label]}.to_h
	return out
end

def scale_10(in_val, max)
	return (in_val/max) * 10
end

def descriptives_from_key(tokens, key)
	arr = tokens.map{|t| key[t]}.compact
	stat = DescriptiveStatistics::Stats.new(arr)
	out = [stat.mean, stat.median, stat.min, stat.max, (stat.value_from_percentile(75).to_f - stat.value_from_percentile(25).to_f)].map{|x| x || 0.0}
	return out
end

def aggregate_descriptives(joyo_descriptives, jlpt_descriptives, freq_descriptives)
	agg = [
		joyo_descriptives.map{|val| scale_10(val, 7)},
		jlpt_descriptives.map{|val| scale_10(val, 5)},
		freq_descriptives.map{|val| scale_10(val, 101)}
	]
	out = agg.transpose.map{|row| (row.sum/3).round(2)}
	return out
end

def load_vocab_lists()
	freq_key = {}
	jlpt_key = {}
	joyo_key = {}
	jlpt_urls = {
		"https://tangorin.com/vocabulary/65001" => 1.0,
		"https://tangorin.com/vocabulary/65011" => 1.0,
		"https://tangorin.com/vocabulary/65002" => 2.0,
		"https://tangorin.com/vocabulary/65012" => 2.0,
		"https://tangorin.com/vocabulary/65003" => 3.0,
		"https://tangorin.com/vocabulary/65013" => 3.0,
		"https://tangorin.com/vocabulary/65004" => 4.0,
		"https://tangorin.com/vocabulary/65014" => 4.0,
		"https://tangorin.com/vocabulary/65005" => 5.0,
		"https://tangorin.com/vocabulary/65015" => 5.0
	}
	joyo_urls = {
		"https://tangorin.com/vocabulary/65021" => 1.0,
		"https://tangorin.com/vocabulary/65022" => 2.0,
		"https://tangorin.com/vocabulary/65023" => 3.0,
		"https://tangorin.com/vocabulary/65024" => 4.0,
		"https://tangorin.com/vocabulary/65025" => 5.0,
		"https://tangorin.com/vocabulary/65026" => 6.0,
		"https://tangorin.com/vocabulary/65030" => 7.0
	}

	freq_key.merge!(get_list_from_wikipedia("https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/Japanese2022_10000"))
	freq_key.merge!(get_list_from_wikipedia("https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/Japanese2022_10001-20000"))
	jlpt_urls.map{|url, label| jlpt_key.merge!(get_list_from_tangorin(url, label))}
	joyo_urls.map{|url, label| joyo_key.merge!(get_list_from_tangorin(url, label))}

	keys = freq_key.keys + jlpt_key.keys + joyo_key.keys
	vocab_key = {}
	keys.each{|term| vocab_key[term] = [joyo_key[term], jlpt_key[term], freq_key[term]]}
	
	out = [freq_key, jlpt_key, joyo_key, vocab_key]
	return out 
end
