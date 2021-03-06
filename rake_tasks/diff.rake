# A simple differ using svn. Handles externals.
class Differ < Hash
  
  include Rake::DSL
  
  def initialize path
    @path = path
    super 0
  end
  
  def count key, value
    self[key] += value
    value
  end
  
  FORMAT = '  %-30s %8d lines, %3d changes in %2d files'
  
  def scan(path = @path)
    Dir.chdir path do
      diff_file_name = 'diff'
      if File.directory? 'diff'
        diff_file_name = 'diff.diff'
      end
      system "svn diff > #{diff_file_name}"
      if File.size? diff_file_name
        puts FORMAT %
          [
            path,
            count(:LOC, `wc -l #{diff_file_name}`.to_i),
            count(:changes, `grep ^@@ #{diff_file_name} | wc -l`.to_i),
            count(:files, `grep ^Index #{diff_file_name} | wc -l`.to_i),
          ]
      else
        rm diff_file_name
      end
    end
  end
  
  def scan_with_externals(path = @path)
    scan path
    `svn status`.scan(/^X\s*(.*)/) do |external,|
      scan external
    end
  end
  
  def clean(path = @path)
    Dir.chdir path do
      rm 'diff' if File.file? 'diff'
      rm 'diff.diff' if File.file? 'diff.diff'
    end
  end
  
  def clean_with_externals(path = @path)
    clean path
    `svn status`.scan(/^X\s*(.*)/) do |external,|
      clean external
    end
  end
  
  def differences?
    self[:LOC] > 0
  end
  
  def inspect
    FORMAT %
      [ 'Total', self[:LOC], self[:changes], self[:files] ]
  end
  
end

namespace :diff do
  
  desc 'Make a diff and print a summary'
  task :summary do
    differ = Differ.new '.'
    differ.scan_with_externals
    if differ.empty?
      puts 'No differences found.'
    else
      p differ
    end
  end
  
  desc 'Remove all diffs'
  task :clean do
    differ = Differ.new '.'
    differ.clean_with_externals
  end
  
end

desc 'Make a diff and print a summary'
task :diff => 'diff:summary'
