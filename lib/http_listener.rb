module RestAssure
  
  # Base HTTP listener class for varied HTTP server implementations.
  class HttpListener
    
    def start(port)
      raise NotImplementedError
    end
    
    def stop()
      raise NotImplementedError
    end
    
  end
  
end