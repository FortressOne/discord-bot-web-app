# Read-only client for the public fortressone-stats S3 bucket. The bucket
# allows unauthenticated ListObjectsV2 and GET, so no AWS credentials or SDK
# are needed.
module Stats
  class Archive
    BUCKET_URL = "https://fortressone-stats.s3.ap-southeast-2.amazonaws.com".freeze

    def self.each_key(prefix: nil, &block)
      new.each_key(prefix: prefix, &block)
    end

    def self.fetch(key)
      new.fetch(key)
    end

    def each_key(prefix: nil)
      return enum_for(:each_key, prefix: prefix) unless block_given?

      continuation_token = nil
      loop do
        params = { "list-type" => 2, "max-keys" => 1000 }
        params["prefix"] = prefix if prefix
        params["continuation-token"] = continuation_token if continuation_token

        document = Nokogiri::XML(get("/", params))
        document.remove_namespaces!
        document.xpath("//Contents").each do |contents|
          key = contents.at_xpath("Key")&.text
          size = contents.at_xpath("Size")&.text.to_i
          yield key if match_log_key?(key, size)
        end

        break unless document.at_xpath("//IsTruncated")&.text == "true"

        continuation_token = document.at_xpath("//NextContinuationToken")&.text
        break if continuation_token.blank?
      end
    end

    def fetch(key)
      get("/#{key.split('/').map { |part| ERB::Util.url_encode(part) }.join('/')}")
    end

    private

    def match_log_key?(key, size)
      # Match logs always live under <region>/<game_mode>/; top-level objects
      # (demo-counts.json, index.html) are bucket housekeeping.
      key.present? && key.include?("/") && key.end_with?(".json") && size > 100
    end

    def get(path, params = nil)
      response = connection.get(path, params)
      raise "S3 request failed (#{response.status}) for #{path}" unless response.success?

      response.body
    end

    def connection
      @connection ||= Faraday.new(url: BUCKET_URL) do |faraday|
        faraday.options.timeout = 60
        faraday.options.open_timeout = 10
      end
    end
  end
end
