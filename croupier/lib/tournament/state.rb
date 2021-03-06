class Croupier::Tournament::State
  attr_reader :players
  attr_reader :spectators
  attr_reader :small_blind
  attr_reader :big_blind

  def community_cards=(cards)
    @game_state.community_cards = cards
  end


  def initialize
    @game_state = Croupier::Game::State.new(self)

    @players = []
    @spectators = []
    @small_blind = 10
    @big_blind = 20
    @current_player = 0
    @dealers_position = 0
    reset_last_aggressor
  end

  def reset_last_aggressor
    @last_aggressor = nil
  end

  def current_buy_in
    players.inject(0) { |max_buy_in, player| max_buy_in = [max_buy_in, player.total_bet].max }
  end

  def pot
    players.inject(0) { |sum, player| sum + player.total_bet }
  end

  def register_player(player)
    @players << player
  end

  def register_spectator(spectator)
    @spectators << spectator
  end

  def deck
    @deck ||= Croupier::Deck.new
  end

  def each_observer
    (@players + @spectators).each do |observer|
      yield observer
    end
  end

  def each_spectator
    @spectators.each do |observer|
      yield observer
    end
  end

  def each_player
    @players.each do |observer|
      yield observer
    end
  end

  def each_player_from(from_player)
    @players.rotate(@players.index(from_player)).each do |observer|
      yield observer
    end
  end

  def transfer_bet(player, amount, bet_type)
    original_buy_in = current_buy_in
    player.total_bet += amount
    @last_aggressor = player if current_buy_in > original_buy_in

    transfer player, amount
    each_observer do |observer|
      observer.bet player, amount: amount, type: bet_type, pot: pot
    end
  end

  def last_aggressor
    return first_player if @last_aggressor.nil?

    @last_aggressor
  end

  def transfer(player, amount)
    player.stack -= amount
  end

  def dealer
    @players[@dealers_position]
  end

  def first_player
    @players[nthPlayer 1]
  end

  def second_player
    @players[nthPlayer 2]
  end

  def number_of_players_in_game
    @players.count { |player| player.has_stack? }
  end

  def next_round!
    @game_state = Croupier::Game::State.new(self)

    @players.each do |player|
      player.initialize_round
    end

    move_deal_button_to_next_player

    if orbit_completed
      double_the_blinds
    end
  end

  private

  def orbit_completed
    @dealers_position == 0
  end

  def double_the_blinds
    @small_blind *= 2
    @big_blind *= 2
  end

  def move_deal_button_to_next_player
    @dealers_position = nthPlayer 1
  end

  def nthPlayer(n)
    (@dealers_position + n) % players.count
  end
end
