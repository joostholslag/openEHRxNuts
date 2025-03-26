package rules

import rego.v1

import data.data.ACP["ACP.access_policy.rego.json"] as datasource

default allow := false

operation := input.operation

template_id := input.resource.template.id

user_role := input.user_role

allowed_ids := datasource[operation].resource.template.ids

allowed_roles := datasource[operation].user_roles

id_allowed if {
	template_id in allowed_ids
}

user_role_allowed if {
	user_role in allowed_roles
}

allow if {
	# allow read access when template id is composition.acp
	id_allowed

	# allow read access when user role is doctor or nurse
	user_role_allowed
}
