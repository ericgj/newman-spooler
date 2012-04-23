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
