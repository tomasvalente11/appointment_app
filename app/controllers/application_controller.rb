class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  around_action :set_locale

  private

  def set_locale
    locale = cookies[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
    I18n.with_locale(locale) { yield }
  end
end
