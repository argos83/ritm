module Ritm
  # Keeps a list of subscribers and notifies them when requests/responses are intercepted
  class Dispatcher
    def initialize
      @handlers = { on_request: [], on_response: [], on_forward: [] }
    end

    def add_handler(handler)
      on_request { |*args| handler.on_request(*args) } if handler.respond_to? :on_request
      on_forward { |*args| handler.on_forward(*args) } if handler.respond_to? :on_forward
      on_response { |*args| handler.on_response(*args) } if handler.respond_to? :on_response
    end

    def on_request(&block)
      @handlers[:on_request] << block
    end

    def on_forward(&block)
      @handlers[:on_forward] << block
    end

    def on_response(&block)
      @handlers[:on_response] << block
    end

    def notify_request(request)
      notify(:on_request, request)
    end

    def notify_forward(request, response, &block)
      if @handlers[:on_forward].empty?
        yield
      else
        notify(:on_forward, request, response, &block)
      end
    end

    def notify_response(request, response)
      notify(:on_response, request, response)
    end

    private

    def notify(event, *args, &block)
      @handlers[event].each do |handler|
        handler.call(*args, &block)
      end
    end
  end
end
