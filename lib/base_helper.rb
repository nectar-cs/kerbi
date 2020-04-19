require "base64"

module Kerb
  module BaseHelper
    def secrefy(string)
      Base64.encode64(string)
    end
  end
end