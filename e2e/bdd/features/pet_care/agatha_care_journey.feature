# Agatha care journey — BDD scenarios (expanded per phase; PR-01 stub)
@pet_care @agatha-care-journey
Feature: Agatha care journey profile facts
  Profile identification and neuter facts persist with merge-safe PUT semantics.

  @smoke-ci @ACJ-PF-01
  Scenario: Neuter status survives profile reload
    Given a guardian owns a pet with neuter status "no"
    When the guardian updates the pet name without sending neuter status
    Then the pet detail still shows neuter status "no"
