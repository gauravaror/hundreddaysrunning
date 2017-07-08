class PostWorker
  require 'uri'
  require 'net/http'
  require 'nokogiri'
  require 'strava/api/v3'
  require 'active_support'

  include Sidekiq::Worker

  def perform(user_id, date)
    if user_id.eql? -1
      User.all.each do |us|
        missing_days = Day.where.not(:id => us.runs.map(&:day_id)).where("day >= ?", 1.week.ago).where("day <= ?", Time.now )
        missing_days.all.each do |days|
            post_it(us.id, days.day.strftime("%Y-%m-%d"))
        end
      end
    else
      post_it(user_id,date)
    end
  end

  def post_it(user_id, date)
    # Do something
    user = User.find(user_id)
    http = Net::HTTP.new('app.100daysofrunning.in', '80')
    puts "=========Doing Login================"
    puts user.reporting_email
    if user.dob
      puts user.dob.strftime("DDMMYYYY")
    else
      puts "User " + user.reporting_email + " doesn't have dob updated  exiting the flow"
      return
    end

    data = 'username=' + user.reporting_email  + '&password=' + user.dob.strftime("%d%m%Y");
    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
    path= '/customApp/login';
    resp, data = http.post(path, data, headers)

    cookie = resp.response['set-cookie'].split('; ')[0]

    puts 'Code = ' + resp.code
    puts 'Message = ' + resp.message
    resp.each {|key, val| puts key + ' = ' + val}
    puts data
    puts cookie
    puts "=============Submitting Run for today================="

    uri = URI('http://app.100daysofrunning.in/customApp/logDailyRun.htm')
    req = Net::HTTP::Get.new(uri)
    req['cookie'] = cookie
    resp = http.request(req)

    # Output on the screen -> we should get either a 302 redirect (after a successful login) or an error page
    puts 'Code = ' + resp.code
    puts 'Message = ' + resp.message
    resp.each {|key, val| puts key + ' = ' + val}
    puts resp.body
    fragment = Nokogiri::HTML.fragment(resp.body)
    runner = fragment.at('input[name="runnerId"]')
    runnerId = ""
    if runner
      runnerId = runner['value']
    else
      puts "User " + user.reporting_email + " probably not registered with 100daysofrunning"
      return
    end
    puts "runnerId"
    puts runnerId
    #date = "2017-06-21"
    start_date = DateTime.parse(date+' 00:00:00 IST').to_time
    end_date = DateTime.parse(date+' 23:59:59 IST').to_time
    puts start_date
    puts end_date
   client = Strava::Api::V3::Client.new(:access_token => user.access_token)
   activities = client.list_athlete_activities(:after => start_date.to_f, :before => end_date.to_f)
   puts activities
   distance = 0;
   seconds = 0;
   links = ' ';
   activities.each do |child|
   num_link = 0;
	if child['type'].eql? 'Run'
	  distance += child['distance']
	  seconds += child['moving_time']
    if (!child['private'] && (num_link < 2))
       num_link = num_link +1;
       links += 'https://www.strava.com/activities/' + child['id'].to_s;
       links += ' ; '
     end
	end
   end
   if distance.eql? 0
     return
   end
   distance = distance/1000
   puts distance
   puts seconds
   puts links
   puts Time.at(seconds).utc.hour
   puts Time.at(seconds).utc.min
   puts Time.at(seconds).utc.sec
    data = 'runnerId='+runnerId + '&runDate=' + date  + '&distance=' + distance.to_s + '&hours=' + Time.at(seconds).utc.hour.to_s + '&minutes=' + Time.at(seconds).utc.min.to_s + '&seconds=' + Time.at(seconds).utc.sec.to_s + '&runLogDetails=' + links;
    headers = {
      'cookie' => cookie,
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
    path= '/customApp/saveDailyRun.htm';
    resp, data = http.post(path, data, headers)


    puts 'Code = ' + resp.code

    puts "=========Showing Runs================"
    uri = URI('http://app.100daysofrunning.in/customApp/showDailyRuns.htm')
    req = Net::HTTP::Get.new(uri)
    req['cookie'] = cookie
    resp = http.request(req)

    # Output on the screen -> we should get either a 302 redirect (after a successful login) or an error page
    puts 'Code = ' + resp.code
    puts 'Message = ' + resp.message
    resp.each {|key, val| puts key + ' = ' + val}
#    puts resp.body
    fragment = Nokogiri::HTML(resp.body)
   # puts fragment
    rows = fragment.search('tr')
    details = rows.each do |row|
      #puts row
      detail = {}
  	[
  	  [:date, 'td[1]/text()'],
  	  [:distance, 'td[2]/text()'],
  	  [:time, 'td[3]/text()'],
  	  [:link, 'td[4]/text()'],
  	].each do |name, xpath|
  	  detail[name] = row.at_xpath(xpath).to_s.strip
    end
    day = Day.find_by(:day => detail[:date])
    if day != nil
      run = day.runs.where(user_id: user_id).first
      if run == nil
        day.runs.create(:user_id => user_id, :distance => detail[:distance], :time => detail[:time], :link => detail[:link].chars.slice(0,50).join)
      else
        run.update(:user_id => user_id, :distance => detail[:distance], :time => detail[:time], :link => detail[:link].chars.slice(0,50).join)
      end
    end
    end
  end
end
