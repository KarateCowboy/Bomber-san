# typed: strict

require 'sorbet-runtime'


Tile = Struct.new(:row, :col)

class Direction < T::Enum
  enums do
    Horizonal = new('row')
    Vertical = new('col')
  end
end

class Board
  extend T::Sig
  attr_reader :max_tile, :mines, :flags, :reveals
  attr_writer :mines, :reveals

  sig { params(rows: Integer, cols: Integer).returns(Board) }
  def initialize(rows, cols)
    @max_tile = Tile.new(rows, cols)
    @mines = []
    @reveals = Set.new
    @flags = []
    self
  end

  sig { params(num_of_mines: Integer, max_tile: Tile, mines: Array).returns(Array) }
  def self.populate(num_of_mines, max_tile, mines)
    new_unique_mine = lambda do |mine_list|
      row = rand(max_tile.row)
      col = rand(max_tile.col)
      new_mine = Tile.new(row, col)
      unless self.mine_is_on_board? new_mine, mine_list
        return new_mine
      end
      return new_unique_mine.call(mine_list)
    end
    num_of_mines.times.each { mines.push(new_unique_mine.call(mines)) }
    return mines
  end

  sig { params(to_reveal: Tile, max_tile: Tile, mines: Array).returns(Set) }
  def self.reveal(to_reveal, max_tile, mines)
    sig{ params(prior: Set, distance: Integer).returns(Set)}
    puts "max tile is #{max_tile[:row]}, #{max_tile[:col]}"
    get_contig = lambda do |prior, distance|
      return Set.new if prior.length == 0
      if to_reveal[:row] + distance > max_tile[:row] && to_reveal[:col] + distance > max_tile[:col]
        return Set.new
      end
      top_left = Tile.new(to_reveal[:row] + distance, to_reveal[:col] - distance)
      square = Board.square(top_left, (2 * distance) + 1)
      safe_and_contiguous = square.reject{|t| mines.include?(t) || t[:row] < 0 || t[:col] < 0 } # || (Board.adjacent_tiles(t,max_tile) & prior).empty? }
      return safe_and_contiguous.to_set + get_contig.call(safe_and_contiguous, distance + 1)
    end

    reveals = get_contig.call([to_reveal], 1)
    return reveals.to_set.add(to_reveal)
  end

  sig { params(top_left: Tile, size: Integer).returns(Set) }
  def self.square(top_left, size)
    top_side = Board.line(top_left, size, Direction::Horizonal)
    bottom_left = Tile.new(top_left['row'] + size - 1, top_left['col'])
    bottom_side = Board.line(bottom_left, size, Direction::Horizonal)
    left_side = Board.line(top_left, size, Direction::Vertical)
    right_side = Board.line(top_side.last, size, Direction::Vertical)
    (top_side + bottom_side + left_side + right_side).to_set
  end

  sig { params(start: Tile, length: Integer, direction: Direction).returns(Array) }
  def self.line(start, length, direction)
    return [start] if length == 1
    return [] if length == 0

    inc = case direction
          when Direction::Vertical then
            :row
          else
            :col
          end
    line = []
    for i in (start[inc]..(start[inc] + length - 1))
      t = start.clone
      t[inc] = i
      line.push(t)
    end
    return line
  end

  sig { params(tile: Tile, mines: Array).returns(T::Boolean) }
  def self.mine_is_on_board?(tile, mines)
    return mines.any? { |m| m.row == tile.row && m.col == tile.col }
  end

  sig { params(tile: Tile, max_tile: Tile).returns(Array) }
  def self.adjacent_tiles(tile, max_tile)
    return [
        Tile.new(tile.row - 1, tile.col - 1), # up left
        Tile.new(tile.row - 1, tile.col), # above
        Tile.new(tile.row - 1, tile.col + 1), #up right
        Tile.new(tile.row, tile.col + 1), # right
        Tile.new(tile.row + 1, tile.col + 1), # down right
        Tile.new(tile.row + 1, tile.col), # below
        Tile.new(tile.row + 1, tile.col - 1), # down left
        Tile.new(tile.row, tile.col - 1) # left
    ].reject { |t| t.row < 0 || t.col < 0 || t.row >= max_tile.row || t.col >= max_tile.col }
  end

  sig { params(tile: Tile, max_tile: Tile, mines: Array).returns(T::Boolean) }
  def self.is_safe?(tile, max_tile, mines)
    return (mines & Board.adjacent_tiles(tile, max_tile)).empty?
  end
end

