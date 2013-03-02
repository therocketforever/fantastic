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

class Item
  include DataMapper::Resource
  
  property :id, Serial
end



class User
  include DataMapper::Resource
  property :id, Serial

  has 1, :inventory
end

class Inventory
  include DataMapper::Resource
  property :id, Serial

  belongs_to :user
end

DataMapper.finalize.auto_migrate!
