
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
    write_raw m, out
    write_json m, out
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
  
  def write_raw(m, out)
    if out.scrub_raw?
      write scrubbed_message(m, out.raw_headers, out.raw_parts).encoded,
            File.join(base_dir, out.raw_path)
    else
      write m.encoded, File.join(base_dir, out.raw_path)
    end
  end

  #todo  
  def write_json(m, out)
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
  
  def scrubbed_message(msg, headers, parts)
    m = ::Mail::Message.new
    m.header['Message-ID'] = msg.header['Message-ID']
    headers.each do |k|
      m.header[k] = msg.header[k]
    end
    parts.each do |meth|
      if meth == :body
        m.body = msg.body.decoded
      else
        m.send "#{meth}=", msg.send(meth)
      end
    end
    m
  end
  
  private
  
  attr_accessor :builder
  
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
      @output = Output.new
      @build_proc.call(self, msg)
      @output
    end
    
    def path(dir)
      output.path = dir
    end

    def raw(file, params={})
      output.raw_headers = Array(params.fetch(:headers,[]))
      output.raw_parts   = Array(params.fetch(:parts,[]))
      output.raw = file
    end
    
    def json(file, params={})
      output.json_headers = Array(params.fetch(:headers,[]))
      output.json_parts   = Array(params.fetch(:parts,[]))
      output.json = file
    end
    
    def text_part(file)
      output.text_part = file
    end
    
    def html_part(file)
      output.html_part = file
    end
    
    def headers(file)
      output.headers = file
    end
    
    def attachments(mime_type=:all, dir='')
      output.attachments[mime_type] = dir
    end
    
    class Output < Struct.new(:path, 
                              :raw,
                              :raw_headers,
                              :raw_parts, 
                              :json,
                              :json_headers,
                              :json_parts,
                              :text_part, 
                              :html_part, 
                              :headers, 
                              :attachments)
    
      def initialize(*args)
        super
        self.raw_headers ||= []  # empty == all
        self.raw_parts ||= []    # empty == all
        self.json_headers ||= []  # empty == all
        self.json_parts ||= []    # empty == all
        self.attachments ||= {}
      end
      
      def raw_path
        File.join(path, raw)
      end
      
      def scrub_raw?
        !(raw_headers.empty? && raw_parts.empty?)
      end
      
      def text_part_path
        File.join(path, text_part)
      end
      
      def html_part_path
        File.join(path, html_part)
      end
      
      def headers_path
        File.join(path, headers)
      end
      
      def attachments_path(type=:all)
        File.join(path, attachments[type])
      end
      
      
    end
    
  end
  
end
