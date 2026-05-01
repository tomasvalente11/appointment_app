class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("GMAIL_USER", "from@example.com")
  layout "mailer"
end
