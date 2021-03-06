module ClinkCloud
  class IpAddressResource < BaseResource
    resources do
      default_handler do |response|
        fail "Unexpected response status #{response.status}... #{response.body}"
      end

      action :create do
        verb :post
        path { "/v2/servers/#{account_alias}/:server_id/publicIPAddresses/" }
        # TODO: this is hacky
        body { |object| object.delete(:server_id); object.to_json}
        handler(202) do |response|
          # Just return the status
          response.body
        end
      end

      action :update do
        verb :put
        path { "/v2/servers/#{account_alias}/:server_id/publicIPAddresses/:id" }
        body { |object| IpAddressMapping.representation_for(:update, object) }
        handler(200) do |response|
          IpAddressMapping.extract_collection(response.body, :read)
        end
      end

      action :find do
        verb :get
        path { "/v2/servers/#{account_alias}/:server_id/publicIPAddresses/:id" }
        handler(200) do |response|
          IpAddressMapping.extract_collection(response.body, :read)
        end
      end

      action :delete do
        verb :delete
        path { "/v2/servers/#{account_alias}/:server_id/publicIPAddresses/:id" }
        handler(200) do |response|
          response.body
        end
      end
    end
  end
end
