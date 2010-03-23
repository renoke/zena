require 'zip/zipfilesystem'
require 'fileutils'

module Zena
  module Use
    module DataCompression

      # Inflate a zip file in a destination folder, which is by default the zip_file directory.
      # It create destination directory for each file included in the zip file.
      #
      #   Zena::Use::DataCompression.unzip('blue_template.zip', 'skin')
      #
      def self.unzip(zip_file, destination=nil)
        destination ||= File.dirname(zip_file)
        ::Zip::ZipFile.new(zip_file).each do |f|
          f_path = File.join(destination, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          f.extract(f_path) unless File.exist?(f_path)
        end
      end

    end
  end
end