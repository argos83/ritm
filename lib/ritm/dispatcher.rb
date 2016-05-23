module Ritm
  # Keeps a list of subscribers and notifies them when requests/responses are intercepted
  class Dispatcher
    def initialize
      @handlers = { on_request: [], on_response: [] }
    end

    def add_handler(handler)
      on_request { |*args| handler.on_request(*args) } if handler.respond_to? :on_request
      on_response { |*args| handler.on_response(*args) } if handler.respond_to? :on_response
    end

    def on_request(&block)
      @handlers[:on_request] << block
    end

    def on_response(&block)
      @handlers[:on_response] << block
    end

    def notify_request(request)
      notify(:on_request, request)
    end

    def notify_response(request, response)
      notify(:on_response, request, response)
    end

    private

    def notify(event, *args)
      @handlers[event].each do |handler|
        handler.call(*args)
      end
    end
  end
end
