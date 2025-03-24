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

test_doctor_read_positive if {
	testinput = {
		"user_role": "doctor",
		"resource": {"template": {"id": "composition.acp"}},
		"operation": "READ",
	}
	rules.allow == true with input as testinput
}

test_nurse_create_negatife if {
	testinput = {
		"user_role": "nurse",
		"resource": {"template": {"id": "composition.acp"}},
		"operation": "CREATE",
	}
	rules.allow != true with input as testinput
}

test_doctor_create_positive if {
	testinput = {
		"user_role": "doctor",
		"resource": {"template": {"id": "composition.acp"}},
		"operation": "CREATE",
	}
	rules.allow == true with input as testinput
}

test_non_acp_template_id_negative if {
	testinput = {
		"user_role": "doctor",
		"resource": {"template": {"id": "not-composition.acp"}},
		"operation": "READ",
	}
	rules.allow != true with input as testinput
}

test_read_report_doctor_positive if {
	testinput = {
		"user_role": "doctor",
		"resource": {"template": {"id": "composition.report"}},
		"operation": "READ",
	}
	rules.allow == true with input as testinput
}

test_create_report_doctor_negative if {
	testinput = {
		"user_role": "doctor",
		"resource": {"template": {"id": "composition.report"}},
		"operation": "CREATE",
	}
	rules.allow != true with input as testinput
}
