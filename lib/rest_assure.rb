# Main application point.

require 'webrick'
require '../../lib/rest_assure_server'

class Simple < WEBrick::HTTPServlet::AbstractServlet
  
  def do_GET(request, response)
    
    puts request.header
    
    status, content_type, body = do_stuff_with(request)
    
    response.status = status
    response['Content-Type'] = content_type
    response.body = body
  end
  
  def do_stuff_with(request)
    return 200, "text/plain", "default page"
  end
  
end

#server = WEBrick::HTTPServer.new(:Port => 8000)
#server.mount "/configurable", Simple

#trap "INT" do
   #puts('Shutting down...')
   #server.shutdown
#end

#server.start
