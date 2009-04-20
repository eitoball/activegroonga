# Copyright (C) 2009  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

class BaseTest < Test::Unit::TestCase
  include ActiveGroongaTestUtils

  def test_find
    bookmarks = Bookmark.find(:all)
    assert_equal(["http://groonga.org/", "http://cutter.sourceforge.net/"].sort,
                 bookmarks.collect(&:uri).sort)
  end

  def test_find_by_id
    groonga = Bookmark.find(@bookmark_records[:groonga].id)
    assert_equal("http://groonga.org/", groonga.uri)
  end

  def test_find_by_attribute
    daijiro = User.find_by_name("daijiro")
    assert_equal("daijiro", daijiro.name)
  end

  def test_create
    assert_predicate(Task.count, :zero?)
    send_mail = Task.new
    send_mail.name = "send mails"
    assert_nil(send_mail.id)
    assert_true(send_mail.save)
    assert_not_nil(send_mail.id)

    reloaded_send_mail = Task.find(send_mail.id)
    assert_equal("send mails", send_mail.name)
  end

  def test_update
    groonga_id = @bookmark_records[:groonga].id
    groonga = Bookmark.find(groonga_id)
    groonga.comment = "a search engine"
    assert_equal(groonga_id, groonga.id)
    groonga.save
    assert_not_nil(groonga_id, groonga.id)

    reloaded_groonga = Bookmark.find(groonga.id)
    assert_equal("a search engine", reloaded_groonga.comment)
  end

  def test_mass_assignments
    google = Bookmark.new
    google.attributes = {
      "uri" => "http://google.com/",
      "comment" => "a search engine"
    }
    assert_true(google.save)

    reloaded_google = Bookmark.find(google.id)
    assert_equal({
                   "uri" => "http://google.com/",
                   "comment" => "a search engine",
                   "content" => nil,
                   "user_id" => 0,
                 },
                 reloaded_google.attributes)
  end

  def test_mass_updates
    groonga = Bookmark.find_by_uri("http://groonga.org/")
    groonga.update_attributes({
                                "uri" => "http://google.com/",
                                "comment" => "a search engine",
                              })

    google = Bookmark.find(groonga.id)
    assert_equal({
                   "uri" => "http://google.com/",
                   "comment" => "a search engine",
                   "content" => groonga.content,
                   "user_id" => groonga.user_id,
                 },
                 google.attributes)
  end

  def test_destroy
    before_count = Bookmark.count
    Bookmark.find_by_uri("http://groonga.org/").destroy
    assert_equal(before_count - 1, Bookmark.count)
  end

  def test_inspect
    assert_equal("Bookmark(user_id: references, uri: string, " +
                 "content: text, comment: text)",
                 Bookmark.inspect)

    assert_equal("#<Bookmark user_id: 1, uri: \"http://groonga.org/\", " +
                 "content: \"<html><body>groonga</body></html>\", " +
                 "comment: \"fulltext search engine\">",
                 Bookmark.find_by_uri("http://groonga.org/").inspect)
  end

  def test_update_inverted_index
    google = Bookmark.new
    google.attributes = {
      "uri" => "http://google.com/",
      "comment" => "a search engine",
      "content" => "<html><body>...Google...</body></html>",
    }
    google.save!

    bookmarks = Bookmark.find_all_by_content("Google")
    assert_equal([google], bookmarks)

    google.content = "<html><body>...Empty...</body></html>"
    google.save!

    bookmarks = Bookmark.find_all_by_content("Google")
    assert_equal([], bookmarks)

    bookmarks = Bookmark.find_all_by_content("Empty")
    assert_equal([google], bookmarks)
  end

  def test_update_index
    user = @user_records[:daijiro]
    google = Bookmark.new
    google.attributes = {
      "uri" => "http://google.com/",
      "user_id" => user.id,
    }
    google.save!

    bookmarks = Bookmark.find_all_by_user_id([user.id].pack("i"))
    assert_equal([google], bookmarks)
  end

  def test_create
    google = Bookmark.create("uri" => "http://google.com/",
                             "comment" => "a search engine",
                             "content" => "<html><body>...Google...</body></html>")

    assert_equal([google], Bookmark.find_all_by_content("Google"))
  end
end
