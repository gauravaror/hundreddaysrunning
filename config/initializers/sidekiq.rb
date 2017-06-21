

job = Sidekiq::Cron::Job.new(name: 'Post worker - every 4min',
args: [-1,  DateTime.now.strftime("%Y-%m-%d")] ,
cron: '0 */6 * * *', class: 'PostWorker') # execute at every 5 minutes, ex: 12:05, 12:10, 12:15...etc
unless job.save
  puts job.errors #will return array of errors
end
