module AssetHat
  # Returns the version number. See also <tt>AssetHat::VERSION</tt>.
  def self.version
    data_filepath = File.join(File.dirname(__FILE__), %w[.. .. VERSION.yml])
    data = YAML.load(File.open(data_filepath, 'r'))
    [:major, :minor, :patch, :build].
      map { |x| data[x] }.reject(&:blank?).join('.')
  end

  VERSION = self.version

end
