module NephoRuby
  module ApiMethods
    
    # https://kb.nephoscale.com/api/server.html#servercloud
    # https://kb.nephoscale.com/api/server.html#serverdedicated
    def get_servers(type)
      servers = []
      
      case type
      when :cloud
        response = commit("server/cloud/", "get", {})
        
        for vm in response.data
          image = ::NephoRuby::Image.new(:agent           => vm["image"]["has_agent"],
                                         :deployable_type => vm["image"]["deployable_type"],
                                         :default         => vm["image"]["is_default"],
                                         :creation_time   => vm["image"]["create_time"],
                                         :id              => vm["image"]["id"],
                                         :max_cpu         => vm["image"]["max_cpu"],
                                         :active          => vm["image"]["is_active"],
                                         :base_type       => vm["image"]["base_type"],
                                         :max_memory      => vm["image"]["max_memory"],
                                         :name            => vm["image"]["friendly_name"],
                                         :arch            => vm["image"]["architecture"])
                                         
          servers.push(::NephoRuby::CloudServer.new(:id           => vm["id"],
                                                    :memory       => vm["memory"],
                                                    :power_state  => vm["power_status"],
                                                    :hostname     => vm["hostname"],
                                                    :ip_addresses => vm["ipaddresses"].split(", ").map { |i| IPAddr.new(i) },
                                                    :created_at   => vm["create_time"],
                                                    :image        => image))
    
        end
      when :dedicated
        response = commit("server/dedicated/", "get", {})
        
        for dedicated in response.data
          image = ::NephoRuby::Image.new(:agent           => dedicated["image"]["has_agent"],
                                         :deployable_type => dedicated["image"]["deployable_type"],
                                         :default         => dedicated["image"]["is_default"],
                                         :creation_time   => dedicated["image"]["create_time"],
                                         :id              => dedicated["image"]["id"],
                                         :max_cpu         => dedicated["image"]["max_cpu"],
                                         :active          => dedicated["image"]["is_active"],
                                         :base_type       => dedicated["image"]["base_type"],
                                         :max_memory      => dedicated["image"]["max_memory"],
                                         :name            => dedicated["image"]["friendly_name"],
                                         :arch            => dedicated["image"]["architecture"])
                                         
          servers.push(::NephoRuby::DedicatedServer.new(:id           => dedicated["id"],
                                                        :memory       => dedicated["memory"],
                                                        :power_state  => dedicated["power_status"],
                                                        :hostname     => dedicated["hostname"],
                                                        :created_at   => dedicated["create_time"],
                                                        :ip_addresses => dedicated["ipaddresses"].split(", ").map { |i| IPAddr.new(i) },
                                                        :image        => image))
        end
      else
        raise InvalidServerType, "Only cloud or dedicated are valid server types"
      end
      
      servers
    end
    
    # https://kb.nephoscale.com/api/server.html#servercloud
    # https://kb.nephoscale.com/api/server.html#serverdedicated
    def create_server(server)
      case server.class.to_s
      when "NephoRuby::CloudServer"
        commit("server/cloud/", "post", server.to_params)
      when "NephoRuby::DedicatedServer"
        commit("server/dedicated/", "post", server.to_params)
      else
        raise InvalidServerType, "Only cloud or dedicated server types can be added"
      end
    end
    
    def power_control(server, action)
      case server.class.to_s
      when "NephoRuby::CloudServer"
        commit("/server/cloud/#{server.id}/initiator/#{action.to_s}/", "post", {})
      when "NephoRuby::DedicatedServer"
        commit("/server/dedicated/#{server.id}/initiator/#{action.to_s}/", "post", {})
      end
    end
    
    def destroy_server(server)
      case server.class.to_s
      when "NephoRuby::CloudServer"
        commit("server/cloud/#{server.id}/", "delete", {})
      when "NephoRuby::DedicatedServer"
        commit("server/dedicated/#{server.id}/", "delete", {})
      else
        raise InvalidServerType, "Only cloud or dedicated server types can be added"
      end
    end
    
    # https://kb.nephoscale.com/api/quickstart.html#instance-list
    def get_instances
      instances = []
      response = commit("server/type/cloud/", "get", {})
      
      for instance in response.data
        instances.push(::NephoRuby::Instance.new( :id           => instance["id"],
                                                  :ram          => instance["ram"],
                                                  :storage      => instance["storage"],
                                                  :name         => instance["name"],
                                                  :description  => instance["description"]))
      end
      
      instances
    end
    
    # https://kb.nephoscale.com/api/quickstart.html#image-list
    def get_images
      images = []
      response = commit("image/server/", "get", {})
      
      for image in response.data
        images.push(::NephoRuby::Image.new( :id               => image["id"],
                                            :active           => image["is_active"],
                                            :default          => image["is_default"],
                                            :agent            => image["has_agent"],
                                            :creation_time    => image["create_time"],
                                            :max_cpu          => image["max_cpu"],
                                            :max_memory       => image["max_memory"],
                                            :arch             => image["architecture"],
                                            :deployable_type  => image["deployable_type"],
                                            :name             => image["friendly_name"]))
      end
      
      images
    end
    
    # https://kb.nephoscale.com/api/quickstart.html#unassigned-public-ipv4-address-list
    def get_ip_addresses(version = 4, selector = :unassigned)
      addresses = []
      response = commit("network/ipaddress/", "get", {:type => 0, :version => version, :unassigned => (selector == :unassigned ? 'true' : 'false')})
      
      for address in response.data
        addresses.push(IPAddr.new(address["ipaddress"]))
      end
      
      addresses
    end
    
    
    def get_credentials
      credentials = []
      response = commit("key/", "get", {})
      
      for cred in response.data
        credentials.push(NephoRuby::Credential.new( :id           => cred["id"],
                                                    :password     => cred["password"],
                                                    :public_key   => cred["public_key"],
                                                    :private_key  => cred["private_key"],
                                                    :group        => cred["group"]))
      end
      
      credentials
    end
  end
end