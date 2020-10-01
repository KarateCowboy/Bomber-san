# typed: strict
require './src/game_controller'
require './src/board'
require 'json'
require 'ap'

describe Board do

  describe '#initialize' do
    it 'returns a board of specified size' do
      b = Board.new 10, 10
      expect(b.max_tile.row).to eq(10)
      expect(b.max_tile.col).to eq(10)
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
      new_mine_list = Board.populate 5, b.max_tile, b.mines
      expect(new_mine_list.length).to eq(5)
      expect(new_mine_list.uniq.length).to eq(new_mine_list.length)
    end
  end

  describe '#reveal' do
    it 'adds a user reveal to the state' do
      b = Board.new(1, 1)
      safe_tile = Tile.new(0, 0)
      new_reveals = Board.reveal(safe_tile, b.max_tile, b.mines)
      expect(new_reveals).to include(Tile.new(0, 0))
    end
    it 'adds safe, adjacent tiles to the state' do
      b = Board.new(3, 3)
      let rows = []
      3.times{|r| rows.push([]); 3.times{|c| rows[r].push('x') }}
      safe_tile = Tile.new(0, 0)
      new_reveals = Board.reveal(safe_tile, b.max_tile, b.mines)
      pp new_reveals
      expect(new_reveals.length).to eq(9)
    end
  end

  describe '#line' do
    context 'vertical' do
      it 'returns the column of tiles as an array' do
        start = Tile.new(0, 3)
        new_line = Board.line(start, 10, Direction::Vertical)
        expect(new_line.length).to eq(10)
        expect(new_line.map { |t| t[:col] }.uniq.first).to eq(start[:col])
      end
      it 'returns the row of tiles as an array' do
        start = Tile.new(3, 0)
        new_line = Board.line(start, 10, Direction::Horizonal)
        expect(new_line.length).to eq(10)
        expect(new_line.map { |t| t[:row] }.uniq.first).to eq(start[:row])
      end
    end
  end

  describe 'square' do
    it 'returns a set of tiles making the outline of a square' do
      top_side = Board.line(Tile.new(0, 0), 10, Direction::Horizonal)
      bottom_side = Board.line(Tile.new(9, 0), 10, Direction::Horizonal)
      left_side = Board.line(Tile.new(0, 0), 10, Direction::Vertical)
      right_side = Board.line(Tile.new(0, 9), 10, Direction::Vertical)

      expected_square = (top_side + bottom_side + left_side + right_side).uniq
      generated_square = Board.square(Tile.new(0, 0), 10)
      expect(expected_square.map { |m| generated_square.include?(m) }.uniq.first).to eq(true)
    end
  end

  describe '#is_safe?' do
    it 'returns true if no adjacent tiles has a mine' do
      b = Board.new 10, 10
      safe_tile = Tile.new(2, 2)
      is_safe = Board.is_safe? safe_tile, b.max_tile, b.mines
      expect(is_safe).to eq(true)

      unsafe_tile = safe_tile
      b.mines.push(Tile.new(2, 3))

      should_be_unsafe = Board.is_safe? unsafe_tile, b.max_tile, b.mines
      expect(should_be_unsafe).to eq(false)
    end
  end

  describe '#adjacent_tiles' do
    it 'does not return tiles outside the board' do
      b = Board.new 10, 10
      tile = Tile.new(0, 0)
      tiles = Board.adjacent_tiles(tile, b.max_tile)
      expect(tiles.collect { |t| t.col }.any? { |x| x < 0 }).to eq(false)
      expect(tiles.collect { |t| t.row }.any? { |x| x < 0 }).to eq(false)
    end

    it 'returns all eight adjacent tiles' do
      b = Board.new 10, 10
      tile = Tile.new(3, 3)
      adjacent_tiles = Board.adjacent_tiles(tile, b.max_tile)
      above = Tile.new(2, 3)
      expect(adjacent_tiles).to include(above)
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
        new_game.sweep(Tile.new(0, 1))
        expect(new_game.status).to eq(GameState::Won)
      end
    end
  end
end
