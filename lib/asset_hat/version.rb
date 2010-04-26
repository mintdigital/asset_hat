module AssetHat
  # Returns this gem's version number. See also VERSION.
  def self.version
    data_filepath = File.join(File.dirname(__FILE__), %w[.. .. VERSION.yml])
    data = YAML.load(File.open(data_filepath, 'r'))
    [:major, :minor, :patch, :build].
      map { |x| data[x] }.reject(&:blank?).join('.')
  end

  # This gem's version number.
  VERSION = self.version

end
