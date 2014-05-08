require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do
  def calculate_total(cards)
    arr = cards.map { |element| element[1] }
  
    total = 0
    arr.each do |value|
      if value == 'A'
        total += 11
      elsif value.to_i == 0 # J, Q, K
        total += 10
      else
        total += value.to_i
      end
    end
  
    #correct for aces
    arr.select{ |element| element == 'A' }.count.times do
      total -= 10 if total > 21
    end

    total
  end #calculate_total

  def card_image(card)
    suit = case card[0]
           when 'H' then 'hearts'
           when 'D' then 'diamonds'
           when 'S' then 'spades'
           when 'C' then 'clubs'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
              when 'J' then 'jack'
              when 'Q' then 'queen'
              when 'K' then 'king'
              when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end #card_image
end #helpers


before do
  @show_hit_stay_buttons = true
end


get '/' do
  erb :new_player
end

get '/new_player' do
  erb :new_player
end


post '/new_player' do
  session[:player_name] = params[:player_name]
  
  if session[:player_name].empty?
    @error = "You must enter a name."
    halt erb(:new_player)
  end

  redirect '/game'
end


get '/game' do
  session[:deck] = []
  session[:deck] = ['H', 'D', 'S', 'C'].product(['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'])
  session[:deck].shuffle!

  session[:player_cards] = []
  session[:dealer_cards] = []

  2.times do 
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
  end

  erb :game
end


post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == 21
    @success = "Congratulations #{session[:player_name]}, you've hit blackjack. You win!"
    @show_hit_stay_buttons = false
  elsif player_total > 21
    @error = "#{session[:player_name]} has busted. Better luck next time."
    @show_hit_stay_buttons = false
  end

  erb :game
end


post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_stay_buttons = false
  redirect '/game/dealer'
end


get '/game/dealer' do
  @show_hit_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == 21
    @error = "Sorry, dealer hit blackjack. You lose."
  elsif dealer_total > 21
    @success = "Congratulations, dealer busted. You win!"
  elsif dealer_total >= 17
    #dealer stays
    redirect '/game/compare'
  else
    #dealer hits
    @show_dealer_hit_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    @error = "Sorry, you lost."
  elsif player_total > dealer_total
    @success = "Congratulations, you win!"
  else
    @success = "It's a tie"
  end
  erb :game
end

