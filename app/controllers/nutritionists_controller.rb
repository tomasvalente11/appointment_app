class NutritionistsController < ApplicationController
  BRAGA_COORDS = [41.5503, -8.4200].freeze

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

    coords = Geocoder.coordinates(params[:location]).presence if params[:location].present?
    radius = coords ? params[:radius].to_i.then { |r| [25, 50, 100, 200].include?(r) ? r : 50 } : 99_999
    coords ||= BRAGA_COORDS

    @nutritionists = @nutritionists.nearest_to(*coords, max_km: radius).to_a

    respond_to do |format|
      format.html
      format.json do
        render json: @nutritionists.map { |n|
          {
            id: n.id,
            name: n.name,
            services: n.services.map { |s| { duration: s.duration, id: s.id, name: s.name } },
          }
        }
      end
    end
  end

end
