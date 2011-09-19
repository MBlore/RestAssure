require '../../lib/rest_assure'
include RestAssure

server = RestAssureServer.new('config.xml')
server.start