require 'test/unit'
require 'rubygems'
require 'active_record'
require "#{File.dirname(__FILE__)}/../init"

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :dbfile => ':memory:')

begin # setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :businessmen do |t|
      t.string :type
      t.timestamp :woke_at, :brushed_teeth_at, :showered_at, :ate_at, :slept_at 
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Businessman < ActiveRecord::Base; end
class ThoroughBusinessman < Businessman
  time_parseable
end
class CleanButHungryBusinessman < Businessman
  time_parseable :brushed_teeth_at, :showered_at, :format => {
    :date => "%m/%d/%Y", :time => "%I:%M%p"
  }
end
class WellFedSmellyBusinessman < Businessman
  time_parseable :ate_at
  validates_presence_of :ate_at
end

class TimeParseableTest < Test::Unit::TestCase
  def setup
    @busy_man  = ThoroughBusinessman.new
    @clean_man = CleanButHungryBusinessman.new
    @dirty_man = WellFedSmellyBusinessman.new
  end

  def teardown
    teardown_db
  end

  def test_string_attr_reader
    assert_nil @busy_man.woke_at_string
    assert_nil @clean_man.brushed_teeth_at_string
    assert !@dirty_man.respond_to?(:showered_at_string)
  end

  def test_string_attr_writer
    assert @busy_man.respond_to?(:slept_at_string=)
  end

  def test_date_and_time_attr_readers
    assert_nil @busy_man.woke_time_string
    assert_nil @busy_man.woke_date_string
    now = Time.now
    @busy_man.woke_at = now
    assert_equal @busy_man.woke_time_string, now.strftime("%I:%M %p")
    assert_equal @busy_man.woke_date_string, now.strftime("%b %d, %Y")
  end

  def test_date_and_time_attr_writers
    @busy_man.woke_time_string = "4:45 AM"
    @busy_man.woke_date_string = "April 30, 2008"
    assert_equal @busy_man.woke_at, Time.parse(@busy_man.woke_at_string)
  end

  def test_parsing
    @busy_man.woke_at_string = '5:30 AM on April 30, 2008'
    assert ((5.seconds.ago..5.seconds.from_now) === @busy_man.woke_at) == false
    assert_equal @busy_man.woke_at, Time.parse('5:30 AM on April 30, 2008')
  end

  def test_invalid_parsing_error
    @clean_man.showered_at_string = 'Every morning'
    assert @clean_man.errors.on(:showered_at_string)
  end

  def test_error_chaining
    assert !@dirty_man.valid?    
    assert @dirty_man.errors.on(:ate_at)
    assert @dirty_man.errors.on(:ate_at_string)
    assert @dirty_man.errors.on(:ate_date_string)
  end

  def test_alternate_formatting
    now = Time.now
    @clean_man.showered_at = now
    assert_equal @clean_man.showered_at_string, now.strftime("%I:%M%p on %m/%d/%Y")
    assert_equal @clean_man.showered_date_string, now.strftime("%m/%d/%Y")
    assert_equal @clean_man.showered_time_string, now.strftime("%I:%M%p")
  end
end
