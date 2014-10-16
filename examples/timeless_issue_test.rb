require 'mongoid'
require 'mongoid/support/query_counter'
require 'minitest/autorun'
# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

Mongoid.configure.connect_to("mongoid_test")

class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
end


class BugTest < Minitest::Test
  def test_timeless_leak
    p = Post.create(title: 'Some post')
    q = Post.create(title: 'Some other post')

    p.title = 'Some New Title'
    p.save

    q.title = "Some other new title"
    q.save

    finishing_line = Time.now

    p.title = "Another New Title"
    p.timeless.save

    q.title = "Some other newer title"
    q.save

    # update to P was performed with timeless, so it should still have an
    # updated_at earlier than the finishing_line
    assert_equal true, p.updated_at < finishing_line

    # update to Q was not performed with timeless, so it should have an
    # changed updated_at reflecting that it was changed AFTER the finishing_line
    assert_equal true, q.updated_at > finishing_line

    # My other concern about this is that timeless can cause a record to be
    # saved while not recording any created_at. Surely part of the timestamps
    # 'contract' is to expect never to have a saved record without a created_at
    # timestamp. Why on earth would you want to use timeless on a create?
    # bearing in mind, if you create a document with a manually defined
    # created_at value, it will take prescedence over the timestamp to be
    # assigned by timestamps module.
  end
end
