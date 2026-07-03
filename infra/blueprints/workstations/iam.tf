locals {
  admin_users = toset([for email in var.admin_users : "user:${email}"])
  dev_users   = toset([for email in var.workstation_users : "user:${email}"])
  all_users   = setunion(local.dev_users, local.admin_users)

  admin_role_members = {
    for pair in flatten([
      for role in var.admin_roles : [
        for member in local.admin_users : {
          role   = role
          member = member
        }
      ]
    ]) : "${pair.role}-${pair.member}" => pair
  }
  user_role_members = {
    for pair in flatten([
      for role in var.user_roles : [
        for member in local.all_users : {
          role   = role
          member = member
        }
      ]
    ]) : "${pair.role}-${pair.member}" => pair
  }
}

resource "google_project_iam_member" "admin_roles" {
  for_each = local.admin_role_members

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}

resource "google_project_iam_member" "user_roles" {
  for_each = local.user_role_members

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}



