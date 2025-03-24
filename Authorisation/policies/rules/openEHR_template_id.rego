package rules

import rego.v1

datasource := data.data.ACP["ACP.access_policy.rego.json"]

default allow := false

allow if {
	# allow read access when template id is composition.acp
	input.resource.template.id in datasource[input.operation].resource.template.ids

	# allow read access when user role is doctor or nurse
	input.user_role in datasource[input.operation].user_roles
}
