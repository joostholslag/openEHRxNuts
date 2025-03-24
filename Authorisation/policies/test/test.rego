package test

import data.rules
import future.keywords.if

test_nurse_read_positive if {
	testinput = {
		"user_role": "nurse",
		"resource": {"template": {"id": "composition.acp"}},
		"operation": "GET",
	}
	rules.allow == true with input as testinput
}

test_doctor_read_positive if {
	testinput = {
		"user_role": "doctor",
		"resource": {"template": {"id": "composition.acp"}},
		"operation": "GET",
	}
	rules.allow == true with input as testinput
}

test_nurse_post_negatife if {
	testinput = {
		"user_role": "nurse",
		"resource": {"template": {"id": "composition.acp"}},
		"operation": "POST",
	}
	rules.allow != true with input as testinput
}

test_doctor_write_positive if {
	testinput = {
		"user_role": "doctor",
		"resource": {"template": {"id": "composition.acp"}},
		"operation": "POST",
	}
	rules.allow == true with input as testinput
}

test_non_ACP_template_id_negatife if {
	testinput = {
		"user_role": "doctor",
		"resource": {"template": {"id": "not-composition.acp"}},
		"operation": "GET",
	}
	rules.allow != true with input as testinput
}

test_get_report_doctor_positive if { 
	testinput = {
		"user_role": "doctor",
		"resource": {"template": {"id": "composition.report"}},
		"operation": "GET",
	}
	rules.allow == true with input as testinput
}

test_write_report_doctor_negative if { 
	testinput = {
		"user_role": "doctor",
		"resource": {"template": {"id": "composition.report"}},
		"operation": "POST",
	}
	rules.allow != true with input as testinput
}


