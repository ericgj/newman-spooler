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