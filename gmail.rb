# coding: UTF-8

require 'gmail'
#require './secret.rb'
require 'kconv'
require 'twitter'
require 'json'
require 'net/http'

Twitter.configure do |config|
	config.consumer_key = ENV['consumer_key']
	config.consumer_secret = ENV['consumer_secret']
	config.oauth_token = ENV['oauth_token']
	config.oauth_token_secret = ENV['oauth_token_secret']
end

def full_address( address_a )
	address = address_a[0]
	return address[:mailbox] + "@" + address[:host]
end

def url_short(long_url=nil)
	return nil if long_url == nil
	result = JSON.parse(Net::HTTP.get("ux.nu","/api/short?url=#{long_url}"))
#	p result
	return result["data"]
end

USERNAME = ENV['USERNAME']
PASSWORD = ENV['PASSWORD']
from = ENV['mail_from']

puts USERNAME
puts PASSWORD


gmail = Gmail.new(USERNAME,PASSWORD)

#begin
mails = gmail.inbox.emails(:unread,:from => from).each do |mail|
	
	subject = mail.subject.toutf8
	from = full_address(mail.from)
	to = full_address(mail.to)
	
	puts "From: #{from}"
	puts "Subject: #{subject}"
	puts "To: #{to}"
	
	body = String.new
	if mail.text_part
		puts "text: #{mail.text_part.decoded}"
		body = mail.text_part.decoded
	elsif mail.html_part
		puts "html: #{mail.html_part.decoded}"
		body = mail.html_part.decoded
	elsif
		puts "body: #{mail.body.decoded.encode("UTF-8",mail.charset)}"
		body = mail.body.decoded.encode("UTF-8",mail.charset)
	end
	puts "body:"
	p body
	title = subject
	next unless to == USERNAME
	
	page_title = subject.chomp
	title_length = title.length
	i = 0
	str = String.new
	long_url = String.new
	p body
	body.each_line do |line|
		if /^http:\/\// =~ line
			puts "URL: #{line}"
			long_url = line.chomp
#			long_url[i] = line.chomp 
#			i += 1
		elsif line.include?("@")
			next
		elsif line.include?("＠")
			next
		elsif line.include?("Sent from Pocket - Get it free!")
			next
		else
			str << line
		end
	end
	
	short_url = url_short(long_url)["url"]
	tweet_str = "#{str} \n/ #{title} \n/ #{short_url}"
	 
	Twitter.update(tweet_str)
=begin	
	url_before = Array.new
	short_url = Array.new
	i.times do |t|
		break if long_url == nil
		shorten = url_short(long_url[t])
		url_before[t] = "unsafe!" unless shorten["safe"] == "true"
		short_url[t] = shorten["url"]
	end
	
	url_length = 0
	short_url.each do |url|
		url_length += url.length + 2
	end
	
	first_tweet = true
	while str.length + url_length + title_length >= 120
		break if str.empty?
		
		s_str = String.new
		if first_tweet
			s_str << "(始め)"
			first_tweet = false
		else
			s_str << "(続き)" 
		end
		s_str = str.slice!(0,120) 
		
		if str.length + url_length + title_length >= 120
			s_str << "(続く)"
		end
		
		Twitter.update(s_str)
	end
	
	tweet_str = String.new
	tweet_str << "(続き)" unless first_tweet
	
	tweet_str << str + " \n/ " + page_title + " / " 
	
	short_url.size.times do |i|
		tweet_str << "\n#{url_before[i]} #{short_url[i]}"
	end
	tweet_str << "(終わり)" unless first_tweet
	
	Twitter.update(tweet_str)
	
=end
end
#rescue
#	puts "エラーが発生しました。"
#	puts $@
#ensure
gmail.logout
#end
