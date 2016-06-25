
dispatcher = Ritm.dispatcher

DEFAULT_REQUEST_HANDLER = proc do |req|
  dispatcher.notify_request(req) if Ritm.conf.intercept.enabled
end

DEFAULT_RESPONSE_HANDLER = proc do |req, res|
  dispatcher.notify_response(req, res) if Ritm.conf.intercept.enabled
end
