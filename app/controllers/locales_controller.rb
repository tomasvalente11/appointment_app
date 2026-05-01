class LocalesController < ApplicationController
  def update
    locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale.to_s
    cookies.permanent[:locale] = locale
    redirect_back_or_to root_path
  end
end
