require 'clockwork'
include Clockwork

handler do |job|
	require './gmail.rb'
  puts "Running #{job}"
end

every(10.seconds, 'frequent.job')
