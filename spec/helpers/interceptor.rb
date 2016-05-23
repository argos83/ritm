require 'ritm'

class TestHandler
  attr_reader :requests, :responses
  attr_accessor :on_request, :on_response

  def initialize
    clear
    Ritm.on_request do |req|
      @requests << req
      @on_request.call(req) unless @on_request.nil?
    end
    Ritm.on_response do |req, res|
      @responses << res
      @on_response.call(req, res) unless @on_response.nil?
    end
  end

  def clear
    @on_request = nil
    @on_response = nil
    @requests = []
    @responses = []
  end
end

INTERCEPTOR = TestHandler.new
