require 'sorbet-runtime'

class GameState < T::Enum
  enums do
    Open = new
    Lost = new
    Won = new
  end
end

class GameController
  extend T::Sig

  attr_reader :board, :id, :status
  sig { params(rows: Integer, cols: Integer, minecount: Integer).returns(GameController) }
  def initialize(rows, cols, minecount)
    @board = Board.new rows, cols
    @id = GameController.new_id 16
    @game_file = File.write('./mine_game.json', {:id => @id}.to_json)
    @minecount = minecount
    @board.mines = Board.populate(@minecount, Tile.new(rows, cols), [])
    @status = GameState::Open
    self
  end

  sig { params(length: Integer).returns(String) }
  def self.new_id(length)
    uniq_id = (0...length).map { (65 + rand(26)).chr }.join
  end

  sig { params(tile: Tile).returns(Board) }
  def sweep(tile)
    unless @board.reveals.include?(tile)
      if @board.mines.include? tile
        @status = GameState::Lost
        return @board
      else
        reveals = Board.reveal([tile], @board.max_tile, @board.mines, @board.reveals)
        @board.reveals = reveals
      end
      if @board.max_tile.row * @board.max_tile.col - @board.mines.length - @board.reveals.length == 0
        @status = GameState::Won
      end
    end
    return @board
  end

end