# Copyright 2023-2026 Google LLC
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

module "vpc_hub" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"
  project_id = module.project_hub_host.project_id
  name       = "hub"
  vpc_reuse  = var.vpc_create ? null : {}
  subnets = [
    {
      ip_cidr_range = var.vpc_hub_primary_cidr
      name          = var.vpc_subnet_name
      region        = var.region
    },
  ]
  psa_configs = [{
    ranges = {
      "default" = var.vpc_hub_psa_cidr
    }
  }]
}

module "fw_hub" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v45.0.0"
  project_id = module.project_hub_host.project_id
  network    = module.vpc_hub.name
}

module "vpc_spoke" {
  for_each   = var.environments
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"
  project_id = module.project_spoke_host[each.key].project_id
  name       = each.key
  vpc_reuse  = var.vpc_create ? null : {}
  subnets = [
    {
      ip_cidr_range = each.value.network.nodes_cidr_block
      name          = var.vpc_subnet_name
      region        = var.region
      secondary_ip_ranges = {
        pods     = { ip_cidr_range = each.value.network.pods_cidr_block }
        services = { ip_cidr_range = each.value.network.services_cidr_block }
      }
    },
  ]
  subnets_proxy_only = [
    {
      ip_cidr_range = each.value.network.proxy_only_subnet_cidr_block
      name          = "proxy"
      region        = var.region
      active        = true
    },
  ]
  psa_configs = [{
    ranges = {
      "default" = each.value.network.psa_cidr
    }
  }]
}

module "fw_spoke" {
  for_each   = var.environments
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v45.0.0"
  project_id = module.project_spoke_host[each.key].project_id
  network    = module.vpc_spoke[each.key].name
  factories_config = {
    rules_folder  = "${path.module}/firewall/rules"
    cidr_tpl_file = "${path.module}/firewall/cidrs.yaml"
  }
}

module "peering_hub_spoke" {
  for_each      = var.environments
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-peering?ref=v45.0.0"
  prefix        = "hub-${each.key}"
  local_network = module.vpc_hub.self_link
  peer_network  = module.vpc_spoke[each.key].self_link
}

module "vpc_spoke_build" {
  for_each   = var.environments
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"
  project_id = module.project_spoke_host[each.key].project_id
  name       = "build"
  vpc_reuse  = var.vpc_create ? null : {}
  subnets = [
    {
      ip_cidr_range = each.value.network.build_primary_cidr
      name          = "build"
      region        = var.region
    },
  ]
  psa_configs = [{
    ranges = {
      "build" = each.value.network.build_psa_cidr
    }
    export_routes = true
  }]
}

module "fw_spoke_build" {
  for_each   = var.environments
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v45.0.0"
  project_id = module.project_spoke_host[each.key].project_id
  network    = module.vpc_spoke_build[each.key].name
}

resource "google_compute_ha_vpn_gateway" "build_to_spoke" {
  for_each = var.environments
  name     = "build-to-${each.key}"
  project  = module.project_spoke_host[each.key].project_id
  region   = var.region
  network  = module.vpc_spoke_build[each.key].self_link
}

resource "google_compute_ha_vpn_gateway" "spoke_to_build" {
  for_each = var.environments
  name     = "${each.key}-to-build"
  project  = module.project_spoke_host[each.key].project_id
  region   = var.region
  network  = module.vpc_spoke[each.key].self_link
}

module "vpn_build_to_spoke" {
  for_each           = var.environments
  source             = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha?ref=v45.0.0"
  project_id         = module.project_spoke_host[each.key].project_id
  region             = var.region
  network            = module.vpc_spoke_build[each.key].self_link
  name               = "build-to-${each.key}"
  vpn_gateway_create = null
  vpn_gateway        = google_compute_ha_vpn_gateway.build_to_spoke[each.key].self_link
  peer_gateways = {
    default = { gcp = google_compute_ha_vpn_gateway.spoke_to_build[each.key].self_link }
  }
  router_config = {
    asn = 64514
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        (each.value.network.build_psa_cidr) = "psa-${each.key}-build"
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

module "vpn_spoke_to_build" {
  for_each           = var.environments
  source             = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha?ref=v45.0.0"
  project_id         = module.project_spoke_host[each.key].project_id
  region             = var.region
  network            = module.vpc_spoke[each.key].self_link
  name               = "${each.key}-to-build"
  vpn_gateway_create = null
  vpn_gateway        = google_compute_ha_vpn_gateway.spoke_to_build[each.key].self_link
  router_config = {
    asn = 64513
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        (each.value.network.master_cidr_block) = "cluster-${each.key}"
      }
    }
  }
  peer_gateways = {
    default = { gcp = google_compute_ha_vpn_gateway.build_to_spoke[each.key].self_link }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = module.vpn_build_to_spoke[each.key].random_secret
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.2.1/30"
      shared_secret         = module.vpn_build_to_spoke[each.key].random_secret
      vpn_gateway_interface = 1
    }
  }
}
