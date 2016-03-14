# Tickers

#### Screenshots

![screenshot 1](https://raw.githubusercontent.com/MaxPleaner/tickers/master/public/screenshot1.png)
![screenshot 2](https://raw.githubusercontent.com/MaxPleaner/tickers/master/public/screenshot2.png)

## How to run

- Note you need Postgres server set up.
- Tested with Ruby 2.4.0

Run the following commands:

```sh
git clone https://github.com/MaxPleaner/tickers/;
cd tickers;
bundle;
rake db:create db:migrate db:seed; 
```

Then customize `config/application.yml` with your preferred username / password (for dev mode, use ENV vars if deploying)

Note that the default username is "admin" and the password is "password". This is used for basic HTTP auth as well as the `/update_output` route (explained later). 

Next run `rails server` and visit localhost:3000. 

## Web interface usage

Basically there's a couple steps to making a realtime "ticker":

1. Go to the "create" page
2. In the text editor, write a Ruby script, but folow some specific rules:
  - The return value of this script is ignored.
  - Instead, the  `curl localhost:3000/update_output` command is used:
    - Set the 'password' param which is the same used for HTTP auth.
    - Set the 'name' param on this route to be the same as the name you give the script.
    - The 'content' is a URI encoded string, which becomes the displayed text in the ticker.
    - For example, with a script named "MyScript", the command `curl localhost:3000/update_output?name=MyScript&output=#{SecureRandom.urlsafe_base64}` will change the displayed text on the  "MyScript" ticker to a random string. If you set this to run every 1000 milliseconds (via the `interval` value chosen), then a new random string will appear every second. 
    - You can use an `id` param in place of `name` - this is necessary when updating a script's name.
    - Note that `CGI::escape` should be used instead of `URI::escape` when passing data in a query paramter. 
3. From the main page, click one of the ticker names to toggle open its output.

## Warning

Press the "killall" button on the main page before closing the Rails server.

Closing the server does not stop the processes. 

## Deploying to heroku

This can be deployed to Heroku as-is, i.e. no need to set up
add-ons or anything.

run: `heroku create MyAppName` then edit `production.rb` and change `ROOT_URL` there. 

`git push heroku master`, `heroku run rake db:create db:migrate db:seed`, `heroku config:set username=MyUsername password=MyPassword`, then `heroku open`.

Note that for production, username and password using `heroku config:set` instead of `application.yml`. 

Make sure to precompile assets for production and commit before deploying. `env RAILS_ENV=production RAKE_ENV=production rake assets:precompile`

## About

- I was reading about Teletext for the first time and I kind of liked the aesthetic of the Teletext interface. I found the [telestrap](https://code.steadman.io/telestrap/) bootstrap theme which I think is super cool. I needed an excuse to make something with this and so started reading about Teletext on wikipedia for inspiration. My reading led me to telegraphs, "ticker tape parades", and how historical "stock tickers" have transformed into high-speed trading. 

- I decided to make a site which shows the live-updating output of commands being run on an interval, sort of akin to a stock ticker. 

- It'd been a while since I used Bootstrap so I started by making a little "cheat sheet" for basic usage of the Telestrap theme. You can see this at `/sample`.

- I generated a Rails app and moved the Telestrap assets in.

- Next I worked on views for the "Ticker" scaffold. I started with just "create" and "index" actions. For the "create" form, I used [ace.js](https://ace.c9.io/#nav=about) with Ruby syntax highlighting and a little jQuery to connect it with a textarea (see 'onchange' in application.js)

- Next I worked on asynchronously executing the "Ticker" scripts. I ended up making my own implementation using shell commands. See `app/models/ticker.rb` for the code, but I'll explain it here:

  - a Ticker record has a "content" column which contains a ruby script in a string. An "interval" column represents how often the script should be run (in milliseconds). It also has a "process_name" column which is programmatically set when the background job begins.

  - There are two instance methods on Ticker which control the background jobs:

    1. **`begin`**
      - creates a filename containing a constant identifier ("tickers_process_") and a random string
      - Writes the script content to a tempfile with this filename.
      - When writing the file, adds some wrapper code around
        the script content.
      - `loop do` and `sleep` are added in order to loop it every N milliseconds (which is determined by the interval column)
      - `$0 = "#{tempfile_name}"` is used to set the process name for the script. Setting this makes it easier to find the script's pid using `ps aux`.
      - Next the script is run by using system exec (backticks) to spin up a rails console and issuing it a `load` command to have it run the tempfile.
      - It turns out that the most difficult part of spawning subprocesses is doing in a way that enables stopping them. I experiemented with a number of commands, including `fork`, `spawn`, and `thread`. The returned value of these methods is a PID, but I found that the actual PID of the process dynamically changed and so this can't dependaby be used to stop the background job. A Ruby method calling these commands (i.e. `spawn`) will continue on to the next statement without waiting for the subprocess to compete, but if the method is run from a REPL, the prompt won't be returned to the user. I fixed this by plugging in the returned PID to `Process.detach(pid)`. I ended up going with `spawn` because it offers a `pgroup: true` option. This option tells it to start a new "process group" for the spawned command. I'm not sure how much it really does but it supposedly prevents orphaning child processes. 
      - Finally, the Ticker record's `process_name` column is updated to the tempfile name.
      - The background scripts' output is still visible though I tried to hide it with `> /dev/null`. Although this is probably a good thing, as background scripts would be very hard to debug without log output. 
  2. **`kill`**
    - Thankfully much simpler than `begin`
    - Basically, a running background job's PID is looked up by a ticker's `process_name`. 
    - The following command is used for this: `ps aux | grep #{process_name.first(25)} | awk 'NR==1{print $2}`
    - Then `kill -9 #{pid}` is used to do the actual killing.

  - There is also one class method on `Ticker`:
    1. **`killall`**
      - This command is to kill all background jobs (including orphans).
      - It's one line is `pkill -f #{@@process_name_constant}` This kills all processes with a name partially matching the argument. 
      - TODO: run this on Rails server exit to ensure that the jobs don't keep running. 

- After writing this background job system, I now needed a way for the background scripts to send updates to my websocket listeners. I tried using `WebsocketRails["channelName"].trigger` but found that it only worked when run from my Rails controller. So I made a Rails endpoint which calls this method, and called that endpoint from the background job using `curl`.

- At this point I was pretty satisfied. I added an "edit" form. The heroku deploy was working fine with the Telestrap theme but I hadn't debugged the background job system yet.

- Thanks for reading! Contribute if you want! 
