require "base64"

module Kerbi
  module MixerHelper
    def b64_encode_secret(string)
      string ? Base64.encode64(string) : ''
    end
  end
end