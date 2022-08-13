class GamesController < ApplicationController
  def index
    @games = Game.all.order(completed_at: :desc)
  end

  def show
    @game = Game.find(params[:id])
  end
end
