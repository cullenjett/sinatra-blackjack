require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

get '/' do
  erb :set_name
end

post '/set_name' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  session[:deck] = []
  session[:deck] = ['2', '3', '4', '5', '6', '7', '8', '9', '10'].product(['A', 'K', 'Q', 'J'])

  session[:player_cards] = []
  2.times do 
    session[:player_cards] << session[:deck].pop
  end
  erb :game
end

get '/nested_template' do
  erb :"test_folder/nested_template"
end