task :security_scan do
  cmd = %{ ( #{ 3.times.map { %{echo "\\n"; } }.join(" ") } ) | sudo rkhunter -c}
  IO.popen(cmd) do |io|
    while (line = io.gets) do
      puts line
    end
  end  
end
