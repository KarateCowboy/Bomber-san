# typed: strict
require './src/game_controller'
require './src/board'
require 'json'

describe Board do

  describe '#initialize' do
    it 'returns a board of specifiec size' do
      b = Board.new 10, 10
      expect(b.rows).to eq(10)
      expect(b.cols).to eq(10)
    end
    it 'has a list of mines' do
      b = Board.new 10, 10
      expect(b.mines.class).to eq(Array)
    end
    it 'has a list of flags' do
      b = Board.new 10, 10
      expect(b.flags.class).to eq(Array)
    end
  end
  describe '#populate' do
    it 'builds the given number of mines' do
      b = Board.new 10, 10
      new_mine_list = Board.populate 5, b.rows, b.cols, b.mines
      expect(new_mine_list.length).to eq(5)
      expect(new_mine_list.uniq.length).to eq(new_mine_list.length)
    end
  end
  describe '#reveal' do
    it 'adds a user reveal to the state' do
      b = Board.new(1, 1)
      new_reveals = Board.reveal Tile.new(0, 0), b.reveals
      expect(new_reveals).to include(Tile.new(0, 0))
    end
  end

  describe '#is_mine?' do
    it 'tells if a reveal is a mine or not' do
      b = Board.new(1, 3)
      mines = [Tile.new(1, 2)]
      answer = Board.mine_is_on_board?(Tile.new(1, 1), mines)
      expect(answer).to eq(false)
      expect(Board.mine_is_on_board?(Tile.new(1, 2), mines)).to eq(true)
    end
  end
end

describe GameController do

  context 'actions' do
    describe '#unique_id' do
      it 'creates a unique string id' do
        uniq_id = GameController.new_id 16
        expect(uniq_id).to match(/[A-Z]{16,16}/)
      end
    end
    describe '#new_game' do
      it 'creates a new board of the specified size' do
        new_game = GameController.new 10, 10, 1
        expect(new_game.board).to be_a(Board)
      end
      it 'has a unique id' do
        new_game = GameController.new 10, 10, 1
        expect(new_game.id).to match(/[A-Z]{16,16}/)
      end

      it 'sets the status to Open' do
        new_game = GameController.new 10, 10, 1
        expect(new_game.status).to eq(GameState::Open)
      end
      it 'creates a game file' do
        new_game = GameController.new 10, 10, 1
        begin
          game_file = File.read('./mine_game.json')
          game_data = JSON.parse(game_file)
          expect(game_data['id']).to eq(new_game.id)
        rescue
          throw "Expected a game file to exist"
        end
      end
    end

    describe '#sweep' do
      it 'sets a safe tile to cleared' do
        new_game = GameController.new 1, 1, 0
        new_game.sweep Tile.new(0, 0)
        expect(new_game.board.reveals.length).to eq(1)
        only_reveal = new_game.board.reveals.first
        expect(only_reveal.row).to eq(0)
        expect(only_reveal.col).to eq(0)
      end
      it 'sets the game status to lost if a bomb is hit' do
        new_game = GameController.new(1, 1, 1)
        new_game.sweep Tile.new(0, 0)
        expect(new_game.status).to eq(GameState::Lost)
      end

      it 'sets the game status to won if all tiles are cleared' do
        new_game = GameController.new(1, 2, 0)
        new_game.sweep Tile.new(0, 0)
        new_game.sweep(Tile.new(0,1))
        expect(new_game.status).to eq(GameState::Won)
      end
    end
  end
end