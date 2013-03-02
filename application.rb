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

class HealPotion < Potion
end

class ManaPotion < Potion
end

class Poison < Potion
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
