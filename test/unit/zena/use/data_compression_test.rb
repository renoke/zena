require 'test_helper'

class DataCompressionTest < Test::Unit::TestCase

  context 'Unzip a file to a specified folder' do
    setup do
      Zena::Use::DataCompression.unzip  "#{RAILS_ROOT}/test/fixtures/files/9752.zip",
                                        "#{RAILS_ROOT}/test/fixtures/import"
    end

    should 'inflate the file within the specified folder' do
      assert File.exist?("#{RAILS_ROOT}/test/fixtures/import/9752")
    end

    teardown do
      FileUtils.rm_r("#{RAILS_ROOT}/test/fixtures/import/9752") if
        File.exist?("#{RAILS_ROOT}/test/fixtures/import/9752")
    end
  end

  context 'Unzip a file in default folder' do
    setup do
      Zena::Use::DataCompression.unzip  "#{RAILS_ROOT}/test/fixtures/files/9752.zip"
    end

    should 'inflate the file within the default folder' do
File.exist?("#{RAILS_ROOT}/test/fixtures/files/9752")
    end

    teardown do
      FileUtils.rm_r("#{RAILS_ROOT}/test/fixtures/files/9752") if
        File.exist?("#{RAILS_ROOT}/test/fixtures/files/9752")
    end
  end

end