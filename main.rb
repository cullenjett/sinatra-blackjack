require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK_AMT = 21
DEALER_HIT_MIN = 17
INITIAL_POT_AMT = 100



# ***********
# * HELPERS *
# ***********


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
      total -= 10 if total > BLACKJACK_AMT
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


  def winner!(msg)
    @show_hit_stay_buttons = false
    @winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
    session[:player_pot] = session[:player_pot] + session[:player_bet]
    @play_again = true
  end


  def loser!(msg)
    @show_hit_stay_buttons = false
    @loser = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    @play_again = true
  end


  def tie!(msg)
    @show_hit_stay_buttons = false
    @winner = "<strong>It's a tie.</strong> #{msg}"
    @play_again = true
  end
end #helpers



# ***********
# * ACTIONS *
# ***********


before do
  @show_hit_stay_buttons = true
  @play_again = false
end


get '/' do
  erb :new_player
end


get '/new_player' do
  erb :new_player
end


post '/new_player' do
  session[:player_name] = params[:player_name]
  session[:player_pot] = INITIAL_POT_AMT
  
  if session[:player_name].empty?
    @error = "You must enter a name."
    halt erb(:new_player)
  end

  redirect '/bet'
end


get '/bet' do
  session[:player_bet] = nil
  erb :bet
end


post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "You have to bet something..."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Bet amount cannot be more than what you have ($#{session[:player_pot]})"
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end


get '/game' do
  session[:turn] = session[:player_name]

  session[:deck] = []
  session[:deck] = ['H', 'D', 'S', 'C'].product(['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'])
  session[:deck].shuffle!

  session[:player_cards] = []
  session[:dealer_cards] = []

  2.times do 
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
  end

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMT
    winner!("That's a blackjack!")
  end

  erb :game
end


post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMT
    winner!("That's a blackjack!")
  elsif player_total > BLACKJACK_AMT
    loser!("Bust with #{player_total}. Too many hits, fool!")
  end

  erb :game, layout: false
end


post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_stay_buttons = false
  redirect '/game/dealer'
end


get '/game/dealer' do
  session[:turn] = 'dealer'
  @show_hit_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMT
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMT
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_HIT_MIN
    #dealer stays
    redirect '/game/compare'
  else
    #dealer hits
    @show_dealer_hit_button = true
  end

  erb :game, layout: false
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
    loser!("#{session[:player_name]} has #{player_total} and Dealer has #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} has #{player_total} and Dealer has #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and the dealer have #{player_total}")
  end

  erb :game, layout: false
end


get '/game_over' do
  erb :game_over
end







