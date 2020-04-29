class HashCode
  def self.for(value)
    value.to_s
         .bytes
         .map { |byte| (byte * byte).to_s }
         .join
         .to_i
  end
end
