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

module Offensible
  def damage(target)
    puts "I apply damage to my target!"
  end
  def critical(target)
    puts "I cause a critical modifyer to be applied!"
  end
end

module Defensible
  def resist(target)
    puts "I reduce damage appied by Offensible#damage & Offensible#critical."
  end
  def absorb(target)
    puts "I absorb damage applied by Offensible#damage & Offensible#critical."
  end
end

module Empowered
  def channel(target)
    puts "I do something related to the function of being a magical item"
  end
end

class Item
  include DataMapper::Resource
  include Equipable
  
  property :id, Serial
  property :name, String
  property :durability, Decimal, :default => 100.00
  property :material, Enum[:wood, :leather, :iron, :steel, :silver, :gold, :glass, :crystal], :default => :wood
  property :quality, Enum[:common, :uncomon, :rare, :legendary, :unique, :artifact], :default => :common
  
  has n, :inventories, :through => Resource
end

class Artifact < Item
end

class EnchantedItem < Item
  extend Empowered
end

class Potion < EnchantedItem
  property :magnitude, Integer, :default => 1.d4.roll
  def apply_effect(target)
    self.effect
  end
  
  def effect
    puts "I do something... but you should overide me in the spocific item class"
  end
end

class HealPotion < Potion
  def effect
     puts "Add positive value to self.current_hit_points"
  end
end

class ManaPotion < Potion
  def effect
    puts "Add positive value to self.current_mana"
  end
end

class Poison < Potion
  def effect
    puts "Add negitive value to self.current_hit_points"
  end
end

class Weapon < Item
  include Offensible
  
  property :damage_type, Flag[:cutting, :bashing, :elemental, :magical]
  property :modification, Flag[:none, :poisoned, :elemental, :cursed, :enchanted, :broken], :default => :none
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
  include Defensible
  
  property :modification, Flag[:none, :dense, :rusty, :fine, :broken]
end

class User
  include DataMapper::Resource
  
  property :id, Serial
  property :archtype, Discriminator
  property :name, String
  property :max_hit_points, Integer, :default => 10
  property :current_hit_points, Integer, :default => 10
  property :dexterity, Integer
  property :strength, Integer
  property :intelegence, Integer
  property :wisdom, Integer
  
  before :save do
    self.current_hit_points = self.max_hit_points unless self.current_hit_points
  end

  has n, :inventories
  has n, :items, :through => :inventories
  has n, :abilities, :through => Resource

  def inventory
    self.inventories
  end

  def equip(target, slot)
    puts "#{target.name} equiped in #{slot}."
  end

  def attack(target)
    puts "Attack!!"
  end

  def defend(target)
    puts "Defend!!" 
  end
end

class Warrior < User
  has n, :codes, :through => Resource
  
  def philosophy
    self.codes
  end
end

class Mage < User
  property :max_mana, Integer, :default => 10
  property :current_mana, Integer, :default => 10

  before :save do
    self.current_mana = self.max_mana unless self.max_mana
  end

  has n, :spells, :through => Resource 

  def spellbook
    self.spells
  end
end

class Thief < User
  has n, :martial_arts, :through => Resource

  def style
    self.martial_arts
  end
end

class Inventory
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  has n, :items, :through => Resource
end

class Ability
  include DataMapper::Resource
  property :id, Serial
  property :ability_archtype, Discriminator

  has n, :users, :through => Resource
end

class MartialArt < Ability
  has n, :thiefs, :through => Resource
end

class Spell < Ability
  has n, :mages, :through => Resource
end

class Code < Ability
  has n, :warriors, :through => Resource
end

DataMapper.finalize.auto_migrate!

Binding.pry
