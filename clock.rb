# encoding: UTF-8

BEGIN{
	USERNAME = ENV['USERNAME']
	PASSWORD = ENV['PASSWORD']
	FROM = ENV['mail_from']
	
	puts USERNAME
}

require 'clockwork'
require 'gmail'
#require './secret.rb'
require 'kconv'
require 'twitter'
require 'json'
require 'net/http'
include Clockwork

def full_address( address_a )
	address = address_a[0]
	return address[:mailbox] + "@" + address[:host]
end

def url_short(long_url="http://www.gehirn.co.jp/")
	result = JSON.parse(Net::HTTP.get("ux.nu","/api/short?url=#{long_url}"))
#	p result
	return result["data"]
end

handler do |job|
	Twitter.configure do |config|
		config.consumer_key = ENV['consumer_key']
		config.consumer_secret = ENV['consumer_secret']
		config.oauth_token = ENV['oauth_token']
		config.oauth_token_secret = ENV['oauth_token_secret']
	end
	
	puts USERNAME
	puts PASSWORD
	
	gmail = Gmail.new(USERNAME,PASSWORD)
	
	begin
		mails = gmail.inbox.emails(:unread,:from => FROM).each do |mail|
		
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
#					long_url[i] = line.chomp 
#					i += 1
				elsif line.include?("@")
					next
				elsif line.include?("Sent from Pocket - Get it free!")
					next
				else
					str << line
				end
			end
		
			str.chomp!
			short_url = url_short(long_url)["url"]
			tweet_str = "#{str} \n/ #{title} \n/ #{short_url}"
		 
			Twitter.update(tweet_str)
		
			puts "ツイートしました！"
			puts tweet_str
			print "\n\n"
	
		end
	rescue => ex
		puts ex.message
	ensure
		gmail.logout
	end
end

every(10.seconds, 'mail_to_tweet.job')
