require 'rubygems/package'
require 'zlib'

TAR_LONGLINK = '././@LongLink'


class SubTarball
  def initialize(as_id)
    @as = Assignment.find(as_id)
  end

  def update!
    temp = Rails.root.join('tmp', 'tars', 'assign', @as.id.to_s)
    if temp.to_s =~ /tars\/assign/
      FileUtils.rm_rf(temp)
    end

    FileUtils.mkdir_p(temp)

    afname = "assignment_#{@as.id}"

    dirs = temp.join(afname)
    FileUtils.mkdir_p(dirs)

    @as.main_submissions.each do |sub|
      next if sub.file_full_path.blank?

      uu = sub.user
      dd = dirs.join(uu.dir_name)
      FileUtils.mkdir_p(dd)

      FileUtils.mkdir_p(dd)

      FileUtils.cp(sub.file_full_path, dd)
    end

    FileUtils.cd(temp)
    system(%Q{tar czf "#{afname}.tar.gz" "#{afname}"})

    src = temp.join("#{afname}.tar.gz")

    FileUtils.cp(src, @as.tarball_full_path)
  end

  def path
    @as.tarball_path
  end

  def self.untar(source, dest)
    self.untar_source(File.open(source), dest)
  end

  def self.untar_gz(source, dest)
    self.untar_source(Zlib::GzipReader.open(source), dest)
  end

private
  def self.untar_source(source, destination)
    # from https://dracoater.blogspot.com/2013/10/extracting-files-from-targz-with-ruby.html
    Gem::Package::TarReader.new(source) do |tar|
      dest = nil
      tar.each do |entry|
        if entry.full_name == TAR_LONGLINK
          dest = File.join destination, entry.read.strip
          next
        end
        dest ||= File.join destination, entry.full_name
        if entry.directory?
          FileUtils.rm_rf dest unless File.directory? dest
          FileUtils.mkdir_p dest, :mode => entry.header.mode, :verbose => false
        elsif entry.file?
          FileUtils.rm_rf dest unless File.file? dest
          FileUtils.mkdir_p(File.dirname(dest))
          File.open dest, "wb" do |f|
            f.print entry.read
          end
          FileUtils.chmod entry.header.mode, dest, :verbose => false
        elsif entry.header.typeflag == '2' #Symlink!
          File.symlink entry.header.linkname, dest
        end
        dest = nil
      end
    end
  end
end
