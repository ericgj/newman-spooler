=begin

TODO
-  JsonOutput  @done
-  set up Gemfile, clean up, add readme, github  @done
-  test decoding attachments  @done
-  test json with attachments @done
-  add top-level namespace
-  rewrite html_part & text_part via document rules ?   @done
-  Capture output filenames, trigger 'after' block  @done
-  capture email decoding errors
-  multi threaded?
-  abstract backend message queue
  
=end
require 'fileutils'

require 'mail'
require File.expand_path('patches/mail/message', File.dirname(__FILE__))

require File.expand_path('spool/utilities', File.dirname(__FILE__))
require File.expand_path('spool/document_rules', File.dirname(__FILE__))

class Spool
  extend SpoolUtils
  
  attr_accessor :base_dir
  
  def initialize(base_dir=nil)
    self.base_dir = base_dir
  end
  
  def message(&build)
    self.builder = Builder.new(&build)
    self
  end
  
  def after(&after_proc)
    self.after_proc = after_proc
    self
  end
  
  # TODO separate threads ?
  # TODO handle errors
  def <<(msg)
    files, attachs, errs = [], [], []
    out = output_rules(msg)
    
    files.push   *write_documents(  msg, out) unless out.documents.empty?
    attachs.push *write_attachments(msg, out) unless out.attachments.empty?
    
    after_proc[files, attachs, errs]  if after_proc
    self
  end
  
  def push(*msgs)
    msgs.each do |m|
      self << m
    end
  end
  
  def output_rules(m)
    builder[m]
  end
    
  def write_documents(m, out)
    out.documents.map do |spec|
      write spec[m].to_s, File.join(base_dir, out.path, spec.file)
    end
  end
  
  # deprecate
  def write_text_part(m, out)
    warn "deprecated, use #write_documents instead"
    write m.text_part.decoded, 
          File.join(base_dir, out.text_part_path)
  end
  
  # deprecate
  def write_html_part(m, out)
    warn "deprecated, use #write_documents instead"
    write m.html_part.decoded, 
          File.join(base_dir, out.html_part_path)
  end
  
  def write_attachments(m, out)
    m.attachments.map do |attach|
      write attach.decoded, 
            File.join(
              base_dir, 
              out.attachments_path(attach.mime_type),
              attach.filename
            )
    end
  end
  
  private
  
  attr_accessor :builder, :after_proc
  
  # todo deal with encodings?
  # todo abstract the backend (i.e. don't necessarily write to file system)
  def write(data, target)
    if target && data
      FileUtils.mkdir_p(File.dirname(target))
      File.open(target,'w+') do |f|
        f.write data
      end
      target
    end
  end
  
  class Builder
  
    attr_reader :output
    
    def initialize(&b)
      @build_proc = b
    end
    
    def [](msg)
      @output = OutputRules.new
      @build_proc.call(self, msg)
      @output
    end
    
    def path(dir)
      output.path = dir
    end

    def raw(file, params={})
      output.add_document RawDocumentRules.new(file, params)
    end
    
    def json(file, params={})
      output.add_document JsonDocumentRules.new(file, params)
    end
    
    def body(file, params={})
      params = {:part => :text}.merge(params)
      output.add_document BodyDocumentRules.new(file, params)
    end
    
    def text_part(file)
      body file, :part => :text
      #output.text_part = file
    end
    
    def html_part(file)
      body file, :part => :html
      #output.html_part = file
    end
    
    def attachments(mime_type=:all, dir='')
      output.attachments[mime_type] = dir
    end
    
  end
  
end

class OutputRules < Struct.new(:path, 
                          :documents,
                          :attachments)

  def initialize(*args)
    super
    self.documents ||= []
    self.attachments ||= {}
  end
  
  def add_document(doc)
    self.documents << doc
  end
  
  def attachments_path(type=:all)
    if attachments[type]
      File.join(path, attachments[type] || '')
    else
      File.join(path, attachments[:all] || '')
    end
  end
  
end


