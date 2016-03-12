class Ticker < ActiveRecord::Base
  @@process_name_constant = "tickers_process_" # used to find orphan processes
  validates :name, presence: true
  @queue = :file_serve
  def self.killall
    `pkill -f #{@@process_name_constant}`
    update_all(process_name: nil)
  end
  def attributes
    {
      'id' => id,
      'output' => output
    }
  end
  def interval=(val)
    val ||= 1000
    super(val)
  end
  def kill
    return unless process_name
    2.times {
      pid = `ps aux | grep #{process_name.first(25)} | awk 'NR==1{print $2}'`.chomp
      `kill -9 #{pid}`
      sleep 1
    }
    self.update(process_name: nil)
  end
  def begin
    tempfile_name = @@process_name_constant + SecureRandom.urlsafe_base64
    # tempfile name is used to name processes. It's important to include a constant in the name (i.e. "tickers")
    # so that the process can be found if it becomes  a orphan.
    file = Tempfile.new(tempfile_name)
    file_text = <<-RUBY
      $0 = "#{tempfile_name}"
      loop do
        #{self.content}
        sleep #{self.interval.to_f / 1000}
      end
    RUBY
    tempfile_path = file.path
    file.write(file_text)
    file.close # saves the write
    cmd = <<-SH
      echo "load '#{tempfile_path}'" | rails console
    SH
    cmd_pid = spawn(cmd, pgroup: true)
    Process.detach(cmd_pid)
    self.update(process_name: tempfile_name)
  end
end
