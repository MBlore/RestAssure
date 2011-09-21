# Main application point.

require 'webrick'
require "addressable/template"

class Simple < WEBrick::HTTPServlet::AbstractServlet
  
  def do_GET(request, response)
    
    puts request.header
    
    puts request.path
    
    template = Addressable::Template.new("/resource1/{0}/{1}/{2}")
    p template.extract(request.path)
    
    status, content_type, body = do_stuff_with(request)
    
    response.status = status
    response['Content-Type'] = content_type
    response.body = body
  end
  
  def do_stuff_with(request)
    return 200, "text/plain", "default page"
  end
  
end


#server = WEBrick::HTTPServer.new(:Port => 8001)
#server.mount "/configurable", Simple

#trap "INT" do
   #puts('Shutting down...')
   #server.shutdown
#end

#server.start
