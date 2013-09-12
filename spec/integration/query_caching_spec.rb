require 'spec_helper'

describe 'query caching' do
  let(:db_names) { [db1, db2] }

  before do
    Apartment.configure do |config|
      config.excluded_models = ["Company"]
      config.database_names = lambda{ Company.pluck(:database) }
      config.use_schemas = true
    end

    Apartment::Database.reload!(config)

    db_names.each do |db_name|
      Apartment::Database.create(db_name)
      Company.create database: db_name
    end
  end

  after do
    db_names.each{ |db| Apartment::Database.drop(db) }
    Apartment::Database.reset
    Company.delete_all
  end

  it 'clears the ActiveRecord::QueryCache after switching databases' do
    db_names.each do |db_name|
      Apartment::Database.switch db_name
      User.create! name: db_name
    end

    ActiveRecord::Base.connection.enable_query_cache!

    Apartment::Database.switch db_names.first
    User.find_by_name(db_names.first).name.should == db_names.first

    Apartment::Database.switch db_names.last
    User.find_by_name(db_names.first).should be_nil
  end
end