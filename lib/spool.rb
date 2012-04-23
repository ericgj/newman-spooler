
require 'fileutils'

require 'mail'

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



class RawDocumentRules

  attr_accessor :file, :headers, :parts
  
  def initialize(file, params={})
    self.file = file
    self.headers = Array(params.fetch(:headers,[]))
    self.parts   = Array(params.fetch(:parts,[]))
  end

  def [](msg)
    RawOutput.new(msg, headers, parts)
  end
  
  class RawOutput
    
    attr_reader :message, :headers, :parts
    
    def initialize(msg, headers=[], parts=[])
      @message, @headers, @parts = msg, headers, parts
    end
    
    def to_s
      (scrub? ? scrubbed_message : message).encoded
    end
  
    def scrub?
      !(headers.empty? && parts.empty?)
    end
    
    def scrubbed_message
      m = ::Mail::Message.new
      m.header['Message-ID'] = message.header['Message-ID']
      headers.each do |k|
        m.header[k] = message.header[k]
      end
      parts.each do |meth|
        if meth == :body
          m.body = message.body.decoded     # probably not right
        else
          m.send "#{meth}=", message.send(meth)
        end
      end
      m      
    end
    
  end
  
end


class JsonDocumentRules

  attr_accessor :file, :headers, :parts
  
  def initialize(file, params={})
    self.file = file
    self.headers = Array(params.fetch(:headers,[]))
    self.parts   = Array(params.fetch(:parts,[]))
  end
  
  def [](msg)
    JsonOutput.new(msg, headers, parts)
  end
  
  class JsonOutput
    
    attr_reader :message, :headers, :parts
    
    def initialize(msg, headers=[], parts=[])
      @message, @headers, @parts = msg, headers, parts
    end
    
    def to_s
      ::MultiJson.dump(to_hash, :pretty => true)
    end
    
    #TODO
    def to_hash
      
    end
  end
  
end