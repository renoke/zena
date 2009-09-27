require 'test_helper'
class DbTest < Zena::Unit::TestCase

  def test_zip_fixtures
    assert_equal zips_zip(:zena), Zena::Db.fetch_row("select zip from zips where site_id = #{sites_id(:zena)}").to_i
  end

  def test_fetch_ids
    ids  = [:zena, :people, :ant].map{|r| nodes_id(r)}
    zips = [:zena, :people, :ant].map{|r| nodes_zip(r)}
    assert_list_equal ids, Zena::Db.fetch_ids("SELECT id FROM nodes WHERE id IN (#{ids.join(',')})")
    assert_list_equal ids, Zena::Db.fetch_ids("SELECT id FROM nodes WHERE id IN (#{ids.join(',')})")
    assert_list_equal zips, Zena::Db.fetch_ids("SELECT zip FROM nodes WHERE id IN (#{ids.join(',')})", 'zip')
  end

  def test_next_zip
    assert_raise(Zena::BadConfiguration) { Zena::Db.next_zip(88) }
    assert_equal zips_zip(:zena ) + 1, Zena::Db.next_zip(sites_id(:zena))
    assert_equal zips_zip(:ocean) + 1, Zena::Db.next_zip(sites_id(:ocean))
    assert_equal zips_zip(:zena ) + 2, Zena::Db.next_zip(sites_id(:zena))
  end

  def test_next_zip_rollback
    assert_raise(Zena::BadConfiguration) { Zena::Db.next_zip(88) }
    assert_equal zips_zip(:zena ) + 1, Zena::Db.next_zip(sites_id(:zena))
    assert_equal zips_zip(:ocean) + 1, Zena::Db.next_zip(sites_id(:ocean))
    assert_equal zips_zip(:zena ) + 2, Zena::Db.next_zip(sites_id(:zena))
  end

  def test_fetch_row
    assert_equal "water", Zena::Db.fetch_row("SELECT name FROM nodes WHERE id = #{nodes_id(:water_pdf)}")
    assert_nil Zena::Db.fetch_row("SELECT name FROM nodes WHERE 0")
  end

  private
    def assert_list_equal(l1, l2)
      if l1[0].kind_of?(Hash)
        [l1,l2].each do |l|
          l.each do |h|
            h.each do |k,v|
              h[k] = v.to_s
            end
          end
        end
        l1.each do |h|
          assert l2.include?(h)
        end
        assert_equal l1.uniq.size, l2.uniq.size
      else
        assert_equal l1.map{|v| v.to_s}.sort, l2.map{|v| v.to_s}.sort
      end
    end
end