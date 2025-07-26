# Copyright 2023-2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "vpc-hub" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v34.0.0"
  project_id = module.project_hub_host.project_id
  name       = "hub"
  vpc_create = var.vpc_create
  subnets = [
    {
      ip_cidr_range = var.vpc-hub_primary_cidr
      name          = var.vpc_subnet_name
      region        = var.region
    },
  ]
  psa_configs = [{
    ranges = {
      "default" = var.vpc-hub_psa_cidr
    }
  }]
}

module "fw-hub" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v34.0.0"
  project_id = module.project_hub_host.project_id
  network    = module.vpc-hub.name
}

# module "nat_hub" {
#   source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat?ref=v34.0.0"
#   project_id     = module.project_hub_host.project_id
#   region         = var.region
#   name           = var.nat_name
#   router_network = module.vpc-hub.name
# }

module "vpc-prod" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v34.0.0"
  project_id = module.project_prod_host.project_id
  name       = "prod"
  vpc_create = var.vpc_create
  subnets = [
    {
      ip_cidr_range = var.cluster-prod_network_config.nodes_cidr_block
      name          = var.vpc_subnet_name
      region        = var.region
      secondary_ip_ranges = {
        pods     = var.cluster-prod_network_config.pods_cidr_block
        services = var.cluster-prod_network_config.services_cidr_block
      }
    },
  ]
  subnets_proxy_only = [
    {
      ip_cidr_range = var.cluster-prod_network_config.proxy_only_subnet_cidr_block
      name          = "proxy"
      region        = var.region
      active        = true
    },
  ]
  psa_configs = [{
    ranges = {
      "default" = var.vpc-prod_psa_cidr
    }
  }]
}

module "fw-prod" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v34.0.0"
  project_id = module.project_prod_host.project_id
  network    = module.vpc-prod.name
  factories_config = {
    rules_folder  = "firewall/rules"
    cidr_tpl_file = "firewall/cidrs.yaml"
  }
}

module "peering-hub-prod" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-peering?ref=v34.0.0"
  prefix        = "hub-prod"
  local_network = module.vpc-hub.self_link
  peer_network  = module.vpc-prod.self_link
}

module "vpc-test" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v34.0.0"
  project_id = module.project_test_host.project_id
  name       = "test"
  vpc_create = var.vpc_create
  subnets = [
    {
      ip_cidr_range = var.cluster-test_network_config.nodes_cidr_block
      name          = var.vpc_subnet_name
      region        = var.region
      secondary_ip_ranges = {
        pods     = var.cluster-test_network_config.pods_cidr_block
        services = var.cluster-test_network_config.services_cidr_block
      }
    },
  ]
  subnets_proxy_only = [
    {
      ip_cidr_range = var.cluster-test_network_config.proxy_only_subnet_cidr_block
      name          = "proxy"
      region        = var.region
      active        = true
    },
  ]
  psa_configs = [{
    ranges = {
      "default" = var.vpc-test_psa_cidr
    }
  }]
}

module "fw-test" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v34.0.0"
  project_id = module.project_test_host.project_id
  network    = module.vpc-test.name
  factories_config = {
    rules_folder  = "firewall/rules"
    cidr_tpl_file = "firewall/cidrs.yaml"
  }
}

module "peering-hub-test" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-peering?ref=v34.0.0"
  prefix        = "hub-test"
  local_network = module.vpc-hub.self_link
  peer_network  = module.vpc-test.self_link
}

module "vpc-dev" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v34.0.0"
  project_id = module.project_dev_host.project_id
  name       = "dev"
  vpc_create = var.vpc_create
  subnets = [
    {
      ip_cidr_range = var.cluster-dev_network_config.nodes_cidr_block
      name          = var.vpc_subnet_name
      region        = var.region
      secondary_ip_ranges = {
        pods     = var.cluster-dev_network_config.pods_cidr_block
        services = var.cluster-dev_network_config.services_cidr_block
      }
    },
  ]
  subnets_proxy_only = [
    {
      ip_cidr_range = var.cluster-dev_network_config.proxy_only_subnet_cidr_block
      name          = "proxy"
      region        = var.region
      active        = true
    },
  ]
  psa_configs = [{
    ranges = {
      "default" = var.vpc-dev_psa_cidr
    }
  }]
}

module "fw-dev" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v34.0.0"
  project_id = module.project_dev_host.project_id
  network    = module.vpc-dev.name
  factories_config = {
    rules_folder  = "firewall/rules"
    cidr_tpl_file = "firewall/cidrs.yaml"
  }
}

module "peering-hub-dev" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-peering?ref=v34.0.0"
  prefix        = "hub-dev"
  local_network = module.vpc-hub.self_link
  peer_network  = module.vpc-dev.self_link
}

