---
name: Guardian dashboard integration test contracts
description: Stable interaction and assertion guidance for guardian dashboard flow tests after layout transitions.
---

Guardian dashboard integration flows should tap key-addressable controls only while their `ModalRoute` is current, and should assert the dashboard's stable structural keys rather than retired copy.

**Why:** Flutter finders can retain widgets from an outgoing route during a transition. Dashboard layout work can also replace an empty-state sentence with a structural empty preview and action. Tapping or asserting the old widgets makes a valid navigation look like a failed flow.

**How to apply:** In route-driven widget tests, scroll keyed controls into view and dispatch at their center when finder hit testing targets a wrapper. After navigation, wait for current dashboard keys such as the pet preview and add-pet control, and avoid retrying a stale route's controls.