require 'securerandom'
require 'tempfile'

class Backgrounder
  attr_accessor :process_name, :interval, :script_content

  def initialize(options={})
    @interval, @script_content = options.values_at(:interval, :script_content)
    raise ArgumentError unless [interval, script_content].all?
  end

  def begin
    tempfile_name = SecureRandom.urlsafe_base64
    tempfile = Tempfile.new(tempfile_name)
    tempfile_path = tempfile.path
    tempfile_content = <<-RUBY
      $0 = "#{tempfile_name}" # changes the name of the program
      while true
        #{self.script_content}
        sleep #{self.interval.to_f / 1000}
      end
    RUBY
    tempfile.write(tempfile_content)
    tempfile.close # saves the write
    require 'byebug'
    cmd = <<-SH
      echo "load '#{tempfile_path}'" | irb
    SH
    cmd_pid = spawn(cmd, pgroup: true)
    self.process_name = tempfile_name
    Process.detach(cmd_pid) # prevents the process from blocking the current script
  end

  def kill
    # loop twice for good measure, because orphan commands are really annoying
    # it actully makes a difference though. My test didn't work otherwise. 
    2.times {
      # calls kill -9 twice, because there actually two processes for each process_name
      # the first is the headless irb console, and the second is the loaded file. 
      puts "--------\Trying to kill process named: #{self.process_name}\n----------"
      pid1 = `ps aux | grep #{self.process_name} | awk 'NR==1{print $2}'`.chomp
      `kill -9 #{pid1}`
      pid2 = `ps aux | grep #{self.process_name} | awk 'NR==2{print $2}'`.chomp
      `kill -9 #{pid2}`
    }
  end
end

backgrounder = Backgrounder.new(
  interval: 1000, script_content: "`chromium-browser http://google.com`"
)
backgrounder.begin
# => runs curl command once per second in background

sleep 2 # other background commands can be run here

backgrounder.kill
# => stops the background process