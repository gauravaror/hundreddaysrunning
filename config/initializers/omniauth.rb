Rails.application.config.middleware.use OmniAuth::Builder do
  provider :strava, '17784', 'b06f8ae027cbb247afafc914652242d69d1a2b4c', scope: 'public'
end
