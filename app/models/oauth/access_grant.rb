class Oauth::AccessGrant
    include MongoMapper::Document
    key :resource_owner_id, ObjectId
    key :application_id, ObjectId
    key :authz_code, String
    key :expires_in, Integer
    key :redirect_uri, String
    key :revoked_at, DateTime
    key :scopes, String
end