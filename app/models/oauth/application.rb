class Oauth::Application
    include MongoMapper::Document

    many :authorized_tokens, :class_name => "Oauth::AccessToken"

    key :name, String
    key :client_id, String
    key :client_secret, String
    key :redirect_uri, String
    key :scopes, String
end