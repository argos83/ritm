require 'ritm/user/project'

project = Ritm::Project.find

def repl(prompt)
  result = nil
  loop do
    print prompt
    STDOUT.flush
    result = yield gets.chomp
    break unless result.nil?
  end
  result
end

if project
  puts "Loading settings from: #{project.path}"
else
  puts 'No project could be found'
  if repl('Do you want to create a new project? [Y|n]: ') { |a| a.empty? || a.casecmp('y') }
    location = repl('Enter the project root directory [~/.ritm]: ') { |a| a.empty? ? File.join(Dir.home, '.ritm') : a }
    project = Ritm::Project.create location
  else
    exit
  end
end

proxy = project.configure

proxy.start

puts "Loading settings from: #{project.path}"
puts "Proxy listening on #{project.settings[:proxy][:address]}:#{project.settings[:proxy][:port]}"
puts "CA certificate: #{project.settings[:proxy][:ssl_reverse_proxy][:ca][:pem]}"

puts 'Enter a command (\'help\' for available commands)'
repl('> ') do |command|
  case command
  when 'help'
    puts 'bla bla bla'
    nil
  when 'pause'
    puts 'Fuzzer disabled'
    Ritm.conf.intercept.enabled = false
    nil
  when 'resume'
    puts 'Fuzzer enabled'
    Ritm.conf.intercept.enabled = false
    nil
  when 'start'
    nil
  when 'exit', 'quit'
    puts 'Stopping proxy service...'
    proxy.shutdown
    true
  end
end
