require_relative 'spec_helper'
require 'uri'
require 'json'
require 'ritm'
require 'helpers/ritm_spec_utils'

RSpec.describe Ritm do
  include RitmSpecUtils

  %w[http://localhost:4567 https://localhost:4443].each do |base_url|
    before(:each) do
      interceptor.clear
    end

    it 'intercepts requests and responses' do
      expect(interceptor.requests.size).to eq 0
      expect(interceptor.responses.size).to eq 0
      client(base_url).get('/ping')
      expect(interceptor.requests.size).to eq 1
      expect(interceptor.responses.size).to eq 1
    end

    it 'can disable interception temporarily' do
      expect(interceptor.requests.size).to eq 0
      expect(interceptor.responses.size).to eq 0
      Ritm.disable
      client(base_url).get('/ping')
      expect(interceptor.requests.size).to eq 0
      expect(interceptor.responses.size).to eq 0
      Ritm.enable
      client(base_url).get('/ping')
      expect(interceptor.requests.size).to eq 1
      expect(interceptor.responses.size).to eq 1
    end

    it 'can be configured to use upstream proxies' do
      resp = nil
      with_proxy do |session|
        c = client(base_url, verify_ssl: false, proxy: 'http://localhost:7777')
        c.get('/ping')
        expect(interceptor.requests.size).to eq 0
        expect(interceptor.responses.size).to eq 0

        session.configure { misc[:upstream_proxy] = DEFAULT_PROXY_ADDRESS }

        resp = c.get('/ping')
        expect(interceptor.requests.size).to eq 1
        expect(interceptor.responses.size).to eq 1
      end
      expect(resp.body).to eq 'pong'
    end

    describe 'when intercepting requests' do
      it 'intercepts requests before they are sent' do
        exec_order = [:a]
        interceptor.on_request = proc do |_req|
          exec_order << :c
        end
        exec_order << :b
        client(base_url).get('/ping')
        exec_order << :d
        expect(exec_order).to eq(%i[a b c d])
      end

      it 'gets access to method, resource, headers, and body' do
        client(base_url).post('/echo?query=string') do |r|
          r.headers['Content-Type'] = 'application/json'
          r.body = '{ "password": "12345" }'
        end
        req = interceptor.requests.last
        expect(req.request_method).to eq('POST')
        expect(req.request_uri.to_s).to eq("#{base_url}/echo?query=string")
        expect(req.header['content-type']).to eq(['application/json'])
        expect(req.body).to eq('{ "password": "12345" }')
      end

      it 'can modify method, resource, headers, and body' do
        interceptor.on_request = proc do |req|
          req.request_method = 'PUT'
          req.request_uri = URI("#{base_url}/echo?arg=1")
          req['content-type'] = 'text/plain'
          req.body = '{ "password": "666" }'
        end
        response = client(base_url).post('/echo') do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = '{ "password": "12345" }'
        end
        res = JSON.parse(response.body, symbolize_names: true)
        expect(res[:method]).to eq('PUT')
        expect(res[:path]).to eq('/echo')
        expect(res[:query]).to eq('arg=1')
        expect(res[:body]).to eq('{ "password": "666" }')
        expect(res[:headers][:'content-type']).to eq('text/plain')
        # TODO: implement changing host:port when intercepting
        # expect(res[:headers][:host]).to eq('127.0.0.1.xip.io:4567')
      end
    end

    describe 'when intercepting responses' do
      it 'intercepts responses before the client gets them' do
        exec_order = [:a]
        interceptor.on_response = proc { |_req, _res| exec_order << :c }
        exec_order << :b
        client(base_url).get('/ping')
        exec_order << :d
        expect(exec_order).to eq(%i[a b c d])
      end

      it 'gets access to status, headers, and body' do
        client(base_url).get('/ping')
        res = interceptor.responses.last
        expect(res.status).to eq 200
        expect(res.header['content-length']).to eq('4')
        expect(res.header['content-type']).to eq('text/html;charset=utf-8')
        expect(res.body).to eq('pong')
      end

      it 'can modify status, headers, and body' do
        interceptor.on_response = proc do |_req, res|
          res.body = 'plonch'
          res.status = 404
          res.header['x-custom'] = 'narf'
          res.header['content-type'] = 'text/plain'
        end
        res = client(base_url).get('/ping')
        expect(res.status).to eq 404
        expect(res.headers['content-length']).to eq('6')
        expect(res.headers['content-type']).to eq('text/plain')
        expect(res.headers['x-custom']).to eq('narf')
        expect(res.body).to eq('plonch')
      end

      it 'gets gzip content automatically decoded' do
        content = nil
        interceptor.on_response = proc do |_req, res|
          expect(res.header['content-encoding']).to be nil
          content = res.body
        end
        client(base_url).get('/encoded/gzip')
        expect(content).to eq 'Living is easy with eyes closed'
      end

      it 'gets deflate content automatically decoded' do
        content = nil
        interceptor.on_response = proc do |_req, res|
          expect(res.header['content-encoding']).to be nil
          content = res.body
        end
        client(base_url).get('/encoded/deflate')
        expect(content).to eq 'Misunderstanding all you see'
      end
    end
  end
end
