require "base64"

module Kerbi
  module BaseHelper
    def secrefy(string)
      string ? Base64.encode64(string) : ''
    end
  end
end