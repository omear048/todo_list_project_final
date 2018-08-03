source "https://rubygems.org"

gem "sinatra", "~>1.4.7"
gem "sinatra-contrib"
gem "erubis"

gem "pg"   #added to enable us to interact with the database 


ruby "2.4.1p111" #Specify the Ruby version in Gemfile so that Heruku knows the exact version of Ruby to use when serving the project


group :production do #Configure your application to use a production web server. Ruby's standard library comes with a default web server called WEBrick but by default WEBrick is single threaded and can not handle multiple requests at the same time. That is why we reccomend using the Puma web server. 
  gem "puma"
end
