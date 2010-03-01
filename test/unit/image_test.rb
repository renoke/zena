require 'test_helper'

class ImageTest < Zena::Unit::TestCase

  # don't use transaction fixtures so that after_commit (implemented in Versions gem) works.
  self.use_transactional_fixtures = false

  context 'Creating an image' do
    setup do
      login(:tiger)
    end

    teardown do
      FileUtils.rm(subject.filepath) if subject && subject.version.attachment
    end

    subject do
      secure!(Image) { Image.create( :parent_id=>nodes_id(:cleanWater),
                                          :name=>'birdy',
                                          :file => uploaded_jpg('bird.jpg')) }
    end

    should 'record be valid' do
      subject.valid?
    end

    should 'record be saved in database' do
      assert !subject.new_record?
    end

    should 'save image in File System' do
      assert File.exist?(subject.filepath)
    end

    should 'save original filename' do
      assert_equal 'bird.jpg', subject.file.original_filename
    end

    should 'be kind of Image' do
      assert_kind_of Image , subject
    end

    should 'save ext (extension)' do
      assert_equal 'jpg', subject.ext
    end

    should 'save content type' do
      assert_equal 'image/jpeg', subject.content_type
    end

    should 'save width with full format' do
      assert_equal 660, subject.width
    end

    should 'save height with full format' do
      assert_equal 600, subject.height
    end

    should 'create a version' do
      assert_not_nil subject.version.id
    end

    should 'create an attachment' do
      assert_not_nil subject.version.attachment.id
    end

    should 'build filepath with file name' do
      assert_match /bird.jpg/, subject.filepath
    end

    context 'with specific title' do
      setup do
        subject do
          secure!(Image) { Image.create( :parent_id=>nodes_id(:cleanWater),
                                              :title=>'eagle',
                                              :file => uploaded_jpg('bird.jpg')) }
        end
      end

      should 'build filepath with file name' do
        assert_match /bird.jpg/, subject.filepath
      end
    end

  end

  context 'Resizing image with a new format' do
    setup do
      @pv_format = Iformat['pv']
      login(:ant)
      @img = secure!(Image) { Image.create( :parent_id=>nodes_id(:cleanWater),
                                          :name=>'birdy', :file => uploaded_jpg('bird.jpg')) }
      @img.file(@pv_format)
    end

    teardown do
      FileUtils.rm(subject.filepath) if subject && subject.version.attachment
    end

    subject do
      @img
    end

    should 'return the resolution corresponding to the new format' do
      assert_equal "70x70", "#{subject.width(@pv_format)}x#{subject.height(@pv_format)}"
    end

    should 'return the full resolution by default' do
      assert_equal "660x600", "#{subject.width()}x#{subject.height()}"
    end

    should 'create a new file corresponding to the new format' do
      assert File.exist?( subject.filepath(@pv_format) )
    end

    should 'create a new file path witch a folder named of the format' do
      assert_match /pv/, subject.filepath(@pv_format)
    end

    should 'return file corresponding to the new format' do
      assert_kind_of File, subject.file(@pv_format)
    end

    should 'keep the original file' do
      assert_match /full/, subject.filepath
    end

    should 'not create a version' do
      assert_equal 1, subject.versions.count
    end

    context 'and updating name' do
      setup do
        @img.update_attributes(:name=>'milan')
      end

      should 'change node name' do
        assert_equal 'milan', subject.name
      end

      should 'keep filepath of both format' do
        assert_match /full/, subject.filepath
        assert_match /pv/, subject.filepath(@pv_format)
      end
    end

  end

  context 'Accepting content type' do

    should 'Image accept jpeg' do
      assert Image.accept_content_type?('image/jpeg')
    end

    should 'not accepect pdf' do
      assert !Image.accept_content_type?('application/pdf')
    end
  end

  context 'Updating image file' do
    setup do
      login(:tiger)
      @img = secure!(Image) { Image.create( :parent_id=>nodes_id(:cleanWater),
                                          :title=>'birdy', :file => uploaded_jpg('bird.jpg')) }
      @img.update_attributes(:file=>uploaded_jpg('flower.jpg'))
    end

    teardown do
      FileUtils.rm(subject.filepath) if subject.version.attachment
    end

    subject do
      @img
    end

    should 'record be valid' do
      assert subject.valid?
    end

    should 'record be saved' do
      assert !subject.new_record?
    end

    should 'change file name' do
      assert_equal 'flower.jpg', subject.filename
    end

    should 'change filepath' do
      assert_match /flower.jpg/, subject.filepath
    end

    should 'change image width' do
      assert_equal 800, subject.width
    end

    should 'change image height' do
      assert_equal 800, subject.width
    end

    should 'change image size' do
      assert_equal 96648, subject.size
    end
  end

  context 'Updating non image file' do
    setup do
      login(:tiger)
      @img = secure!(Image) { Image.create( :parent_id=>nodes_id(:cleanWater),
                                          :title=>'spring', :file => uploaded_jpg('flower.jpg')) }
      @img.update_attributes(:file=>uploaded_text('some.txt'))
    end

    teardown do
      FileUtils.rm(subject.filepath) if File.exist?(subject.filepath)
    end

    subject do
      @img
    end

    should 'not change content type' do
      assert 'image/jpeg', subject.content_type
    end

    should 'not change file name' do
      assert 'flower.jpg', subject.filename
    end

    should 'not change file path' do
      assert_match /flower.jpg/, subject.filepath
    end

    should 'not create a version' do
      assert 1, subject.versions.size
    end
  end

  context 'Croping image' do
    setup do
      login(:tiger)
      @img = secure!(Image) { Image.create( :parent_id=>nodes_id(:cleanWater),
                                          :title=>'goeland', :file => uploaded_jpg('bird.jpg')) }
    end

    teardown do
      FileUtils.rm(subject.filepath) if File.exist?(subject.filepath)
    end

    subject{ @img }

    should 'build filepath with file name' do
      assert_match /bird.jpg/, subject.filepath
    end

    context 'with x, y, w, h' do
      setup do
        @img.update_attributes(:crop=>{:x=>'500',:y=>30,:w=>'200',:h=>80})
      end

      should 'keep image valid' do
        assert subject.valid?
      end

      should 'return new size' do
        assert_equal 2010, subject.size
      end

      should 'return new width' do
        assert_equal 160, subject.width
      end

      should 'return new height' do
        assert_equal 80, subject.height
      end

      should 'keep filepath with file name' do
        assert_match /bird.jpg/, subject.filepath
      end
    end

    context 'with limitation' do
      setup do
        @img.update_attributes(:crop=>{:max_value=>'30', :max_unit=>'Kb'})
      end

      should 'keep image valid' do
        err subject
        assert subject.valid?
      end

      should 'keep size under limitation' do
        assert subject.size < 30 * 1024 * 1.2
      end

      should 'keep filepath with file name' do
        assert_match /bird.jpg/, subject.filepath
      end
    end

    context 'with iformat' do
      setup do
        @img.update_attributes(:crop=>{:format=>'png'})
      end

      should 'keep image valid' do
        err subject
        assert subject.valid?
      end

      should 'change image extension' do
        assert_equal 'png', subject.ext
      end

      should 'change content_type' do
        assert_equal 'image/png', subject.content_type
      end
    end

    context 'with same size' do
      setup do
        @img.update_attributes(:crop=>{:x=>'0',:y=>0,:w=>'660',:h=>600})
      end

      should 'keep image valid' do
        err subject
        assert subject.valid?
      end

      should 'keep original width' do
        assert_equal 660, subject.width
      end

      should 'keep original height' do
        assert_equal 600, subject.height
      end
    end

    context 'with new file' do
      setup do
        @img.update_attributes(:file=>uploaded_jpg('flower.jpg'), :crop=>{:x=>'500',:y=>30,:w=>'200',:h=>80})
      end

      should 'keep image valid' do
        err subject
        assert subject.valid?
      end

      should 'return new width' do
        assert_equal 800, subject.width
      end

      should 'return new height' do
        assert_equal 600, subject.height
      end

      should 'return new size' do
        assert_equal 96648,  subject.size
      end
    end
  end



  def test_create_with_small_file
    preserving_files('/sites/test.host/data') do
      login(:ant)
      img = secure!(Image) { Image.create( :parent_id=>nodes_id(:cleanWater),
        :name => 'bomb.png',
        :c_file => uploaded_png('bomb.png') )}
      assert_kind_of Image, img
      assert ! img.new_record?, "Not a new record"
      assert_equal 793, img.version.content.size
      assert img.c_file(Iformat['pv'])
    end
  end

  def test_update_same_image
    login(:tiger)
    bird = secure!(Node) { nodes(:bird_jpg) }
    assert_equal Digest::MD5.hexdigest(bird.c_file.read),
                 Digest::MD5.hexdigest(uploaded_jpg('bird.jpg').read)
    bird.c_file.rewind
    assert_equal 1, bird.versions.count
    assert_equal '2006-04-11 00:00', bird.updated_at.strftime('%Y-%m-%d %H:%M')
    assert !bird.version.would_edit?('content_attributes' => {'file' => uploaded_jpg('bird.jpg')})
    assert bird.update_attributes(:c_file => uploaded_jpg('bird.jpg'))
    assert_equal 1, bird.versions.count
    assert_equal '2006-04-11 00:00', bird.updated_at.strftime('%Y-%m-%d %H:%M')
    assert bird.update_attributes(:c_file => uploaded_jpg('flower.jpg'))
    assert_equal 2, bird.versions.count
    assert_not_equal '2006-04-11 00:00', bird.updated_at.strftime('%Y-%m-%d %H:%M')
  end

  def test_set_event_at_from_exif_tags
    without_files('test.host/data/jpg') do
      login(:ant)
      img = secure!(Image) { Image.create( :parent_id=>nodes_id(:cleanWater),
                                          :inherit => 1,
                                          :name=>'lake',
                                          :c_file => uploaded_jpg('exif_sample.jpg')) }
      assert_equal 'SANYO Electric Co.,Ltd.', img.c_exif['Make']

      # reload
      assert img = secure!(Image) { Image.find(img.id) }
      assert exif_tags = img.c_exif
      assert_equal 'SANYO Electric Co.,Ltd.', img.c_exif['Make']
      assert_equal Time.parse("1998-01-01 00:00:00"), img.c_exif.date_time
      assert_equal Time.parse("1998-01-01 00:00:00"), img.event_at
    end
  end

end
