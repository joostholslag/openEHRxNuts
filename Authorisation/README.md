This folder contains an experiment to express access control policy (authorisations) for openEHR data.
It's an attempt to solve the issue described in https://github.com/jorritspee/openEHRxNuts/issues/11.


## Architecture

![Architecture overview: client, openEHR CDR with Policy Enforcement Point, Policy Decision Point, Policy Information Point and Policy Repository](docs/architecture_overview.png)

The diagram source is [`docs/architecture_overview.drawio`](docs/architecture_overview.drawio) (edit with [draw.io](https://app.diagrams.net)). The question in the diagram, which policy applies to a request, is answered in [DESIGN.md](DESIGN.md), section 7.5. `docs/` also keeps a [screenshot](docs/rego_playground_screenshot.jpg) of an early version of the policy in the Rego Playground, for historical reference.
