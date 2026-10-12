# Agatha care journey — BDD scenarios (expanded per phase; PR-01 stub)
@pet_care @agatha-care-journey
Feature: Agatha care journey profile facts
  Profile identification and neuter facts persist with merge-safe PUT semantics.

  @ACJ-PF-01
  Scenario: Neuter status survives profile reload
    Given a guardian owns a pet with neuter status "no"
    When the guardian updates the pet name without sending neuter status
    Then the pet detail still shows neuter status "no"

  @acj @pr-03 @smoke-uat
  Scenario: ACJ-IC-01 — Record neuter no from sheet on inset prompt
    Given a guardian owns a pet with unknown neuter status
    When the guardian records neuter status "no" from the profile inset sheet
    Then the pet detail shows neuter status "no"

  @acj @pr-03 @smoke-ci @authz
  Scenario: ACJ-IC-02 — View-only cannot record profile facts
    Given a shared carer views a pet with unknown profile facts
    Then the profile inset Record action is disabled
