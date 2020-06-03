require "base64"

module Kerbi
  module BaseHelper
    def b64_secret_encode(string)
      string ? Base64.encode64(string) : ''
    end
  end
end