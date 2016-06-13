class DecksController < ApplicationController
  def create
    if current_user.decks.length >= current_user.deck_limit
      flash[:error] = "Deck limit reached! To raise this limit, please purchase a Premium account."
      redirect_to premium_path
    else
      new_deck = Deck.create(:name => params[:deck][:name], :user => current_user)
      if new_deck
        redirect_to edit_deck_path(new_deck)
      else
        flash[:error] = "FUCK"
        redirect_to new_deck_path
      end
    end
  end

  def generate_black_file
    validate_logged_in
    redirect_to root_path unless current_user.admin

    deck = Deck.find(params[:id])
    file = ""

    deck.black_cards.each do |card|
      file += "[[#{card[:pick]}]]#{card[:text]}\n"
    end

    render text: file
  end

  def generate_white_file
    validate_logged_in
    redirect_to root_path unless current_user.admin

    deck = Deck.find(params[:id])
    file = ""

    deck.black_cards.each do |card|
      file += "#{card}\n"
    end

    render text: file
  end

  def new
    validate_logged_in
    if current_user.decks.length >= current_user.deck_limit
      flash[:error] = "Deck limit reached! To raise this limit, please purchase a Premium account."
      redirect_to premium_path
    else
      @title = "New Deck"
    end
  end

  def show
    @deck = Deck.find(params[:id])
    @title = @deck.name

    @open_graph.push({
      :prop => "title",
      :value => "CAH Creator Deck: #{@deck.name}"
    })

    @open_graph.push({
      :prop => "description",
      :value => "Come look at #{@deck.user.name}'s deck on CAH Creator with #{@deck.black_cards.count} black cards and #{@deck.white_cards.count} white cards"
    })
  end

  def import
    validate_logged_in
    if current_user.decks.length >= current_user.deck_limit
      flash[:error] = "Deck limit reached! To raise this limit, please purchase a Premium account."
      redirect_to premium_path
    else
      @title = "Import Deck"
    end
  end

  def select
    validate_logged_in
    @title = "Select Deck"
    @user = current_user
  end

  def import_deck
    validate_logged_in
    if current_user.decks.length >= current_user.deck_limit
      flash[:error] = "Deck limit reached! To raise this limit, please purchase a Premium account."
      redirect_to premium_path
    else
      imported_deck = JSON.parse(params[:imported_deck][:json], :symbolize_names => true)

      if imported_deck[:blackCards].length >= 50 && !current_user.premium
        imported_deck[:blackCards] = imported_deck[:blackCards][0..49]
        flash[:message] = "Since you don't have premium, your deck has been limited to 50 black cards and 100 white cards."
      end

      if imported_deck[:whiteCards].length >= 100 && !current_user.premium
        imported_deck[:whiteCards] = imported_deck[:whiteCards][0..99]
        flash[:message] = "Since you don't have premium, your deck has been limited to 50 black cards and 100 white cards."
      end

      black_cards = Deck.validate_black_cards(imported_deck[:blackCards])
      white_cards = Deck.validate_white_cards(imported_deck[:whiteCards])
      deck = Deck.create(:name => imported_deck[:name], :black_cards => black_cards, :white_cards => white_cards, :user => current_user)
      redirect_to edit_deck_path(deck)
    end
  end

  def edit
    @deck = Deck.find(params[:id])
    @title = "Editing #{@deck.name}"
    unless @deck && current_user == @deck.user || current_user.admin
      redirect_to root_path
    end
  end
end
