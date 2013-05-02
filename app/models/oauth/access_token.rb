class Oauth::AccessToken
    include MongoMapper::Document
    key :resource_owner_id, ObjectId
    key :token, String
    key :expires_in, Integer
    key :revoked_at, DateTime
    key :scopes, String
end