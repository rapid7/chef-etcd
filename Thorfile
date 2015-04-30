# encoding: utf-8

require 'bundler'
require 'bundler/setup'
require 'thor/scmversion'

require 'chef'
require 'chef/cookbook_site_streaming_uploader'
require 'chef/cookbook/metadata'
require 'chef/knife'
require 'fileutils'
require 'json'
require 'securerandom'

##
# Supermarket
##
class Tasks < Thor
  include Thor::Actions
  namespace :super

  # Don't vendor VCS files.
  # Reference GNU tar --exclude-vcs: https://www.gnu.org/software/tar/manual/html_section/tar_49.html
  # Boosted from https://github.com/berkshelf/berkshelf/blob/master/lib/berkshelf/berksfile.rb
  EXCLUDED_VCS_FILES = [
    '.arch-ids', '{arch}', '.bzr', '.bzrignore', '.bzrtags',
    'CVS', '.cvsignore', '_darcs', '.git', '.hg', '.hgignore',
    '.hgrags', 'RCS', 'SCCS', '.svn', '**/.git'].freeze

  ## Load kinfe configuration
  Chef::Config.from_file(File.join(ENV['HOME'], '.chef/knife.rb'))

  desc 'share', 'Package and upload cookbook to a supermarket'
  option :site, :type => :string,
                :aliases => :s,
                :default => Chef::Config.knife['supermarket_site'] || 'https://supermarket.chef.io/'
  option :user, :type => :string,
                :aliases => :u,
                :default => Chef::Config.knife['supermarket_user'] || Chef::Config.node_name
  option :key, :type => :string,
               :aliases => :k,
               :default => Chef::Config.knife['supermarket_key'] || Chef::Config.client_key
  option 'dry-run', :type => :boolean, :default => false
  def share
    temp_directory = ".temp/#{ SecureRandom.hex(16) }"
    ignore_file = IgnoreFile.new('chefignore', '.gitignore', EXCLUDED_VCS_FILES)

    invoke 'version:current', nil, []

    cookbook = Chef::Cookbook::Metadata.new
    cookbook.from_file('metadata.rb')

    stage_direcotry = File.join(temp_directory, cookbook.name)
    tarball_file = "#{ cookbook.name }-#{ cookbook.version }.tgz"
    tarball_path = File.join(temp_directory, tarball_file)

    empty_directory stage_direcotry

    cookbook_files = Dir.glob('**/{*,.*}')
    ignore_file.apply!(cookbook_files)

    say_status :package, "Cookbook #{ cookbook.name }@#{ cookbook.version }"

    ## First, make directories
    cookbook_files.select { |f| File.directory?(f) }.each do |f|
      FileUtils.mkdir_p(File.join(stage_direcotry, f))
    end

    ## Then copy files
    cookbook_files.reject { |f| File.directory?(f) }.each do |f|
      FileUtils.cp(f, File.join(stage_direcotry, f))
    end

    ## Finally, write metadata.json
    IO.write(File.join(stage_direcotry, 'metadata.json'), cookbook.to_json)

    ## And package it all up.
    inside(temp_directory) do
      run "tar -czf #{ tarball_file } #{ cookbook.name }"
    end

    say_status :upload, "Cookbook #{ cookbook.name }@#{ cookbook.version } to "\
      "#{ options['site'] } as #{ options['user'] }"

    if options['dry-run']
      say_status 'dry-run', 'Cookbook is not uploaded in dry-run mode. Run the '\
        'clean task to remove temporary files.', :yellow
    else
      http_resp = Chef::CookbookSiteStreamingUploader.post(
        File.join(options['site'], '/api/v1/cookbooks'),
        options['user'], options['key'],
        :tarball => File.open(tarball_path),
        :cookbook => { :category => '' }.to_json
      )

      if http_resp.code.to_i != 201
        say_status :error, "Error uploading cookbook: #{ http_resp.code } #{ http_resp.message }", :red
        say http_resp.body
      end
    end
  ensure
    invoke :clean, nil, [temp_directory] unless options['dry-run']
  end

  desc 'clean [TEMP]', 'Cleanup temporary files'
  def clean(temp = nil)
    return remove_dir temp unless temp.nil?
    Dir.glob('.temp/*').each { |t| remove_dir t }
  end
end

##
# Inspired by https://github.com/sethvargo/buff-ignore
##
class IgnoreFile
  attr_reader :statements
  COMMENT_OR_WHITESPACE = /^\s*(?:#.*)?$/.freeze

  def initialize(*args)
    @statements = []

    args.each do |arg|
      case
      when arg.is_a?(Array) then push(arg)
      when File.exist?(arg) then load_file(arg)
      else push(arg)
      end
    end
  end

  def push(*arg)
    statements.push(*arg.flatten.map(&:strip))
    statements.sort!
    statements.uniq!
  end
  alias_method :<<, :push

  def load_file(ifile)
    push(File.readlines(ifile).map(&:strip).reject do |line|
      line.empty? || line =~ COMMENT_OR_WHITESPACE
    end)
  end

  def ignored?(file)
    statements.any? { |statement| File.fnmatch?(statement, file) }
  end

  def apply(*files)
    files.flatten.reject do |file|
      file.strip.empty? || ignored?(file)
    end
  end

  def apply!(files)
    files.reject! do |file|
      file.strip.empty? || ignored?(file)
    end
  end
end
