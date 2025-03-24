package rules

import rego.v1

default allow := false

allow if {
  input.resource.template.id in data.data.ACP.ACP[input.operation].resource.ids # #allow read access when resource.template.id == composition.acp
  input.user_role in data[input.operation].user_roles #allow read access when user role is doctor or nurse
}
