require 'zlib'

module Ritm
  # ENCODER/DECODER of HTTP content
  module Encodings
    ENCODINGS = [:identity, :gzip, :deflate].freeze

    def self.encode(encoding, data)
      case encoding
      when :gzip
        encode_gzip(data)
      when :deflate
        encode_deflate(data)
      when :identity
        identity(data)
      else
        raise "Unsupported encoding #{encoding}"
      end
    end

    def self.decode(encoding, data)
      case encoding
      when :gzip
        decode_gzip(data)
      when :deflate
        decode_deflate(data)
      when :identity
        identity(data)
      else
        raise "Unsupported encoding #{encoding}"
      end
    end

    class << self
      private

      # Returns data unchanged. Identity is the default value of Accept-Encoding headers.
      def identity(data)
        data
      end

      def encode_gzip(data)
        wio = StringIO.new('wb')
        w_gz = Zlib::GzipWriter.new(wio)
        w_gz.write(data)
        w_gz.close
        wio.string
      end

      def decode_gzip(data)
        io = StringIO.new(data, 'rb')
        gz = Zlib::GzipReader.new(io)
        gz.read
      end

      def encode_deflate(data)
        Zlib::Deflate.deflate(data)
      end

      def decode_deflate(data)
        Zlib::Inflate.inflate(data)
      end
    end
  end
end
