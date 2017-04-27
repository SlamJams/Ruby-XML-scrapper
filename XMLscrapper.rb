require 'net/http'
require 'uri'
require 'nokogiri'
require 'rufus-scheduler'
ENV['TZ'] = 'US/Central'

Rate_Info = Struct.new(:pair, :bid, :ask, :high, :low, :direction, :last)
scheduler = Rufus::Scheduler.new

def parse(rate_info)
  encoded_url = URI.encode('http://rates.fxcm.com/RatesXML')
  url = URI.parse(encoded_url)
  response = Net::HTTP.start(url.host, use_ssl: false) do |http|
   http.get url.request_uri, 'User-Agent' => 'Mozilla/5.1'
  end

  doc = Nokogiri::XML response.body
  rate_symbol =  doc.css("*[@Symbol=#{rate_info.pair}]")
  rate_info.bid = rate_symbol.css('Bid').text
  rate_info.ask = rate_symbol.css('Ask').text
  rate_info.high = rate_symbol.css('High').text
  rate_info.low = rate_symbol.css('Low').text
  rate_info.direction = rate_symbol.css('Direction').text
  rate_info.last = rate_symbol.css('Last').text

  rate_info
end

def notify(rate_info, target_rate)
  if Float(rate_info.bid) >= Float(target_rate)
    print "Targets rate of #{target_rate} for #{rate_info.pair} has been met! Last tick was at #{rate_info.last}. "
    puts "Current rate is #{rate_info.bid}."
  else
    puts "Current rate of #{rate_info.pair} is #{rate_info.bid}. Last tick was at #{rate_info.last}."
  end
end

rate_info = Rate_Info.new
puts 'Enter pair'
rate_info.pair = gets.chomp
puts 'Enter target rate'
target_rate = gets.chomp

scheduler.every '20s' do
  notify(parse(rate_info), target_rate)
end

scheduler.join