module "vpc-prod-build" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v34.0.0"
  project_id = module.project_prod_host.project_id
  name       = "build"
  vpc_create = var.vpc_create
  subnets = [
    {
      ip_cidr_range = var.vpc-prod-build_primary_cidr
      name          = "build"
      region        = var.region
    },
  ]
  psa_configs = [{
    ranges = {
      "build" = var.vpc-prod-build_psa_cidr
    }
    export_routes = true
  }]
}

module "fw-prod-build" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v34.0.0"
  project_id = module.project_prod_host.project_id
  network    = module.vpc-prod-build.name
}

module "vpn-build-prod" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha?ref=v34.0.0"
  project_id = module.project_prod_host.project_id
  region     = var.region
  network    = module.vpc-prod-build.self_link
  name       = "build-to-prod"
  peer_gateways = {
    default = { gcp = module.vpn-prod-build.self_link }
  }
  router_config = {
    asn = 64514
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        (var.vpc-prod-build_psa_cidr) = "psa-prod-build"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.1.2/30"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.2/30"
      vpn_gateway_interface = 1
    }
  }
}

module "vpn-prod-build" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha?ref=v34.0.0"
  project_id = module.project_prod_host.project_id
  region     = var.region
  network    = module.vpc-prod.self_link
  name       = "prod-to-build"
  router_config = {
    asn = 64513
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        (var.cluster-prod_network_config.master_cidr_block) = "cluster-prod"
      }
    }
  }
  peer_gateways = {
    default = { gcp = module.vpn-build-prod.self_link }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = module.vpn-build-prod.random_secret
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.2.1/30"
      shared_secret         = module.vpn-build-prod.random_secret
      vpn_gateway_interface = 1
    }
  }
}

module "vpc-test-build" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v34.0.0"
  project_id = module.project_test_host.project_id
  name       = "build"
  vpc_create = var.vpc_create
  subnets = [
    {
      ip_cidr_range = var.vpc-test-build_primary_cidr
      name          = "build"
      region        = var.region
    },
  ]
  psa_configs = [{
    ranges = {
      "build" = var.vpc-test-build_psa_cidr
    }
    export_routes = true
  }]
}

module "fw-test-build" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v34.0.0"
  project_id = module.project_test_host.project_id
  network    = module.vpc-test-build.name
}

module "vpn-build-test" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha?ref=v34.0.0"
  project_id = module.project_test_host.project_id
  region     = var.region
  network    = module.vpc-test-build.self_link
  name       = "build-to-test"
  peer_gateways = {
    default = { gcp = module.vpn-test-build.self_link }
  }
  router_config = {
    asn = 64514
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        (var.vpc-test-build_psa_cidr) = "psa-test-build"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.1.2/30"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.2/30"
      vpn_gateway_interface = 1
    }
  }
}

module "vpn-test-build" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha?ref=v34.0.0"
  project_id = module.project_test_host.project_id
  region     = var.region
  network    = module.vpc-test.self_link
  name       = "test-to-build"
  router_config = {
    asn = 64513
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        (var.cluster-test_network_config.master_cidr_block) = "cluster-test"
      }
    }
  }
  peer_gateways = {
    default = { gcp = module.vpn-build-test.self_link }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = module.vpn-build-test.random_secret
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.2.1/30"
      shared_secret         = module.vpn-build-test.random_secret
      vpn_gateway_interface = 1
    }
  }
}

module "vpc-dev-build" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v34.0.0"
  project_id = module.project_dev_host.project_id
  name       = "build"
  vpc_create = var.vpc_create
  subnets = [
    {
      ip_cidr_range = var.vpc-dev-build_primary_cidr
      name          = "build"
      region        = var.region
    },
  ]
  psa_configs = [{
    ranges = {
      "build" = var.vpc-dev-build_psa_cidr
    }
    export_routes = true
  }]
}

module "fw-dev-build" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v34.0.0"
  project_id = module.project_dev_host.project_id
  network    = module.vpc-dev-build.name
}

module "vpn-build-dev" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha?ref=v34.0.0"
  project_id = module.project_dev_host.project_id
  region     = var.region
  network    = module.vpc-dev-build.self_link
  name       = "build-to-dev"
  peer_gateways = {
    default = { gcp = module.vpn-dev-build.self_link }
  }
  router_config = {
    asn = 64514
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        (var.vpc-dev-build_psa_cidr) = "psa-dev-build"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.1.2/30"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.2/30"
      vpn_gateway_interface = 1
    }
  }
}

module "vpn-dev-build" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha?ref=v34.0.0"
  project_id = module.project_dev_host.project_id
  region     = var.region
  network    = module.vpc-dev.self_link
  name       = "dev-to-build"
  router_config = {
    asn = 64513
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        (var.cluster-dev_network_config.master_cidr_block) = "cluster-dev"
      }
    }
  }
  peer_gateways = {
    default = { gcp = module.vpn-build-dev.self_link }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = module.vpn-build-dev.random_secret
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.2.1/30"
      shared_secret         = module.vpn-build-dev.random_secret
      vpn_gateway_interface = 1
    }
  }
}
