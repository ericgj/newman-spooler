gem 'minitest'
require 'minitest/spec'
MiniTest::Unit.autorun

# this is a really stupid dummy
# whenever possible, use a real Mail::Message object
class DummyEmail

  attr_reader :date, :to, :from, :subject, :text_part, :html_part, :attachments
  
  module DummyStringMethods
    def encoded; "=====encoded=====" + self; end
    def decoded; self.dup; end
  end
  
  module DummyAttachmentMethods
    attr_accessor :mime_type, :filename
  end
  
  def initialize(&b)
    @attachments = []
    instance_eval(&b)
  end
  
  def date=(s)
    @date = s.extend(DummyStringMethods)
  end
  
  def to=(s)
    @to = s.extend(DummyStringMethods)
  end
  
  def from=(s)
    @from = s.extend(DummyStringMethods)
  end
  
  def subject=(s)
    @subject = s.extend(DummyStringMethods)
  end
  
  def header
    {:date => date,
     :to   => to,
     :from => from,
     :subject => subject
    }
  end
  
  def text_part=(s)
    @text_part = s.extend(DummyStringMethods)
  end
  
  def html_part=(s)
    @html_part = s.extend(DummyStringMethods)
  end
 
  def add_attachment(s, mime_type, filename)
    attach = s.extend(DummyStringMethods, DummyAttachmentMethods)
    attach.mime_type = mime_type
    attach.filename = filename
    @attachments << attach
    attach
  end
  
  def encoded
    "=====encoded=====" + to_s
  end
  
  def decoded
    to_s
  end
  
  # Note: only intended to simulate a real email
  def to_s
    encoded_attachs = self.attachments.map do |a| 
                        "Content-Type: #{a.mime_type};\n" +
                        "Content-Disposition: attachment; filename=#{a.filename}\n\n" +
                        a.encoded
                      end
    %Q{
To: #{self.to.decoded}
From: #{self.from.decoded}
Subject: #{self.subject.decoded}
Content-Type: multipart/alternative;
 boundary="--xxxxxxxx";
 charset=UTF-8

--xxxxxxxx
Content-Type: text/plain;
 
#{text_part.decoded}


--xxxxxxxx
Content-Type: text/html;

#{html_part.decoded}


--xxxxxxxx
#{encoded_attachs.join("--xxxxxxxx\n\n")}


    }
  end
  
end