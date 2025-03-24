package test

import data.rules
import future.keywords.if

test_nurse_read_positive if {
	testinput = {
		"user_role": "nurse",
		"resource": {"template": {"id": "composition.acp"}},
		"operation": "READ",
	}
	rules.allow == true with input as testinput
}

test_nurse_read_positive if {
	testinput = {
		"user_role": "nurse",
		"resource": {"template": {"id": "composition.acp"}},
		"operation": "READ",
	}
	rules.allow == true with input as testinput
}
