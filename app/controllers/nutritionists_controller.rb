class NutritionistsController < ApplicationController
  ALLOWED_RADII_KM = [ 25, 50, 100, 200 ].freeze
  DEFAULT_RADIUS_KM = 50

  # Used by the "nutritionist access" dropdown — populates the public list of
  # nutritionists a logged-in professional would pick from. Distinct from
  # @nutritionists, which is the (possibly filtered) customer-facing search.
  def landing
    @all_nutritionists = Nutritionist.order(:name).to_a
  end

  def requests
    @nutritionist = Nutritionist.find(params[:id])
  end

  def index
    @all_nutritionists = Nutritionist.order(:name).to_a
    @nutritionists = Nutritionist.preload(:services, :availability_slots)

    if params[:q].present?
      ids = NutritionistSearch.search(params[:q])
      @nutritionists = @nutritionists.where(id: ids)
    end

    @nutritionists = filter_by_location(@nutritionists)

    respond_to do |format|
      format.html
      format.json do
        render json: @nutritionists.map { |n|
          {
            id: n.id,
            name: n.name,
            services: n.services.map { |s| { duration: s.duration, id: s.id, name: s.name } }
          }
        }
      end
    end
  end

  private

  def filter_by_location(scope)
    return scope.order(:name).to_a if params[:location].blank?

    coords = Geocoder.coordinates(params[:location])
    return [] if coords.blank?

    scope.nearest_to(*coords, max_km: parsed_radius).to_a
  end

  def parsed_radius
    r = params[:radius].to_i
    ALLOWED_RADII_KM.include?(r) ? r : DEFAULT_RADIUS_KM
  end
end
