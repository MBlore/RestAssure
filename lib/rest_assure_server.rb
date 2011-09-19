module RestAssure
  require 'rexml/document'
  
  class RestAssureServer
    
    def initialize(config_filename)
      @config_filename = config_filename
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
          
          puts
          
          puts 'Service Name: ' + doc.root.elements['name'].text
          puts 'Service Address: ' + doc.root.elements['baseAddress'].text
        
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
    
  end
  
end