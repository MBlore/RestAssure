module RestAssure
  require 'rexml/document'
  require 'uri'
  require 'webrick'
  
  class Router
    include Singleton
    
    def initialize
      @route_list = {:get => {}, :put => {}, :post => {}, :delete => {}}
    end
    
    def add_route(method, route, &blk)
      @route_list[method][route] = blk
    end
      
    def handle_request(request)
      
      method = request.request_uri.method.downcase.to_sym
      route = request.request_uri
      
      content = @route_list[method][route].call
      return content
      
    end
    
  end
  
  class HTTPListener < WEBrick::HTTPServlet::AbstractServlet
    def do_GET(request, response)
      Router.instance.handle_request(request)
    end      
  end
  
  class RestAssureServer
    
    def initialize(config_filename)
      @config_filename = config_filename
      @route_list = {:get => {}, :put => {}, :post => {}, :delete => {}}
    end
    
    def add_route(method, route, &blk)
      @route_list[method][route] = blk
    end
 
    def start
        begin
      
          puts 'Initializing REST server...'
          puts
          puts "Loading configuration from '" + @config_filename + "'..."
          
          file = File.new(@config_filename)
          doc = REXML::Document.new file
          
          puts 'Validating configuration...'         
          
          if validate_config(doc.root) > 0
            puts 'Errors occurred. Failed to start server.'
            return
          end
          
          base_address = doc.root.elements['baseAddress'].text
          
          @uri = URI::parse(base_address)
          
          if !@uri.is_a? URI::HTTP and !@uri.is_a? URI::HTTPS
            puts 'Error: The base address must be a HTTP or HTTPS URI.'
            return
          end
          
          puts
          puts 'Service Name: ' + doc.root.elements['name'].text
          puts 'Service Address: ' + base_address
          puts
          
          start_server()
                                                
        rescue => e
          puts 'Unhandled exception occurred.'
          puts 'Message: ' + e.message
          puts 'Trace:'
          puts e.backtrace
        end
      
    end
    
    private
    def validate_config(root)
      
      errors = 0
      
      # <name>
      if root.elements['name'].nil?
        puts '  Error: Service name is missing.'
        errors += 1
      end
    
      # <baseAddress>
      ba = root.elements['baseAddress']  
      if ba.nil? or ba.text.length == 0
        puts '  Error: Service base address is missing.'
        errors += 1
      end
      
      # <automaticHelp>
      ah = root.elements['automaticHelp']
      ahf = root.elements['automaticHelpFile']
           
      if !ah.nil? and ah.text == 'true'
        if ahf.nil? or !File.exists?(ahf.text)
          puts '  Error: Automatic help is configured, but the proposed file is not specified or missing.'
          errors += 1
        end
      end
      
      root.elements.each('resources/resource') do |e|

        # <name>
        e_name = e.elements['name']
        if e_name.nil?
          puts '  Error: A defined resource has no name.'
          errors += 1
        end
        
        # verbs check
        if e.elements["verbs/*[@allowed='true']"].nil?
          puts '  Error: Resource ' + e_name.text + ' has no allowed HTTP methods.'
          errors += 1
        end
        
        # If GET is allowed, check content types...
        e_get = e.elements["verbs/get"]
        
        if !e_get.nil?
          
          e_get_allowed = e_get.attributes['allowed']
          
          if !e_get_allowed.nil? and e_get_allowed == 'true'
            
            e_content_types = e.elements["representationContentTypes"]
            if !e_content_types.nil? and e_content_types.elements.count == 0
              puts '  Error: Resource ' + e_name.text + ' has allowed GET but no representation content types have been specified.'
              errors += 1
            end
            
          end
          
        end
        
        # If PUT or POST is allowed, check content types...
        e_put = e.elements["verbs/put"]
        e_post = e.elements["verbs/post"]
        
        if !e_put.nil? or !e_post.nil?
          
          e_put_allowed = 'false'
          e_post_allowed = 'false'
          
          if !e_put.nil? 
            e_put_allowed = e_put.attributes['allowed']
          end
          
          if !e_post.nil? 
            e_post_allowed = e_post.attributes['allowed']
          end
          
          if e_put_allowed == 'true' or e_post_allowed == 'true'
           
            e_invoke_content_types = e.elements["invokeContentTypes"]
            
            if !e_invoke_content_types.nil? and e_invoke_content_types.elements.count == 0
              puts '  Error: Resource ' + e_name.text + ' has allowed PUT/POST but no invoke content types have been specified.'
              errors += 1
            end
            
          end
          
        end
        
        # <uriTemplate>
        e_uri_template = e.elements['uriTemplate']
        if e_uri_template.nil?
          puts '  Error: Resource ' + e_name.text + ' is missing a URI template.'
          errors += 1
        end        
        
      end
            
      return errors
      
    end
    
    def start_server
      
      webrick_log_file = 'NUL'
      webrick_logger = WEBrick::Log.new(webrick_log_file, WEBrick::Log::DEBUG)
      
      server = WEBrick::HTTPServer.new(
        :Port   => @uri.port,
        :Logger => webrick_logger,
      )
      
      server.mount_proc '/' do |req, res|
        res.status = 200
        res['Content-Type'] = 'text/html'
        res.body = '<b>hello</b> <i>world</i>'
      end

      trap "INT" do
        puts('Shutting down...')
        server.shutdown
      end

      puts 'Listening for requests...'
      
      server.start
      
    end
    
  end
  
end