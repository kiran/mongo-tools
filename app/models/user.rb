class User
  include MongoMapper::Document
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable

#  devise :database_authenticatable, :registerable,
#         :recoverable, :rememberable, :trackable, :validatable

  key :email, String, :required => true
  key :password, String, :required => true
  key :password_confirmation, String, :required => true
  key :remember_me, Boolean

end
