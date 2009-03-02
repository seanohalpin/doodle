#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'

get '/' do
  redirect '/index.html'
end
