
class Employee < ActiveRecord::Base
  include Dynamo::Attribute
  include Dynamo::Serialization::Marshal
  #dynamo :first_name, String
  #dynamo :last_name, String
end

class Developer < Employee
  #dynamo :skill, String
end

class WebDeveloper < Developer

end

class Version < ActiveRecord::Base
  include Dynamo::Attribute
  include Dynamo::Serialization::Marshal
end

begin
  class DynamoMigration < ActiveRecord::Migration
    def self.down
      drop_table "employees"
      drop_table "versions"
    end
    def self.up
      create_table "employees" do |t|
        t.text   "dynamo"
      end

      create_table "versions" do |t|
        t.string  "dynamo"
        t.string  "title"
        t.string  "comment"
        t.timestamps
      end
    end
  end

  ActiveRecord::Base.establish_connection(:adapter=>'mysql', :database=>'dynamo_test')
  ActiveRecord::Migration.verbose = false
  DynamoMigration.migrate(:down)
  DynamoMigration.migrate(:up)
  ActiveRecord::Migration.verbose = true
end