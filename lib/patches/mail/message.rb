# Note this should probably be a module I extend onto Mail instances and their
# parts, instead, to avoid conflict with other possible implementations of this.
#
module Mail
  class Message
  
    # stolen from ::Mail::Message#to_yaml    
    # with filtering options
    #   +headers+     headers to include (default nil = all)
    #   +properties+  mail properties (instance variables) to include (default nil = all)
    #   +mime_types+  attachment/part mime types to include (default nil = all)
    #
    # note also that instance variable keys have the '@' stripped off in output
    #
    def to_hash(opts = {})
      incl_headers = opts.fetch(:headers,nil)
      incl_mimes   = opts.fetch(:mime_types,nil)
      incl_props   = opts.fetch(:properties,nil)
      incl_headers = incl_headers.map {|h| dasherize(h)} if incl_headers
      incl_mimes   = incl_mimes.map(&:to_s) if incl_mimes
      incl_props   = incl_props.map {|p| "@#{p}".to_sym} if incl_props
      
      hash = {}
      
      # headers
      hash['headers'] = {}
      header.fields.each do |field|
        hash['headers'][field.name] = field.value \
          if incl_headers.nil? || incl_headers.include?(field.name)
      end
      
      # non-string properties
      if delivery_handler && 
         (incl_props.nil? || incl_props.include?(:@delivery_handler))  
        hash['delivery_handler'] = delivery_handler.to_s
      end
      
      if incl_props.nil? || incl_props.include?(:@transport_encoding)
        hash['transport_encoding'] = transport_encoding.to_s
      end
      
      special_variables = [:@header, :@delivery_handler, :@transport_encoding]
      
      # recursively add parts under multipart_body key
      if multipart?
        hash['multipart_body'] = []
        body.parts.each do |part| 
          if incl_mimes.nil? || incl_mimes.include?(part.mime_type)
            hash['multipart_body'] << part.to_hash(opts)
          end
        end
        special_variables.push(:@body, :@text_part, :@html_part)
      end
      
      # properties
      #
      # Note hack: binary bodies are left in existing transfer-encoding rather
      # than decoded. Decoding triggers errors in serialization.
      # However, note that CRLF endings are left in, and a given serialization
      # may need to escape these.
      #
      (instance_variables.map(&:to_sym) - special_variables).each do |var|
        if incl_props.nil? || incl_props.include?(var)
          hash[var.to_s.gsub(/^\@/,'')] = 
            if var == :@body && %w[base64 binary].include?(body.encoding)
              instance_variable_get(var).encoded
            else
              instance_variable_get(var)
            end
        end
      end
      hash
    end
    
  end
end