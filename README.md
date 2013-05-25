# Mephisto

A dead-simple blog engine based on [Rails][1] originally developed by [Rick Olson][2] and [Justin Palmer][3] with contributions from a bunch of wicked cool people. Later on maintained for some time by [Eric Kidd][4].
Forked & revived by [Sebastian Gräßl][5]

## Installation

1. Clone the repository
   <pre><code>git clone git@github.com:bastilian/mephisto.git</code></pre>

2. Initialize and update git-submodules, run Bundler in your working copy
   <pre><code>cd mephisto && git submodule init && git submodule update && bundle</pre></code>

3. Copy the database configuration and adjust it to your liking
   <pre><code>cp config/database.example.yml config/database.yml</pre></code>

4. Generate the session key & secret
   <pre><code>bundle exec rake config/initializers/session_store.rb</pre></code>

5. Bootstrap the database
   <pre><code>bundle exec rake db:bootstrap</pre></code>

6. Start the server and go to [http://localhost:3000/admin][6], login with **admin / testpassword** and enjoy!
   <pre><code>bundle exec script/server</pre></code>


### Upgrade Note:

This fork may not be compatible with older/other forks. If you want to upgrade to this fork, be carefull. If you encounter issues do not hesitate to [report them][7]

## License

Copyright (c) 2005-2008 Rick Olson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[1]: http://rubyonrails.org "Ruby on Rails"
[2]: https://github.com/technoweenie "Rick Olson on Github"
[3]: https://github.com/Caged "Justin Palmer on Github"
[4]: https://github.com/emk "Eric Kidd on Github"
[5]: https://github.com/bastilian "Sebastian Gräßl on Github"
[6]: http://localhost:3000 "Local Mephisto"
[7]: https://github.com/bastilian/mephisto/issues "Mephisto issues on Github"