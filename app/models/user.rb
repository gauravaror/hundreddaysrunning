class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  has_many :runs
  has_many :days, :through => :runs
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:strava]


         def self.from_omniauth(auth)
           where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
             user.email = auth.info.email
             user.password = Devise.friendly_token[0,20]
             user.firstname = auth.info.first_name
             user.lastname = auth.info.last_name
             user.access_token = auth.credentials.token
             user.profile = auth.extra.raw_info.profile
             #user.image = auth.info.image # assuming the user model has an image
             # If you are using confirmable and the provider(s) you use validate emails,
             # uncomment the line below to skip the confirmation emails.
             # user.skip_confirmation!
           end
         end
end
