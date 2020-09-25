# typed: strict

require 'sorbet-runtime'


Tile = Struct.new(:row, :col)

class Board
  extend T::Sig
  attr_reader :rows, :cols, :mines, :flags, :reveals
  attr_writer :mines, :reveals

  sig { params(rows: Integer, cols: Integer).returns(Board)}
  def initialize(rows, cols)
    @rows = rows
    @cols = cols
    @mines = []
    @reveals = Set.new
    @flags = []
    self
  end

  sig { params(num_of_mines: Integer, max_rows: Integer, max_cols: Integer, mines: Array).returns(Array)}
  def self.populate(num_of_mines,max_rows, max_cols, mines)
    new_unique_mine = lambda do |mine_list|
      row = rand(max_rows)
      col = rand(max_cols)
      new_mine = Tile.new(row, col)
      if !self.mine_is_on_board? new_mine, mine_list
        return new_mine
      end
      return new_unique_mine.call(mine_list)
    end
    num_of_mines.times.each{ mines.push(new_unique_mine.call(mines))}
    return mines
  end

  sig { params(reveal: Tile, reveals: Set ).returns(Set) }
  def self.reveal(reveal, reveals)
    reveals.add(reveal)
  end

  sig { params(tile: Tile, mines: Array).returns(T::Boolean)}
  def self.mine_is_on_board?(tile, mines)
    return mines.any?{|m| m.row == tile.row && m.col == tile.col }
  end

end

