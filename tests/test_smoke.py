import triage


def test_package_imports_with_policy_version():
    assert triage.POLICY_VERSION == "support-triage-policy-v1.1"
