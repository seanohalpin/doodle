# hello_world.rb
require 'rubygems'
require 'sinatra'

get '/' do
  redirect '/index.html'
end
