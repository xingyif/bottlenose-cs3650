require 'audit'
require 'zipruby'
require 'fileutils'
require 'zlib'

class Upload < ActiveRecord::Base
  validates :file_name,  :presence => true
  validates :user_id,    :presence => true
  validates :secret_key, :presence => true

  validate :data_and_metadata_stored

  belongs_to :user

  after_initialize :generate_secret_key!
  before_destroy :cleanup!

  def data_and_metadata_stored
    unless File.exists?(submission_path)
      Audit.log("Uploaded file missing for upload in #{upload_dir}, aborting save.")
      return false
    end

    unless File.exists?(metadata_path)
      Audit.log("Metadata missing for upload in #{upload_dir}, aborting save.")
      return false
    end
    true
  end

  def create_submission_structure(upload, metadata)
    # upload_dir/
    # +-- metadata.yaml
    # +-- submission/
    # |   +-- original_filename
    # +-- extracted/
    # |   ... unzipped contents, or copied file ...
    # +-- graders/
    #     +-- grader_id/
    #     |   ... grader output ...
    #     ... more graders ...
    base = upload_dir
    base.mkpath
    base.join("submission").mkpath
    base.join("extracted").mkpath
    base.join("graders").mkpath

    store_meta!(metadata)

    self.file_name = upload.original_filename

    File.open(submission_path, 'wb') do |file|
      file.write(upload.read)
    end

    if upload.content_type == "application/zip"
      debugger
      Zip::Archive.open(submission_path.to_s) do |ar|
        raise Exception.new("Too many files in zip!") if ar.num_files > 100
        ar.each do |zf|
          if zf.directory?
            FileUtils.mkdir_p(base.join("extracted", zf.name))
          else
            dest = base.join("extracted", zf.name)
            dirname = File.dirname(dest)
            FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
            
            File.open(dest, 'wb') do |f|
              f << zf.read
            end
          end
        end
      end
    elsif upload.content_type == "application/x-tar"
      SubTarball.untar(submission_path, base.join("extracted"))
    elsif upload.content_type == "application/x-compressed-tar"
      SubTarball.untar_gz(submission_path, base.join("extracted"))
    elsif upload.content_type == "application/gzip"
      if upload.original_filename.ends_with?(".tar.gz")
        SubTarball.untar_gz(submission_path, base.join("extracted"))
      else
        dest = base.join("extracted", File.basename(upload.original_filename, ".gz"))
        Zlib::GzipReader.open(submission_path) do |input_stream|
          File.open(dest, "w") do |output_stream|
            IO.copy_stream(input_stream, output_stream)
          end
        end
      end
    else
      FileUtils.cp(submission_path, base.join("extracted"))
    end

  end

  def upload_dir
    pre = secret_key.slice(0, 2)
    Upload.base_upload_dir.join(pre, secret_key)
  end

  def path
    # Yields a string that's a public uploads path to the submitted file
    upload_path_for(submission_path)
  end

  def store_upload!(upload, metadata)
    if user_id.nil?
      raise Exception.new("Must set user before storing uploaded file.")
    end

    if Dir.exists?(upload_dir)
      raise Exception.new("Duplicate secret key (1). That's unpossible!")
    end

    Audit.log("User #{user.name} (#{user_id}) creating upload #{secret_key}")

    create_submission_structure(upload, metadata)

    Audit.log("Uploaded file #{file_name} for #{user.name} (#{user_id}) at #{secret_key}")
  end

  def extracted_files
    def rec_path(path)
      path.children.sort.collect do |child|
        if child.file?
          {path: child.basename.to_s, full_path: child, public_link: upload_path_for(child)}
        elsif child.directory?
          {path: child.basename.to_s, children: rec_path(child)}
        end
      end
    end
    rec_path(extracted_path)
  end


  def extracted_path
    upload_dir.join("extracted")
  end
  
  def submission_path
    upload_dir.join("submission", file_name)
  end

  def metadata_path
    upload_dir.join("metadata.yaml")
  end

  def grader_path(grader)
    upload_dir.join("graders", grader.id.to_s)
  end
  
  private
  def upload_path_for(p)
    p.to_s.sub(Rails.root.join("public").to_s, "")
  end

  def store_meta!(meta)
    if File.exists?(metadata_path)
      raise Exception.new("Attempt to reset metadata on upload.")
    end

    File.open(metadata_path, "w") do |file|
      file.write(meta.to_yaml)
    end
  end

  def generate_secret_key!
    return unless new_record?

    unless secret_key.nil?
      raise Exception.new("Can't generate a second secret key for an upload.")
    end

    self.secret_key = SecureRandom.urlsafe_base64

    if Dir.exists?(upload_dir)
      raise Exception.new("Duplicate secret key (2). That's unpossible!")
    end
  end

  def cleanup!
    Audit.log("Skip cleanup: #{file_name} for #{user.name} (#{user_id}) at #{secret_key}")
  end

  def self.base_upload_dir
    Rails.root.join("public", "uploads", Rails.env)
  end

  def self.cleanup_test_uploads!
    dir = Rails.root.join("public", "uploads", "test").to_s
    if dir.length > 8 && dir =~ /test/
      FileUtils.rm_rf(dir)
    end
  end
end
