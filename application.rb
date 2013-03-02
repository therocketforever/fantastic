class Application < Sinatra::Base
  
  enable :logging, :inline_templates

  configure :test do
    DataMapper.setup(:default, "sqlite://#{Dir.pwd}/features/support/test.db")
  end
 
  configure :development do
    Bundler.require(:development)
    DataMapper.setup(:default, "sqlite://#{Dir.pwd}/development.db")
  end

  configure :production do
    DataMapper.setup(:default, ENV['DATABASE_URL']) 
  end
  
  get '/' do
    "Hello World!"
  end
end

class Integer
  [4,6,8,10,12,20].each do |sides|
    define_method("d#{sides}") { Dice.new(self, sides) }
  end
end

class Dice
  attr_reader :sides, :count, :increment, :multiplier

  def initialize(count, sides, increment=0, multiplier=1)
    @sides, @count = sides, count
    @increment, @multiplier = increment, multiplier
  end

  def *(n)
    Dice.new(count, sides, increment, multiplier * n)
  end

  def +(n)
    Dice.new(count, sides, increment+n, multiplier)
  end

  def -(n)
    self.+(-n)
  end

  def roll(collect=false)
    result = collect ? [] : 0

    count.times do
      roll = (rand(sides) + 1) * multiplier
      result = result.send(collect ? :push : :+, roll)
    end

    if increment != 0
      result = result.send(collect ? :push : :+, increment * multiplier)
    end

    result
  end

  def best(n, collect=false)
    list = to_a.sort.last(n)
    collect ? list : list.inject(0) { |s,v| s + v }
  end

  def max
    (count * sides + increment) * multiplier
  end

  def min
    (count + increment) * multiplier
  end

  def average
    (max + min) / 2.0
  end

  def to_a
    roll(true)
  end

  def to_s
    s = "#{count}d#{sides}"
    s << "%+d" % increment if increment != 0
    s << "*%d" % multiplier if multiplier != 1
    s
  end

  alias to_i roll
  alias inspect to_s
end


module Equipable
  def equip
    puts "Item Equiped!"
  end
end

class Item
  include DataMapper::Resource
  include Equipable
  property :id, Serial
  has n, :inventories, :through => Resource
end

class EnchantedItem < Item
end

class Potion < EnchantedItem
end

class Weapon < Item
end

class Cutting < Weapon
end

class Bashing < Weapon
end

class Sword < Cutting
end

class Dagger < Cutting
end

class Mace < Bashing
end

class Armor < Item
end

class User
  include DataMapper::Resource
  property :id, Serial
  has n, :inventories
  has n, :items, :through => :inventories
end

class Inventory
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  has n, :items, :through => Resource
end

DataMapper.finalize.auto_migrate!

Binding.pry
