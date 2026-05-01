class NutritionistSearch
  INDEX_NAME = "nutritionists"

  def self.reindex_all
    records = Nutritionist.includes(:services).map { |n| to_record(n) }
    ALGOLIA_CLIENT.replace_all_objects(INDEX_NAME, records)
  end

  def self.sync(nutritionist)
    ALGOLIA_CLIENT.save_object(INDEX_NAME, to_record(nutritionist))
  end

  def self.search(query)
    result = ALGOLIA_CLIENT.search_single_index(INDEX_NAME, { query: query, hitsPerPage: 50 })
    result.hits.map { |h| h.algolia_object_id.to_i }
  end

  def self.to_record(nutritionist)
    {
      objectID:      nutritionist.id,
      name:          nutritionist.name,
      bio:           nutritionist.bio,
      license:       nutritionist.license_number,
      services:      nutritionist.services.map { |s| "#{s.name} #{s.location}" }.join(" "),
      service_names: nutritionist.services.map(&:name),
      locations:     nutritionist.services.map(&:location).uniq,
    }
  end
end
