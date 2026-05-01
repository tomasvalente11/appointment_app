if Rails.env.test?
  module AlgoliaTestStub
    def self.search_single_index(_index, opts = {})
      query = opts[:query].to_s.downcase
      ids = Nutritionist.search_by_term(query).pluck(:id)
      Struct.new(:hits).new(
        ids.map { |id| Struct.new(:algolia_object_id).new(id.to_s) }
      )
    end

    def self.replace_all_objects(_index, _records) = nil
    def self.save_object(_index, _record) = nil
  end

  ALGOLIA_CLIENT = AlgoliaTestStub
else
  ALGOLIA_CLIENT = Algolia::SearchClient.create(
    ENV["ALGOLIA_APP_ID"],
    ENV["ALGOLIA_ADMIN_KEY"]
  )
end
