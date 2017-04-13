require 'pry'

class Dog

  @@all = []

  attr_accessor :name, :breed, :id

  def initialize(name:, breed:, id:nil)
    @name = name
    @breed = breed
    @id = id
    @@all << self
  end

  def self.all
    @@all
  end

  def self.create_table
    sql = <<-SQL
    CREATE TABLE dogs (
      id INTEGER PRIMARY KEY,
      name TEXT,
      breed TEXT);
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    DB[:conn].execute("DROP TABLE dogs;")
  end

  def save
    if self.id
      self.update
    else
      sql_insert = <<-SQL
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
      SQL
      DB[:conn].execute(sql_insert, self.name, self.breed)

      sql_get_id = <<-SQL
        SELECT last_insert_rowid()
        FROM dogs;
      SQL
      @id = DB[:conn].execute(sql_get_id)[0][0]
    end
    self
  end

  def update
    sql_update = <<-SQL
      UPDATE dogs
      SET name = ?, breed = ?
      WHERE id = ?
    SQL
    DB[:conn].execute(sql_update, self.name, self.breed, self.id)
  end

  def self.create(attributes)
    dog = Dog.new(attributes)
    dog.save
  end

  def self.find_by_id(id)
    sql_find_by_id = <<-SQL
      SELECT *
      FROM dogs
      WHERE id = ?;
    SQL
    ret_array = DB[:conn].execute(sql_find_by_id, id).flatten
    Dog.new(name:ret_array[1], breed:ret_array[2], id:ret_array[0])
  end

  def self.find_or_create_by(attr)
    self.all.each do |dog|
      name = attr[:name]
      breed = attr[:breed]
      id = attr[:id]

      if dog.name == name && dog.breed == breed
        return dog
      end
    end
    new_dog = self.new(attr)
    new_dog.save
  end

  def self.new_from_db(row)
    dog = self.new(name: row[1], breed: row[2], id: row[0])
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE name = ?
      LIMIT 1;
    SQL
    db_dog = DB[:conn].execute(sql, name).first
    new_dog = self.new_from_db(db_dog)
  end

end
