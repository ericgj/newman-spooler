=begin

TODO
1. JsonOutput
2. Capture output filenames, trigger 'after' block
3. rewrite html_part via document rules, wrap with <html><body> if not already- use nokogiri
4. refactor document rules, move to separate source files
5. multi threaded?
6. abstract backend message queue
  
=end
require 'fileutils'

require 'mail'
require File.expand_path('patches/mail/message.rb', File.dirname(__FILE__))

module SpoolUtils

  def hash_path(msg, n=2)
    hash(msg).insert(n,'/')
  end
  
  def hash(msg)
    require 'digest/sha1'
    Digest::SHA1.hexdigest(msg.encoded)
  end

  # pathname escape valid for both Windows and *nix
  def escape(string)
    string.gsub(/([\<\>\:\"\/\\\|\?\*]+)/n) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
    end.tr(' ', '_')
  end 
  
end

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
  
  # TODO separate threads ?
  # TODO run 'after' proc
  def <<(msg)
    out = output_rules(m)
    write_documents m, out
    write_text_part m, out
    write_html_part m, out
    write_attachments m, out
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
  
  
  def write_text_part(m, out)
    write m.text_part.decoded, File.join(base_dir, out.text_part_path)
  end
  
  def write_html_part(m, out)
    write m.html_part.decoded, File.join(base_dir, out.html_part_path)
  end
  
  def write_attachments(m, out)
    m.attachments.map do |attach|
      write attach.decoded, 
            File.join(
              base_dir, 
              (out.attachments_path(attach.mime_type) || 
               out.attachments_path(:all)
              ),
              attach.filename
            )
    end
  end
  
  private
  
  attr_accessor :builder
  
  # todo deal with encodings?
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
    
    def text_part(file)
      output.text_part = file
    end
    
    def html_part(file)
      output.html_part = file
    end
    
    def attachments(mime_type=:all, dir='')
      output.attachments[mime_type] = dir
    end
    
  end
  
end

class OutputRules < Struct.new(:path, 
                          :documents,
                          :text_part, 
                          :html_part, 
                          :attachments)

  def initialize(*args)
    super
    self.documents ||= []
    self.attachments ||= {}
  end
  
  def add_document(doc)
    self.documents << doc
  end
    
  def text_part_path
    File.join(path, text_part)
  end
  
  def html_part_path
    File.join(path, html_part)
  end
  
  def attachments_path(type=:all)
    File.join(path, attachments[type])
  end
  
end


#----------NEW


# base class
class DocumentRules

  DEFAULT_HEADERS    = ['Content-Type']
  DEFAULT_PROPERTIES = ['charset']
  DEFAULT_MIME_TYPES = ['text/plain']
  
  attr_accessor :file, :headers, :properties, :mime_types
  
  def initialize(file, params={})
    self.file = file
    self.headers      = params.delete(:headers)
    self.properties   = params.delete(:properties)
    self.mime_types   = params.delete(:mime_types)
    initialize_params(params)
  end

  def [](msg)
    raise NotImplementedError,
          "Implement in subclass, return value must define #to_s"
  end

  # default no-op
  def initialize_params(params)
  end
  
  # helper function for common case
  def to_hash(msg)
    hdrs  = headers    ? (DEFAULT_HEADERS    | headers   ) : nil
    prps  = properties ? (DEFAULT_PROPERTIES | properties) : nil
    mimes = mime_types ? (DEFAULT_MIME_TYPES | mime_types) : nil
    
    puts hdrs.inspect
    puts prps.inspect
    puts mimes.inspect
    
    msg.to_hash :headers    => hdrs,
                :properties => prps,
                :mime_types => mimes
  end
  
  
end

class RawDocumentRules < DocumentRules

  def [](msg)
    if scrub?
      ScrubOutput.new( to_hash(msg) )
    else
      msg.encoded
    end
  end
  
  def scrub?
    headers || properties || mime_types
  end
  
  class ScrubOutput
    
    def initialize(hash)
      @hash = hash
    end
    
    def to_s
      to_message.encoded
    end
  
    # recursively build multipart message parts from hash
    # expensive as hell as it dups the whole msg hash and each part
    def to_message(h=nil,klass=::Mail::Message)
      h ||= @hash
      h = h.dup
      if h['multipart_body']
        parts = h.delete('multipart_body')
      else
        parts = []
        h['body'] = h.delete('body_raw')
      end
      msg = klass.new(h)
      parts.each do |part|
        msg.add_part to_message(part, ::Mail::Part)
      end
      msg
    end
    
  end
  
end


class JsonDocumentRules < DocumentRules
  
  attr_accessor :options
  
  def [](msg)
    JsonOutput.new( to_hash(msg), options )
  end
  
  def initialize_params(params)
    @options = params
  end
  
  class JsonOutput
    
    DEFAULT_OPTIONS = {:pretty => true}
    
    def initialize(hash, opts={})
      @hash, @options = hash, DEFAULT_OPTIONS.merge(opts)
    end
    
    def to_s
      require 'multi_json'
      ::MultiJson.dump(@hash, @options)
    end    
    
  end
  
end