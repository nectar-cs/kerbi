class Hash

  def deep_merge(second)
    merger = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
    merge(second.to_h, &merger)
  end

  def symbolize_keys_deep
    new_hash = {}
    keys.each do |k|
      ks    = k.respond_to?(:to_sym) ? k.to_sym : k
      if values_at(k).first.kind_of? Hash or values_at(k).first.kind_of? Array
        new_hash[ks] = values_at(k).first.send(:symbolize_keys_deep)
      else
        new_hash[ks] = values_at(k).first
      end
    end
    new_hash
  end

end