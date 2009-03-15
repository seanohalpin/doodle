#!/usr/bin/env ruby

require 'sinatra'

get '/' do
  redirect '/index.html'
end
